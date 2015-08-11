config = require 'config'
vagrant = require 'node-vagrant'
_r = require 'kefir'

fsModel = require './fs.coffee'

getVagrantMachine = () ->
  configModulePath = fsModel.getConfigModulePath()
  return null if ! configModulePath?
  return vagrant.create {cwd: configModulePath}

model = {}
model.getVersion = (cb) ->
  vagrant.version cb

model.getStatus = (cb) ->
  machine = getVagrantMachine()
  return cb new Error 'get vagrant machine failed' if ! machine?
  machine.status (err, result) ->
    return cb new Error err if err
    return cb(null, i.status) for own d, i of result

model.up = (cb) ->
  machine = getVagrantMachine()
  return cb new Error 'get vagrant machine failed' if ! machine?
  machine.up cb

model.run = (callback) ->
  runningMessage = 'is_runnning'

  _r.fromNodeCallback (cb) ->
    setTimeout () ->
      model.getStatus (err, status) ->
        return cb new Error err if err
        return cb runningMessage if status == 'running'
        cb null, true
    , 1
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      model.up cb
  .onValue (val) ->
    callback null, val
  .onError (err) ->
    return callback null, true if err == runningMessage
    return callback new Error err if typeof err != "object"
    callback err

module.exports = model;