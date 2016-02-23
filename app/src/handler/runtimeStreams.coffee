_r = require 'kefir'
ks = require 'kefir-storage'
isOnline = require 'is-online'

utilModel = require '../models/util'
dockerProxyModel = require '../models/docker/proxy.coffee'
dockerListModel = require '../models/docker/list.coffee'
dockerEventStream = require '../models/docker/events.coffee'
projectsModel = require '../models/projects/list.coffee'
registryModel = require '../models/stores/registry.coffee'


###########
# update docker container list
_r.interval 2000
.onValue () ->
  dockerListModel.loadContainers()


###########
# reload projects every minute
projectsEventStream = _r.interval(60000, 'reload')
.onValue () ->
  projectsModel.loadProjects()


###########
# reevaluate recommendations -> projects mapping
ks.fromProperty 'projects:list'
.throttle(200)
.onValue registryModel.updateRegistryInstallFlags


###########
# clear inspect data if container was destroyed
dockerEventStream
.filter (event) ->
  event?.value?.id && event.type == 'destroy'
.onValue (event) ->
  ks.setChildProperty 'containers:inspect', event.value.id, null


###########
# update internet state
_r.interval 5000
.flatMap ->
  _r.fromNodeCallback (cb) ->
    isOnline cb
.onValue (value) ->
  ks.setChildProperty 'states:live', 'internet', value


###########
# monitor certificate changes and sync them accordingly
_r.merge [ks.fromProperty('projects:certs'), ks.fromProperty('proxy:certs')]
.throttle 5000
.onValue (val) ->
  return false if ! (proxyCertsPath = utilModel.getProxyCertsPath())?
  projectCerts = if val.name == 'projects:certs' then val.value else ks.get 'projects:certs'

  utilModel.syncCerts proxyCertsPath, projectCerts, ->


###########
# update inspect running state on die and start container
dockerEventStream
.filter (event) ->
  event?.value?.id && ['die', 'start'].indexOf(event.type) >= 0
.map  (event) ->
  event.container = ks.getChildProperty 'containers:inspect', event.value.id
  event
.filter (event) -> event.container?
.onValue (event) ->
  event.container.running = if event.type == 'start' then true else false
  ks.setChildProperty 'containers:inspect', event.value.id, event.container
  dockerListModel.initApps event.container


###########
# persist available ssl certs
_r.interval 5000, 'reload'
.flatMap () ->
  _r.fromNodeCallback (cb) ->
    return cb new Error 'Could not get proxy certs path' if ! (proxyCertsPath = utilModel.getProxyCertsPath())
    utilModel.loadCertFiles proxyCertsPath, cb
.map (certFiles) ->
  certs = {}
  for file in certFiles
    file.host = file.name.slice(0, -4)
    certs[file.host] = {files: []} if ! certs[file.host]
    certs[file.host]['files'].push file
  return certs
.onValue (certs) ->
  ks.set 'proxy:certs', certs


###########
# monitor proxy container
_r.interval 10000, 'tick'
.flatMap () ->
  _r.fromNodeCallback (cb) ->
    dockerProxyModel.monitorProxy cb
.onError (err) ->
  connectCodes = ['ECONNREFUSED', 'ECONNRESET']
  ks.setChildProperty 'states:live', 'proxy', false

  if connectCodes.indexOf(err.code) >= 0
    ks.setChildProperty 'states:live', 'proxyError', 'Cannot connect to docker'
  else
    ks.setChildProperty 'states:live', 'proxyError', err.message
.onValue ->
  ks.setChildProperty 'states:live', 'proxy', true
  ks.setChildProperty 'states:live', 'proxyError', null


###########
# update apps running state on container inspect change
ks.fromProperty 'containers:inspect'
.throttle 2000
.map (containers) ->
  runningProjects = {}
  for id, container of containers.value
    runningProjects[container.project] = true if container?.running && container.project
  runningProjects
.onValue (runningProjects) ->
  projects = ks.get "projects:list"

  for project in projects
    project.state = if runningProjects[project.id] then 'running' else null

  ks.set "projects:list", projects
