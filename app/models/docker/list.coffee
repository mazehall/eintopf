_r = require 'kefir'
Dockerrode = require 'dockerode'
DockerEvents = require 'docker-events'
ks = require 'kefir-storage'

config = require '../stores/config.coffee'
utilModel = require '../util/index.coffee'

docker = new Dockerrode {host: '127.0.0.1', port: "2375"}

runningProxyDeployment = false
proxyConfig = config.get 'proxy'

messageProxyUpToDate = 'proxy seems up to date'
messageProxyAlreadyInstalling = "proxy deployment is already running"
messageErrProxyPre = "Error while installing proxy: "
messageErrProxyPost = ". Please check your internet connection!"

emitEventsFromDockerStream = (emitter) ->
  dockerEmitter = new DockerEvents {docker: docker}
  dockerEmitter.start();

  dockerEmitter.on "create", (message) -> emitter.emit {type: 'create', value: message}
  dockerEmitter.on "start", (message) -> emitter.emit {type: 'start', value: message}
  dockerEmitter.on "stop", (message) -> emitter.emit {type: 'stop', value: message}
  dockerEmitter.on "destroy", (message) -> emitter.emit {type: 'destroy', value: message}
  dockerEmitter.on "die", (message) ->emitter.emit {type: 'die', value: message}
  dockerEmitter.on "error", (err) ->
    if err.code == "ECONNRESET" || err.code == "ECONNREFUSED" #try to reconnect after timeout
      setTimeout () ->
        dockerEmitter.stop()
        dockerEmitter.start()
        emitter.emit {type: 'reconnect'}
      , 10000

getCerts = (host, certName) ->
  certs = ks.get 'proxy:certs'
  return certs[certName] if certName && certs?[certName]
  return certs[host] if certs?[host]

  resolveWildcard = host
  while (n = resolveWildcard.indexOf ".") && n > 0
    resolveWildcard = resolveWildcard.substr n + 1
    return certs[resolveWildcard] if certs?[resolveWildcard]
  return null;

model = {}

model.pullImage = (image, config, callback) ->
  config = {} if ! config

  docker.pull image, config, (err, stream) ->
    return callback err if err
    docker.modem.followProgress stream, callback

model.deployProxy = (callback) ->
  container = docker.getContainer proxyConfig.name
  image = docker.getImage proxyConfig.Image

  _r.fromNodeCallback (cb) ->
    container.inspect (err, data) ->
      return cb err if err && err.statusCode != 404
      cb null, data
  .flatMap (data) ->
    _r.fromNodeCallback (cb) ->
      return cb null, true if data == null
      return cb new Error messageProxyUpToDate if proxyConfig.Image == data.Config.Image
      container.remove {force:true}, cb
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      image.inspect (err, result) ->
        return model.pullImage proxyConfig.Image, null, cb if err && err.statusCode == 404
        return cb err, result
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      docker.createContainer proxyConfig, cb
  .flatMap (container) ->
    _r.fromNodeCallback (cb) ->
      container.start cb
  .onError callback
  .onValue (val) ->
    callback null, val

model.startContainer = (containerId, callback) ->
  return callback new Error 'invalid Docker Id' if typeof x == "string"

  container = docker.getContainer containerId
  container.start callback

model.stopContainer = (containerId, callback) ->
  return callback new Error 'invalid Docker Id' if typeof x == "string"

  container = docker.getContainer containerId
  container.stop callback

model.removeContainer = (containerId, callback) ->
  return callback new Error 'invalid Docker Id' if typeof x == "string"

  container = docker.getContainer containerId
  container.remove callback

# maps container data
model.mapInspectData = (container) ->
  if (labels = container.inspect.Config.Labels) and labels["com.docker.compose.project"]
    container.project = labels["com.docker.compose.project"]

  if (utilModel.typeIsArray container.inspect.Config.Env)
    for env in container.inspect.Config.Env
      container.virtualHost = match[1] if (match = env.match /^VIRTUAL_HOST=(.*)/)?
      container.certName = match[1] if (match = env.match /^CERT_NAME=(.*)/)?
  return container

