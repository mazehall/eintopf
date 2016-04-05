_r = require 'kefir'
ks = require 'kefir-storage'
crypto = require "crypto"

config = require '../stores/config.coffee'
utils = require '../util/index.coffee'
remote = require './remote.coffee'
local = require './local.coffee'

defaultRegistry = require '../../../config/default.registry.json'
registryConfig = config.get 'registry'
propertyPublic = 'registry:public'
propertyPrivate = 'registry:private:remote'
propertyLocal = 'registry:private:local'


model = {}

model.getRecipe = (id) ->
  for type in ['public', 'private']
    for i in (ks.get('registry:' + type) || [])
      return i if i.id == id
  return null

model.init = () ->
  model.initPublic()
  model.initPrivatesRemote()
  model.initPrivatesLocal()

model.streamFromPublic = ->
  if ! (publicUrl = process.env.REGISTRY_URL || registryConfig.public) || typeof publicUrl != "string"
    return _r.constantError new Error 'Unconfigured public registry'

  return _r.fromNodeCallback (cb) ->
    remote.loadFromUrls publicUrl, cb

model.streamFromPrivates = ->
  if ! registryConfig.private || (typeof registryConfig.private != "string" && ! utils.typeIsArray registryConfig.private)
    return _r.constantError new Error 'Unconfigured private registry'

  return _r.fromNodeCallback (cb) ->
    remote.loadFromUrls registryConfig.private, cb

model.initPublic = ->
  stream = model.streamFromPublic()
  .flatMapErrors -> _r.constant []
  .filter (data) ->
    ! (! data?.length && ks.get(propertyPublic)?) # skip when empty and something was set before
  .map (data) -> return if data?.length then data else defaultRegistry # use default registry when empty
  .map model.map
  .onValue (data) ->
    ks.set propertyPublic, data

model.initPrivatesRemote = ->
  model.streamFromPrivates()
  .flatMapErrors -> _r.constant []
  .filter (data) ->
    ! (! data?.length && ks.get(propertyPrivate)?) # skip when empty and something was set before
  .map model.map
  .onValue (data) ->
    ks.set propertyPrivate, data

model.initPrivatesLocal = ->
  _r.fromNodeCallback local.getRegistryAsArray
  .flatMapErrors -> _r.constant []
  .map model.map
  .onValue (data) ->
    ks.set propertyLocal, data

# update and set registry install flags
model.remapRegistries = ->
  _r.later 0, ['public', 'private:remote', 'private:local']
  .flatten()
  .map (type) ->
    property = 'registry:' + type
    {name: property, data: model.map ks.get property}
  .onValue (registry) ->
    ks.set registry.name, registry.data

model.map = (registryData) ->
  return null if ! utils.typeIsArray registryData

  for entry in (registryData || [])
    entry.id = crypto.createHash("md5").update(entry.url + entry.registryUrl).digest "hex" if entry?.url && entry.registryUrl
    entry.dirName = utils.getProjectNameFromGitUrl entry.url if entry?.url
    entry.installed = utils.isProjectInstalled entry.dirName if entry?.dirName && ! entry.pattern
  registryData

#@todo move to local model
tmp = require 'tmp'
git = require 'gift'

model.addLocalEntry = (projectUrl, callback) ->
  return callback new Error 'Invalid project url' if ! (projectId = utils.getProjectNameFromGitUrl(projectUrl))

  tmpDir = _r.fromNodeCallback (cb) ->
    tmp.dir { mode: '0750', prefix: 'eintopf_'}, cb
  .flatMap (dirName) ->
    _r.fromNodeCallback (cb) ->
      git.clone projectUrl, dirName, cb
  .flatMap (repo) ->
    _r.fromNodeCallback (cb) ->
      utils.loadJsonAsync repo.path + '/package.json', cb
  .map (projectInfo) ->
    projectInfo.eintopf = {} if ! projectInfo.eintopf

    recipe =
      name: projectInfo.eintopf.name
      description: projectInfo.eintopf.description
      mediabg: projectInfo.eintopf.mediabg
      src: projectInfo.eintopf.src
      url: projectUrl
    recipe
  .flatMap (recipe) ->
    _r.fromNodeCallback (cb) ->
      local.saveEntry recipe, cb
  .onError (err) ->
    return callback err
  .onValue (val) ->
    model.initPrivatesLocal()
    return callback null, true

module.exports = model