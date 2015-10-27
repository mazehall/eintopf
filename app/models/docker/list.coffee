_r = require 'kefir'
Dockerrode = require 'dockerode'
DockerEvents = require 'docker-events'
watcherModel = require '../stores/watcher.coffee'
config = require '../stores/config.coffee'
utilModel = require '../util/index.coffee'

typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'
docker = new Dockerrode {host: '127.0.0.1', port: "2375"}

runningProxyDeployment = false
proxyConfig = config.get 'proxy'

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
  containers = watcherModel.get 'containers:list'
  foundApps = []

  if typeIsArray containers
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
          foundApps.push app

  watcherModel.set 'apps:list', foundApps

getCerts = (host, certName) ->
  certs = watcherModel.get 'proxy:certs'
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
      return cb new Error 'proxy seems up to date' if proxyConfig.Image == data.Config.Image
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

model.loadContainers = () ->
  foundContainers = [];

  _r.fromNodeCallback (cb) ->
    docker.listContainers {"all": true}, cb
  .filter (x) ->
    typeIsArray x
  .flatten()
  .flatMap (containerInfo) ->
    _r.fromNodeCallback (cb) ->
      docker.getContainer(containerInfo.Id).inspect (err, result) ->
        return cb err if err
        return cb null, {info: containerInfo, inspect: result}
  .onValue (val) ->
    push =
      id: val.info.Id
      status: val.info.Status
      name: val.inspect.Name.replace(/\//g, '') # strip docker-compose slashes
      virtualHost: null
      certName: null

    if typeIsArray val.inspect.Config.Env
      val.inspect.Config.Env.forEach (env) ->
        push.virtualHost = match[1] if (match = env.match /^VIRTUAL_HOST=(.*)/)?
        push.certName = match[1] if (match = env.match /^CERT_NAME=(.*)/)?
    foundContainers.push push
  .onEnd () ->
    foundContainers.sort (a, b) ->
      return -1 if a.name < b.name
      return 1 if a.name > b.name
      return 0;
    watcherModel.set 'containers:list', foundContainers
    loadApps()


dockerEventsStream = _r.merge [_r.stream(emitEventsFromDockerStream), _r.interval(2000, 'reload')]

# update container list when changes in docker occurred
dockerEventsStream.throttle 1000
.onValue (event) ->
  model.loadContainers()

# check proxy container state
dockerEventsStream.throttle 10000
.flatMap () ->
  _r.fromNodeCallback (cb) ->
    return cb new Error "proxy deployment is already running" if runningProxyDeployment == true
    runningProxyDeployment = true
    model.deployProxy cb
.onAny (val) ->
  runningProxyDeployment = false if val.type != "error" || val.value.message != "proxy deployment is already running"

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
  watcherModel.set 'proxy:certs', certs

module.exports = model;
