_r = require 'kefir'
https = require "https"
http = require "http"
url = require 'url'
ks = require 'kefir-storage'

config = require '../stores/config'
defaultRegistry = require '../../../config/default.registry.json'
utilsModel = require '../util/index'

registryConfig = config.get 'registry'
loadingTimeout = process.env.REGISTRY_INTERVAL || registryConfig.refreshInterval || 3600000
publicRegistry = process.env.REGISTRY_URL || registryConfig.public || null

model = {}

# update and set registry install flags in kefir-storage 'recommendations:list'
model.updateRegistryInstallFlags = ->
  registry = ks.get "recommendations:list"

  updatedRegistry =
    "public": if registry?.public? then model.mapRegistryData registry.public else []
    "private": if registry?.private? then model.mapRegistryData registry.private else []

  ks.set "recommendations:list", updatedRegistry

model.mapRegistryData = (registryData) ->
  return registryData if ! utilsModel.typeIsArray registryData
  for registry in registryData
    registry.id = if registry.url then utilsModel.getProjectNameFromGitUrl registry.url else null
    registry.installed = if utilsModel.isProjectInstalled registry.id then true else false
  return registryData

model.loadRegistryContent = (registryUrl, callback) ->
  opts = url.parse registryUrl
  opts["headers"] = "accept": "application/json"
  server = if opts.protocol == "https:" then https else http
  req = server.request opts, (res) ->
    res.chunk = ""
    res.on 'data', (chunk) -> this.chunk += chunk;
    res.on 'end', () ->
      return callback new Error 'response set error code: ' + res.statusCode if res.statusCode.toString().substring(0, 1) != "2"
      try return callback null, JSON.parse res.chunk
      catch err
        return callback new Error 'failed to parse registry json'
  req.on "error", (err) -> return callback err
  req.on 'socket', (socket) ->
    socket.setTimeout 5000
    socket.on 'timeout', () ->
      return req.abort()
  req.end()

model.loadPrivateRegistryContent = (privates, callback) ->
  dataset = []
  counter = 0
  for extension, index in privates
    model.loadRegistryContent extension, (error, data) ->
      dataset.push pattern for pattern in data unless error
      counter++
      callback error, dataset, counter is privates?.length

model.loadRegistry = (callback) ->
  return callback new Error "No Registry link configured" if ! publicRegistry

  registry =
    public : []
    private : []

  model.loadRegistryContent publicRegistry, (error, data) ->
    registry.public = if ! error then model.mapRegistryData data else defaultRegistry
    return callback null, registry if not registryConfig.private?.length
    return model.loadPrivateRegistryContent registryConfig.private, (error, data) ->
      registry.private = model.mapRegistryData data unless error
      callback null, registry

model.loadRegistryWithInterval = () ->
  _r.withInterval loadingTimeout, (emitter) ->
    model.loadRegistry (err, result) ->
      return emitter.error err if err
      emitter.emit result
  .onValue (val) ->
    return ks.set 'recommendations:list', [] if ! val
    ks.set 'recommendations:list', val

# initial registry load - sets default data on fail
defaultRegistry = model.mapRegistryData defaultRegistry
model.loadRegistry (err, result) ->
  return ks.set 'recommendations:list', {public: defaultRegistry} if err
  ks.set 'recommendations:list', model.mapRegistryData result

# reevaluate recommendations -> projects mapping
ks.fromProperty 'projects:list'
.throttle(200)
.onValue model.updateRegistryInstallFlags

module.exports = model;