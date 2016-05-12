_r = require 'kefir'

utilModel = require '../util/index.coffee'

customData = null
fileName = 'custom.json'


model = {}

model.getCustomData = (callback) ->
  return callback null, customData if customData
  return callbacknew Error 'failed to get config dir' if !(configDir = utilModel.getConfigModulePath())

  utilModel.loadJsonAsync configDir + '/' + fileName, (err, result) ->
    customData = result if !err
    callback err, result

model.saveCustomData = (content, callback) ->
  return setTimeout(callback(new Error 'failed to get config dir'), 0) if !(configDir = utilModel.getConfigModulePath())

  utilModel.writeJsonAsync configDir + '/' + fileName, content, (err, result) ->
    return callback err if err
    customData = content
    callback null, result

model.saveCustomization = (project, callback) ->
  return callback new Error 'Invalid project description' if ! project?.id

  custom =
    name: project.name || null,
    description: project.description || null
    mediabg: project.mediabg || null
    src: project.src || null

  _r.fromNodeCallback (cb) ->
    setTimeout ->
      model.getCustomData cb
    , 0
  .map (content) ->
    content = {} if ! content
    content.projects = {} if ! content.projects
    content.projects[project.id] = custom
    content
  .flatMap (content) ->
    _r.fromNodeCallback (cb) ->
      model.saveCustomData content, cb
  .onError callback
  .onValue ->
    callback null, true

model.clearCustomization = (projectId, callback) ->
  return callback new Error 'Invalid project id' if ! projectId
  update = false

  _r.fromNodeCallback (cb) ->
    setTimeout ->
      model.getCustomData cb
    , 0
  .map (content) ->
    if content.projects?[projectId]?
      delete content.projects[projectId]
      update = true
    content
  .flatMap (content) ->
    return _r.constant true if ! update
    _r.fromNodeCallback (cb) ->
      model.saveCustomData content, cb
  .onError callback
  .onValue ->
    callback null, true

model.getProject = (projectId, callback) ->
  return callback new Error 'Invalid project id' if ! projectId

  _r.fromNodeCallback (cb) ->
    setTimeout ->
      model.getCustomData cb
    , 0
  .map (fileContent) ->
    fileContent?.projects?[projectId] || {}
  .onError callback
  .onValue (customizations) ->
    callback null, customizations

module.exports = model