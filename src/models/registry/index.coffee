_r = require 'kefir'
ks = require 'kefir-storage'
crypto = require "crypto"

config = require '../stores/config.coffee'
utils = require '../util/index.coffee'
remote = require './remote.coffee'

defaultRegistry = require '../../../config/default.registry.json'
registryConfig = config.get 'registry'
propertyPublic = 'registry:public'
propertyPrivate = 'registry:private:remote'


model = {}

model.getRecipe = (id) ->
  for type in ['public', 'private']
    for i in ks.get 'registry:' + type
      return i if i.id == id
  return null

model.init = () ->
  model.initPublic()
  model.initPrivates()

model.initPublic = () ->
  if ! (publicUrl = process.env.REGISTRY_URL || registryConfig.public) || typeof publicUrl != "string"
    return _r.constantError new Error 'Unconfigured public registry'

  _r.fromNodeCallback (cb) ->
    remote.loadFromUrls publicUrl, cb
  .map (data) ->
    if ! data?.length
      data = if (oldData = ks.get propertyPublic) && oldData?.length then oldData else defaultRegistry
    data
  .map (data) ->
    model.map data
  .onValue (data) ->
    ks.set propertyPublic, data

model.initPrivates = () ->
  if ! registryConfig.private || (typeof registryConfig.private != "string" && ! utils.typeIsArray registryConfig.private)
    return _r.constantError new Error 'Unconfigured private registry'

  _r.fromNodeCallback (cb) ->
    remote.loadFromUrls registryConfig.private, cb
  .map (data) ->
    model.map data
  .onValue (data) ->
    ks.set propertyPrivate, data || []

# update and set registry install flags
model.remapRegistries = ->
  _r.later 0, ['public', 'private']
  .flatten()
  .map (type) ->
    property = 'registry:' + type
    {name: property, data: model.map ks.get property}
  .onValue (registry) ->
    ks.set registry.name, registry.data

model.map = (registryData) ->
  return registryData if ! utils.typeIsArray registryData

  for entry in registryData
    entry.id = crypto.createHash("md5").update(entry.url + entry.registryUrl).digest "hex" if entry?.url && entry.registryUrl
    entry.dirName = utils.getProjectNameFromGitUrl entry.url if entry?.url
    entry.installed = utils.isProjectInstalled entry.dirName if entry?.dirName && ! entry.pattern
  registryData

module.exports = model