Dockerrode = require 'dockerode'
_r = require 'kefir'
ks = require 'kefir-storage'
fs = require 'fs'

model = {}

#@todo make dockerrode configurable
model.initDocker = () ->
  socket = process.env.DOCKER_SOCKET || '/var/run/docker.sock'
  isSocket = if fs.existsSync(socket) then fs.statSync(socket).isSocket() else false

  dockerConfig = if isSocket then { socketPath: socket } else {host: '127.0.0.1', port: "2375"}

  model.docker = new Dockerrode dockerConfig

model.getContainer = (name) ->
  model.docker.getContainer name

model.getImage = (name) ->
  model.docker.getImage name

model.createContainer = (config, callback) ->
  model.docker.createContainer config, callback

model.inspect = (name, callback) ->
  model.getContainer(name).inspect callback

model.startContainer = (name, callback) ->
  return callback new Error 'Container action already running' if ks.getChildProperty 'locks', 'containers:' + name

  ks.setChildProperty 'locks', 'containers:' + name, true

  _r.fromNodeCallback (cb) ->
    model.getContainer(name).start cb
  .flatMap -> # revert locks after next list update to sync view
    ks.fromProperty('containers:list').take(1)
  .onAny ->
    ks.setChildProperty 'locks', 'containers:' + name, false
  .onError callback
  .onValue (val) ->
    callback null, val

model.stopContainer = (name, callback) ->
  return callback new Error 'Container action already running' if ks.getChildProperty 'locks', 'containers:' + name

  ks.setChildProperty 'locks', 'containers:' + name, true

  _r.fromNodeCallback (cb) ->
    model.getContainer(name).stop cb
  .flatMap -> # revert locks after next list update to sync view
    ks.fromProperty('containers:list').take(1)
  .onAny ->
    ks.setChildProperty 'locks', 'containers:' + name, false
  .onError callback
  .onValue (val) ->
    callback null, val

model.removeContainer = (name, callback) ->
  return callback new Error 'Container action already running' if ks.getChildProperty 'locks', 'containers:' + name

  ks.setChildProperty 'locks', 'containers:remove:' + name, true

  _r.fromNodeCallback (cb) ->
    model.getContainer(name).remove cb
  .flatMap -> # revert locks after next list update to sync view
    ks.fromProperty('containers:list').take(1)
  .onAny ->
    ks.setChildProperty 'locks', 'containers:remove:' + name, false
  .onError callback
  .onValue (val) ->
    callback null, val

model.pull = (image, config, callback) ->
  config = {} if ! config

  model.docker.pull image, config, (err, stream) ->
    return callback err if err
    model.docker.modem.followProgress stream, callback

model.initDocker()
module.exports = model