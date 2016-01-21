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

  dockerEmitter.on "create", (message) -> emitter.emit 'create'
  dockerEmitter.on "start", (message) -> emitter.emit 'start'
  dockerEmitter.on "stop", (message) -> emitter.emit 'stop'
  dockerEmitter.on "destroy", (message) -> emitter.emit 'destroy'
  dockerEmitter.on "die", (message) -> emitter.emit 'die'
  dockerEmitter.on "error", (err) ->
    if err.code == "ECONNRESET" || err.code == "ECONNREFUSED" #try to reconnect after timeout
      setTimeout () ->
        dockerEmitter.stop()
        dockerEmitter.start()
        emitter.emit 'reconnect'
      , 10000

loadApps = () ->
  containers = ks.get 'containers:list'
  foundApps = []

  if utilModel.typeIsArray containers
    containers.forEach (container) ->
      if container.virtualHost? and container.status.match /^Up /
        virtualHosts = container.virtualHost.split(",")
        virtualHosts.forEach (virtualHost) ->
          return false if virtualHost.match /^\*/ # ignore wildcards
          certs = getCerts virtualHost, container.certName
          app =
            name: container.name
            host: virtualHost
            certs: certs if certs
            https: true if certs
            project: container.project
          foundApps.push app

  ks.set 'apps:list', foundApps

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
model.mapContainerData = (container) ->
  container.id = container.Id
  container.status = container.Status
  container.name = container.Names[0].replace(/\//g, '') if utilModel.typeIsArray container.Names # strip docker-compose slashes
  container.running = if container.status.match(/^Up/) then true else false

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
  currentContainers = ks.get 'containers:list'

  # use old inspect data if possible
  if utilModel.typeIsArray currentContainers
    for val in currentContainers
      if container.Id == val.id && typeof val.inspect == "object"
        container.inspect = val.inspect
        return callback null, model.mapContainerData container

  docker.getContainer(container.Id).inspect (err, result) ->
    return callback err if err

    container.inspect = result
    return callback null, model.mapContainerData container

model.loadContainers = (callback) ->
  foundContainers = [];

  _r.fromNodeCallback (cb) ->
    docker.listContainers {"all": true}, cb
  .filter (x) ->
    utilModel.typeIsArray x
  .flatten().flatMap (container) ->
    _r.fromNodeCallback (cb) ->
      model.loadContainer container, cb
  .onValue (val) ->
    foundContainers.push val
  .onEnd () ->
    foundContainers.sort (a, b) ->
      return -1 if a.name < b.name
      return 1 if a.name > b.name
      return 0;
    callback null, foundContainers


dockerEventsStream = _r.merge [_r.stream(emitEventsFromDockerStream), _r.interval(2000, 'reload')]

# update container list
dockerEventsStream.throttle 1000
.flatMap ->
  _r.fromNodeCallback (cb) ->
    model.loadContainers cb
.onValue (containers) ->
  ks.set 'containers:list', containers
  loadApps()

# check proxy container state
dockerEventsStream.throttle 10000
.flatMap () ->
  _r.fromNodeCallback (cb) ->
    return cb new Error messageProxyAlreadyInstalling if runningProxyDeployment is true
    runningProxyDeployment = true
    model.deployProxy cb
.onAny (val) ->
  runningProxyDeployment = false if val.type != "error" || val.value.message != messageProxyAlreadyInstalling
.onError (err) ->
  ignoredErrorMessages = [messageProxyUpToDate, messageProxyAlreadyInstalling]
  ignoredErrorCodes = ['ECONNREFUSED', 'ECONNRESET']
  return false if ! ignoredErrorMessages.indexOf(err.message) || ! ignoredErrorCodes.indexOf(err.code)

  message = messageErrProxyPre + err + messageErrProxyPost
  ks.set "backend:errors", [{message: message, read: false, date: Date.now()}]
.onValue ->
  ks.set "backend:errors", []

# persist available ssl certs
proxyCertsStream = _r.interval 5000, 'reload'
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

module.exports = model;
