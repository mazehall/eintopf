_r = require 'kefir'
Dockerrode = require 'dockerode'
docker = new Dockerrode {host: '127.0.0.1', port: "2375"}
DockerEvents = require 'docker-events'

watcherModel = require '../stores/watcher.coffee'

containers = []

typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'


#@todo don't call loadContainers multiple times in a row
# triggers reloading of container list
initDockerEvents = () ->
  emitter = new DockerEvents {docker: docker}
  emitter.start();

  emitter.on "create", (message) ->
    model.loadContainers()
  emitter.on "start", (message) ->
    model.loadContainers()
  emitter.on "die", (message) -> # calls all stop sates
    model.loadContainers()
  emitter.on "error", (err) ->
    if err.code == "ECONNRESET" #try to reconnect after timeout
      setTimeout () ->
        emitter.stop()
        emitter.start()
        model.loadContainers() # connect event is not reliable so reload has to triggered manually
      , 10000

initDockerEvents()
model = {}
model.getContainerList = () ->
  return containers;

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

    if typeIsArray val.inspect.Config.Env
      val.inspect.Config.Env.forEach (env) ->
        push.virtualHost = match[1] if (match = env.match /^VIRTUAL_HOST=(.*)/)?

    foundContainers.push push
  .onEnd () ->
    containers = foundContainers
    watcherModel.set 'containers:list', containers

module.exports = model;