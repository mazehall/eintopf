config = require 'config'
vagrant = require 'node-vagrant'
_r = require 'kefir'
fs = require 'fs'
child_process = require 'child_process'

fsModel = require './fs.coffee'

vagrantInstalled = false

getVagrantMachine = (callback) ->
  configModulePath = fsModel.getConfigModulePath()
  return callback new Error '' if ! configModulePath?

  _r.fromNodeCallback (cb) ->
    fs.stat configModulePath, (err) ->
      cb new Error 'Can´t start vagrant without dedicated vagrant folder ' + configModulePath if err
      cb null, true
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      return cb null, true if vagrantInstalled == true
      child_process.spawn 'vagrant', ['version']
      .on 'close', () ->
        vagrantInstalled = true;
        cb null, true
      .on 'error', () ->
        cb new Error 'vagrant does not seems to be installed'
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      try
        machine = vagrant.create {cwd: configModulePath}
        cb null, machine
      catch err
        cb err
  .onValue (val) ->
    callback null, val
  .onError callback

model = {}
model.getVersion = (cb) ->
  vagrant.version cb

model.getStatus = (callback) ->
  _r.fromNodeCallback (cb) ->
    getVagrantMachine cb
  .flatMap (machine) ->
    _r.fromNodeCallback (cb) ->
      machine.status (err, result) ->
        return cb new Error err if err
        return cb(null, i.status) for own d, i of result
  .onValue (val) ->
    callback null, val
  .onError callback

model.up = (callback) ->
  _r.fromNodeCallback (cb) ->
    getVagrantMachine cb
  .flatMap (machine) ->
    _r.fromNodeCallback (cb) ->
      machine.up cb
  .onValue (val) ->
    callback null, val
  .onError callback

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