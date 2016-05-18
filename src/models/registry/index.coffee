_r = require 'kefir'
ks = require 'kefir-storage'
crypto = require "crypto"
config = require 'config'

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

model.addLocalEntryFromUrl = (projectUrl, callback) ->
  local.streamAddEntryFromUrl projectUrl
  .onError callback
  .onValue (val) ->
    model.initPrivatesLocal()
    return callback null, val

module.exports = model