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
registryUrl = process.env.REGISTRY_URL || registryConfig.url || null

mapRegistryData = (registryData) ->
  return registryData if ! utilsModel.typeIsArray registryData
  for registry in registryData
    registry.id = if registry.url then utilsModel.getProjectNameFromGitUrl registry.url else null
    registry.installed = if utilsModel.isProjectInstalled registry.id then true else false
  return registryData

model = {}

model.loadRegistry = (callback) ->
  return callback new Error "No Registry link configured" if ! registryUrl

  opts = url.parse registryUrl
  opts["headers"] =
    "accept": "application/json"

  server = if opts.protocol == "https:" then https else http
  req = server.request opts, (res) ->
    res.chunk = ""
    res.on 'data', (chunk) ->
      this.chunk += chunk;
    res.on 'end', () ->
      return callback new Error 'response set error code: ' + res.statusCode if res.statusCode.toString().substring(0, 1) != "2"

      try
        return callback null, JSON.parse res.chunk
      catch err
        return callback new Error 'failed to parse registry json'
  req.on 'socket', (socket) ->
    socket.setTimeout 5000
    socket.on 'timeout', () ->
      return req.abort()
  req.on "error", (err) ->
    return callback err
  req.end()

model.loadRegistryWithInterval = () ->
  _r.withInterval loadingTimeout, (emitter) ->
    model.loadRegistry (err, result) ->
      return emitter.error err if err
      emitter.emit result
  .onValue (val) ->
    return watcherModel.set 'recommendations:list', [] if ! val
    watcherModel.set 'recommendations:list', mapRegistryData val
  .onError (err) ->
    if ! watcherModel.get 'recommendations:list' # set default data if nothing is set
      watcherModel.set 'recommendations:list', defaultRegistry

# initial registry load - sets default data on fail
defaultRegistry = mapRegistryData defaultRegistry
model.loadRegistry (err, result) ->
  return watcherModel.set 'recommendations:list', defaultRegistry if err
  watcherModel.set 'recommendations:list', mapRegistryData result

# reevaluate recommendations -> projects mapping
watcherModel.propertyToKefir 'projects:list'
.throttle(200)
.onValue ->
  watcherModel.set "recommendations:list", mapRegistryData watcherModel.get "recommendations:list"

module.exports = model;