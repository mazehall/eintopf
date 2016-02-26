Dockerrode = require 'dockerode'


model = {}

model.docker = new Dockerrode {host: '127.0.0.1', port: "2375"}

model.getContainer = (name) ->
  model.docker.getContainer name

model.getImage = (name) ->
  model.docker.getImage name

model.createContainer = (config, callback) ->
  model.docker.createContainer config, callback

model.inspect = (name, callback) ->
  model.getContainer(name).inspect callback

model.startContainer = (name, callback) ->
  model.getContainer(name).start callback

model.stopContainer = (name, callback) ->
  model.getContainer(name).stop callback

model.removeContainer = (name, callback) ->
  model.getContainer(name).remove callback

model.pull = (image, config, callback) ->
  config = {} if ! config

  model.docker.pull image, config, (err, stream) ->
    return callback err if err
    model.docker.modem.followProgress stream, callback


module.exports = model