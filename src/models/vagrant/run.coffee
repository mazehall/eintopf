_r = require 'kefir'
ks = require 'kefir-storage'
vagrant = require 'node-vagrant'
jetpack = require "fs-jetpack"

utilModel = require '../util/'
terminalModel = require '../util/terminal.coffee'
sshModel = require './ssh.coffee'

isVagrantInstalled = (callback) ->
  return callback new Error 'failed to initialize vagrant' if ! (machine = model.getVagrantMachine())?

  child = machine._run ['version']
  child.on 'close', () ->
    callback null, true
  child.on 'error', (err) ->
    callback new Error 'vagrant is apparently not installed'

model = {}

model.getVagrantMachine = (callback) ->
  return callback new Error '' if ! (configModulePath = utilModel.getConfigModulePath())?
  return machine = vagrant.create {cwd: configModulePath}

model.getStatus = (callback) ->
  return callback new Error 'failed to initialize vagrant' if ! (machine = model.getVagrantMachine())?
  machine.status (err, result) ->
    return callback new Error err if err
    return callback(null, i.status) for own d, i of result

model.getSshConfig = (callback) ->
  return callback new Error 'failed to initialize vagrant' if ! (machine = model.getVagrantMachine())?

  machine.sshConfig (error, config) ->
    return callback? error if error
    return machine._run ["ssh", "-c", "hostname -I | cut -d' ' -f2"], (error, hostname) ->
      config.hostname = hostname if hostname and not error
      callback? error, config

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

  machine.sshConfig (error, config) ->
    return callback error if error
    return machine._run ["ssh", "-c", "hostname -I | cut -d' ' -f2"], (error, hostname) ->
      config.hostname = hostname if hostname and not error
      callback error, config

  terminalModel.createPTYStream 'vagrant reload', {cwd: machine.opts.cwd, env: machine.opts.env}, (err) ->
    return callback err if err
    return callback null, true

model.up = (callback) ->
  return callback new Error 'failed to initialize vagrant' if ! (machine = model.getVagrantMachine())?
  failedSsh = false

  ks.log 'terminal:output', {text: 'starts vagrant from ' + machine.opts.cwd}

  proc = terminalModel.createPTYStream 'vagrant up', {cwd: machine.opts.cwd, env: machine.opts.env}, (err) ->
    return callback new Error 'SSH connection failed' if failedSsh #@todo better implementation???
    return callback err if err
    return callback null, true

  proc.stdout.on 'data', (val) ->
    if (val.toString().match /(Warning: Authentication failure. Retrying...)/ )
      proc.emit 'error', new Error 'SSH connection failed'
      failedSsh = true
      if proc.pty then proc.destroy() else proc.kill('SIGINT')

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
