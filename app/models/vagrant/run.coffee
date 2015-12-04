_r = require 'kefir'
vagrant = require 'node-vagrant'
jetpack = require "fs-jetpack"

utilModel = require '../util/'
terminalModel = require '../util/terminal.coffee'
watcherModel = require '../stores/watcher.coffee'

isVagrantInstalled = (callback) ->
  return callback new Error 'failed to initialize vagrant' if ! (machine = model.getVagrantMachine())?

  child = machine._run ['version']
  child.on 'close', () ->
    callback null, true
  child.on 'error', (err) ->
    callback new Error 'vagrant is apparently not installed'

model = {}

#@todo does it have to run completely every time?
model.getVagrantMachine = (callback) ->
  return callback new Error '' if ! (configModulePath = utilModel.getConfigModulePath())?
  return machine = vagrant.create {cwd: configModulePath}

model.getStatus = (callback) ->
  return callback new Error 'failed to initialize vagrant' if ! (machine = model.getVagrantMachine())?
  machine.status (err, result) ->
    return callback new Error err if err
    return callback(null, i.status) for own d, i of result

# get current virtualBox dir. There is currently only one supported
model.getOnlyVirtualBoxDir = (callback) ->
  return callback new Error "Invalid config path" if ! (configPath = utilModel.getConfigModulePath())

  configDir = jetpack.cwd configPath

  _r.fromPromise jetpack.findAsync configDir.path(), {matching: ["./.vagrant/machines/*/virtualbox"]}, "inspect"
  .flatMap (folders) ->
    _r.fromNodeCallback (cb) ->
      return cb new Error "can't maintain integrity with multiple machine folders" if folders.length > 1
      cb null, folders[0]
  .onError callback
  .onValue (val) ->
    callback null, val

#@todo move to ssh model???
model.reloadWithNewSsh = (callback) ->
  _r.fromNodeCallback (cb) ->
    sshModel.installNewKeys cb
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      model.reload cb
  .onError callback
  .onValue (val) ->
    callback null, value

model.reload = (callback) ->
  return callback new Error 'failed to initialize vagrant' if ! (machine = model.getVagrantMachine())?

  terminalModel.createPTYStream 'vagrant reload', {cwd: machine.opts.cwd, env: machine.opts.env}, (err) ->
    return callback err if err
    return callback null, true

model.up = (callback) ->
  return callback new Error 'failed to initialize vagrant' if ! (machine = model.getVagrantMachine())?
  failedSsh = false

  proc = terminalModel.createPTYStream 'vagrant up', {cwd: machine.opts.cwd, env: machine.opts.env}, (err) ->
    return callback new Error 'SSH connection failed' if failedSsh #@todo better implementation???
    return callback err if err
    return callback null, true

  if proc.pty
    proc.stdout.on 'data', (val) ->
      if (val.match /(Warning: Authentication failure. Retrying...)/ )
        failedSsh = true
        proc.emit 'error', new Error 'SSH connection failed'
        proc.destroy()
  else # use stdin when not in pty mode
    proc.stdin.on 'data', (val) ->
      if (val.match /(Warning: Authentication failure. Retrying...)/ )
        failedSsh = true
        proc.emit 'error', new Error 'SSH connection failed'
        proc.destroy()

model.run = (callback) ->
  runningMessage = 'is_runnning'

  _r.fromNodeCallback (cb) ->
    setTimeout () ->
      isVagrantInstalled cb
    , 1
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      model.getStatus (err, status) ->
        return cb new Error err if err
        return cb runningMessage if status == 'running'
        cb null, true
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
        model.up cb
  .onValue (val) ->
    callback null, val
  .onError (err) ->
    return callback null, true if err == runningMessage
    return model.reloadWithNewSsh callback if err.message == "SSH connection failed"
    return callback new Error err if typeof err != "object"
    callback err

module.exports = model;

#@todo improve require order
sshModel = require './ssh.coffee'