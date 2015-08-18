_r = require 'kefir'
Dockerrode = require 'dockerode'
docker = new Dockerrode {host: '127.0.0.1', port: "2375"}
DockerEvents = require 'docker-events'

containers = []

typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

# triggers reloading of container list
#@todo don't call loadContainers multiple times in a row
initDockerEvents = () ->
  emitter = new DockerEvents {docker: docker}
  emitter.start();

  emitter.on "connect", () ->
    console.log("connected to docker api");
    model.loadContainers()
  emitter.on "disconnect", () ->
    #@todo implement reconnect (kefir? try till reconnect)
    console.log("disconnected to docker api; reconnecting");
    emitter.start();
  emitter.on "create", (message) ->
    console.log("container created: %j", message);
    model.loadContainers()
  emitter.on "start", (message) ->
    console.log("container started: %j", message);
    model.loadContainers()
  emitter.on "die", (message) -> # calls all stop sates
    console.log("container died: %j", message);
    model.loadContainers()
  emitter.on "error", (err) ->
    console.log 'err', err

initDockerEvents()
model = {}
model.getContainerList = () ->
  return containers;

#@todo emit changes
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
    console.log containers

module.exports = model;
