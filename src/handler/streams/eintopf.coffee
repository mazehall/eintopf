_r = require 'kefir'
ks = require 'kefir-storage'
isOnline = require 'is-online'

config = require '../../models/stores/config'
utilModel = require '../../models/util'
projectsModel = require '../../models/projects/list.coffee'
registryModel = require '../../models/registry/index.coffee'

registryConfig = config.get 'registry'
registryLoadingTimeout = process.env.REGISTRY_INTERVAL || registryConfig.refreshInterval || 3600000

beat = _r.interval 1000, 'tick'
stream = _r.pool()


model = {}

model.enable = ->
  stream.plug(beat) if stream._isEmpty()

model.disable = ->
  stream.unplug(beat) if ! stream._isEmpty()


###########
# reload projects every minute
beat.throttle 60000
.onValue () ->
  projectsModel.loadProjects()


###########
# reevaluate recommendations -> projects mapping
ks.fromProperty 'projects:list'
.throttle(200)
.onValue registryModel.remapRegistries


###########
# reload registry data
beat.throttle registryLoadingTimeout
.onValue registryModel.init


###########
# update internet state
beat.throttle 10000
.flatMap ->
  checked = 0
  check = (cb) ->
    checked++
    isOnline cb

  _r.concat [ _r.fromNodeCallback(check), _r.fromNodeCallback(check), _r.fromNodeCallback(check)]
  .skipWhile (x) -> x != true && checked != 3
  .take 1
.onValue (value) ->
  ks.setChildProperty 'states:live', 'internet', value


###########
# persist available ssl certs
beat.throttle 5000
.flatMap () ->
  _r.fromNodeCallback (cb) ->
    return cb new Error 'Could not get proxy certs path' if ! (proxyCertsPath = utilModel.getProxyCertsPath())
    utilModel.loadCertFiles proxyCertsPath, cb
.map (certFiles) ->
  certs = {}
  for file in (certFiles || [])
    file.host = file.name.slice(0, -4)
    certs[file.host] = {files: []} if ! certs[file.host]
    certs[file.host]['files'].push file
  return certs
.onValue (certs) ->
  ks.set 'proxy:certs', certs


module.exports = model