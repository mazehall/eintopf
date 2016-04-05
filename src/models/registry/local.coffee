_r = require 'kefir'

utilModel = require '../util/index.coffee'

registryData = null
fileName = 'registry.json'


model = {}

model.getRegistry = (callback) ->
  return callback null, registryData if registryData
  return callbacknew Error 'failed to get config dir' if !(configDir = utilModel.getConfigModulePath())

  utilModel.loadJsonAsync configDir + '/' + fileName, (err, result) ->
    registryData = result if !err
    callback err, result

model.getRegistryAsArray = (callback) ->
  model.getRegistry (err, result) ->
    return callback err if err
    return callback null, [] if typeof result != 'object'

    resultAsArray = []
    for key of (result || {})
      resultAsArray.push result[key]

    return callback null, resultAsArray

model.saveRegistry = (content, callback) ->
  return setTimeout(callback(new Error 'failed to get config dir'), 0) if !(configDir = utilModel.getConfigModulePath())

  utilModel.writeJsonAsync configDir + '/' + fileName, content, (err, result) ->
    return callback err if err
    registryData = content
    callback null, result

model.saveEntry = (recipe, callback) ->
  return callback new Error 'Invalid project description' if ! recipe?.name || ! recipe?.url

  _r.fromNodeCallback (cb) ->
    setTimeout ->
      model.getRegistry cb
    , 0
  .map (registry) ->
    registry = {} if ! registry

    recipe.registryUrl = 'local'
    registry[recipe.url] = recipe
    registry
  .flatMap (content) ->
    _r.fromNodeCallback (cb) ->
      model.saveRegistry content, cb
  .onError callback
  .onValue ->
    callback null, true

module.exports = model