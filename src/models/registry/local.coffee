_r = require 'kefir'
ks = require 'kefir-storage'

utilModel = require '../util/index.coffee'

registryFileName = 'registry.local.json'


model = {}

model.loadFile = (callback) ->
  return callback new Error 'failed to get config dir' if !(configDir = utilModel.getConfigModulePath())

  utilModel.loadJsonAsync configDir + '/' + registryFileName, callback

model.saveFile = (content, callback) ->
  return callback new Error 'failed to get config dir' if !(configDir = utilModel.getConfigModulePath())

  utilModel.writeJsonAsync configDir + '/' + registryFileName, content, callback

model.addFromProject = (project, callback) ->
  return callback new Error 'Invalid description data' if ! project?.eintopf?.name

  # update if entry already exists
#  (return model.updateEntryFromProject project, callback if entry.name == project.name) for entry in ks.get storageProperty

  recipe =
    id: project.name
    name: project.eintopf.name,
    description: project.eintopf.description
    mediabg: project.eintopf.mediabg
    src: project.eintopf.src
    url: null
    parent: project.eintopf.parent

  _r.fromNodeCallback (cb) ->
    model.loadFile cb
  .map (content) ->
    content = [] if ! content
    content.push recipe

    content.sort (a, b) ->
      return -1 if a.name < b.name
      return 1 if a.name > b.name
      return 0;
    content
  .flatMap (content) ->
    _r.fromNodeCallback (cb) ->
      model.saveFile content, cb
  .onError callback
  .onValue ->
    callback null, true

model.updateEntryFromProject = (project, callback) ->


module.exports = model