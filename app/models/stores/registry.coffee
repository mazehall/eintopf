_r = require 'kefir'
https = require "https"
http = require "http"
url = require 'url'

config = require '../stores/config'
watcherModel = require './watcher.coffee'
defaultRegistry = require '../../config/default.registry.json'
utilsModel = require '../util/index'

registryConfig = config.get 'registry'
loadingTimeout = process.env.REGISTRY_INTERVAL || registryConfig.refreshInterval || 3600000
publicRegistry = process.env.REGISTRY_URL || registryConfig.public || null

mapRegistryData = (registryData) ->
  return registryData if ! utilsModel.typeIsArray registryData
  for registry in registryData
    registry.id = if registry.url then utilsModel.getProjectNameFromGitUrl registry.url else null
    registry.installed = if utilsModel.isProjectInstalled registry.id then true else false
  return registryData

model = {}

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
    registry.public = if ! error then mapRegistryData data else defaultRegistry
    return callback null, registry if not registryConfig.private?.length
    return model.loadPrivateRegistryContent registryConfig.private, (error, data) ->
      registry.private = mapRegistryData data unless error
      callback null, registry

model.loadRegistryWithInterval = () ->
  _r.withInterval loadingTimeout, (emitter) ->
    model.loadRegistry (err, result) ->
      return emitter.error err if err
      emitter.emit result
  .onValue (val) ->
    return watcherModel.set 'recommendations:list', [] if ! val
    watcherModel.set 'recommendations:list', val

# initial registry load - sets default data on fail
defaultRegistry = mapRegistryData defaultRegistry
model.loadRegistry (err, result) ->
  registryContent = if err then {public: defaultRegistry} else mapRegistryData result
  return watcherModel.set 'recommendations:list', registryContent if not registryConfig?.private?.length
  return model.loadPrivateRegistryContent registryConfig.private, (error, data) ->
    registryContent.private = mapRegistryData data unless error
    watcherModel.set 'recommendations:list', registryContent

# reevaluate recommendations -> projects mapping
watcherModel.propertyToKefir 'projects:list'
.throttle(200)
.onValue ->
  recommendations = watcherModel.get "recommendations:list"
  recommendations.public = mapRegistryData recommendations.public if recommendations?.public?
  recommendations.private = mapRegistryData recommendations.private if recommendations?.private?
  watcherModel.set "recommendations:list", mapRegistryData recommendations

module.exports = model;