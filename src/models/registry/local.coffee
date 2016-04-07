_r = require 'kefir'
tmp = require 'tmp'
git = require 'gift'

utils = require '../util/index.coffee'

registryData = null
fileName = 'registry.json'

tmp.setGracefulCleanup();

model = {}

model.getRegistry = (callback) ->
  return callback null, registryData if registryData
  return callback new Error 'failed to get config dir' if !(configDir = utils.getConfigModulePath())

  utils.loadJsonAsync configDir + '/' + fileName, (err, result) ->
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
  return setTimeout(callback(new Error 'failed to get config dir'), 0) if !(configDir = utils.getConfigModulePath())

  utils.writeJsonAsync configDir + '/' + fileName, content, (err, result) ->
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

model.streamAddEntryFromUrl = (projectUrl) ->
  return _r.constantError new Error 'Invalid project url' if ! (projectId = utils.getProjectNameFromGitUrl(projectUrl))

  _r.fromNodeCallback (cb) ->
    tmp.dir { mode: '0750', prefix: 'eintopf_', unsafeCleanup: true}, cb
  .flatMap (dirName) ->
    _r.fromNodeCallback (cb) ->
      git.clone projectUrl, dirName, cb
  .flatMap (repo) ->
    _r.fromNodeCallback (cb) ->
      utils.loadJsonAsync repo.path + '/package.json', cb
  .map (projectInfo) ->
    projectInfo = {} if ! projectInfo
    projectInfo.eintopf = {} if ! projectInfo.eintopf

    recipe =
      name: projectInfo.eintopf.name || projectId
      description: projectInfo.eintopf.description
      mediabg: projectInfo.eintopf.mediabg
      src: projectInfo.eintopf.src
      url: projectUrl
    recipe
  .flatMap (recipe) ->
    _r.fromNodeCallback (cb) ->
      model.saveEntry recipe, cb

module.exports = model