# loads container inspect data and adds that plus somme additional mapped data
model.loadContainer = (container, callback) ->
  return callback new Error 'invalid container' if !container || !container.Id

  docker.getContainer(container.Id).inspect (err, result) ->
    return callback err if err

    container.inspect = result
    return callback null, model.mapInspectData container

model.initApps = (container) ->
  return false if ! container?.virtualHost

  virtualHosts = container.virtualHost.split(",")
  virtualHosts.forEach (virtualHost) ->
    return false if virtualHost.match /^\*/ # ignore wildcards

    certs = getCerts virtualHost, container.certName
    app =
      running: container.running
      name: container.name
      host: virtualHost
      certs: certs if certs
      https: true if certs
      project: container.project

    ks.setChildProperty 'apps:list', virtualHost, app

model.inspectContainers = (containers) ->
  return false if ! utilModel.typeIsArray containers

  stream = _r.pool()
  stream.flatten()
  .filter (container) ->
    !(ks.getChildProperty 'containers:inspect', container.Id)
  .flatMap (container) ->
    _r.fromNodeCallback (cb) ->
      model.loadContainer container, cb
  .onValue (container) ->
    ks.setChildProperty 'containers:inspect', container.Id, container
    model.initApps container

  stream.plug _r.constant containers

model.loadContainers = ->
  _r.fromNodeCallback (cb) ->
    docker.listContainers {"all": true}, cb
  .map (containers) ->
    for container in containers
      container.id = container.Id
      container.status = container.Status
      container.name = container.Names[0].replace(/\//g, '') if utilModel.typeIsArray container.Names # strip docker-compose slashes
      container.running = if container.status.match(/^Up/) then true else false
    containers
  .map (containers) ->
    containers.sort (a, b) ->
      return -1 if a.name < b.name
      return 1 if a.name > b.name
      return 0;
  .onError (error) -> # reset on connection error
    ks.set 'containers:list', []
    ks.set 'containers:inspect', {}
    ks.set 'apps:list', {}
  .onValue (containers) ->
    ks.set 'containers:list', containers
    model.inspectContainers containers

module.exports = model;

#######################
# runtime streams
#

# update docker container list
_r.interval 2000
.onValue () ->
  model.loadContainers()

# update inspect running state on die and start container
_r.stream emitEventsFromDockerStream
.filter (event) ->
  event?.value?.id && ['die', 'start'].indexOf(event.type) >= 0
.map  (event) ->
  event.container = ks.getChildProperty 'containers:inspect', event.value.id
  event
.filter (event) -> event.container?
.onValue (event) ->
  event.container.running = if event.type == 'start' then true else false
  ks.setChildProperty 'containers:inspect', event.value.id, event.container
  model.initApps event.container

# clear inspect data if container was destroyed
_r.stream emitEventsFromDockerStream
.filter (event) ->
  event?.value?.id && event.type == 'destroy'
.onValue (event) ->
  ks.setChildProperty 'containers:inspect', event.value.id, null

# check proxy container state
_r.interval 10000
.flatMap () ->
  _r.fromNodeCallback (cb) ->
    return cb new Error messageProxyAlreadyInstalling if runningProxyDeployment is true
    runningProxyDeployment = true
    model.deployProxy cb
.onAny (val) ->
  runningProxyDeployment = false if val.type != "error" || val.value.message != messageProxyAlreadyInstalling
.filterErrors (err) ->
  ignoredErrorMessages = [messageProxyAlreadyInstalling]
  ignoredErrorCodes = ['ECONNREFUSED', 'ECONNRESET']
  return true if ignoredErrorMessages.indexOf(err.message) < 0 && ignoredErrorCodes.indexOf(err.code) < 0
.onError (err) ->
  return ks.set "backend:errors", [] if err.message == messageProxyUpToDate

  message = messageErrProxyPre + err + messageErrProxyPost
  ks.set "backend:errors", [{message: message, read: false, date: Date.now()}]
.onValue ->
  ks.set "backend:errors", []

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
