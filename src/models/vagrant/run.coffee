_r = require 'kefir'
ks = require 'kefir-storage'
jetpack = require "fs-jetpack"

utilModel = require '../util/'
terminalModel = require '../util/terminal.coffee'
virtualboxModel = require './virtualbox.coffee'
sshModel = require './ssh.coffee'
fsModel = require './fs.coffee'

model = {}

model.isVagrantInstalled = (callback) ->
  cmd = if process.platform == 'win32' then 'where vagrant.exe' else 'which vagrant'

  utilModel.runCmd cmd, null, null, null, (err, result) ->
    return callback new Error 'vagrant is apparently not installed' if err
    callback null, true

model.getStatus = virtualboxModel.getGuestStatus

model.getSshConfig = (callback) ->
  fsModel.getSSHConfig (error, config) ->
    return callback? error if error

    virtualboxModel.getGuestIps (err, ips) -> # only take the second ip
      config.hostname = if ips.length >= 2 then ips[1] else ''
      return callback? error, config

model.reloadWithNewSsh = (callback) ->
  _r.fromNodeCallback (cb) ->
    sshModel.installNewKeys cb
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      model.reload cb
  .onError callback
  .onValue (val) ->
    callback null, val

model.reload = (callback) ->
  return callback new Error 'failed to fetch config path' if ! (configModulePath = utilModel.getConfigModulePath())?

  terminalModel.createPTYStream 'vagrant reload', {cwd: configModulePath, env: process.env}, (err) ->
    return callback err if err
    return callback null, true

model.up = (callback) ->
  return callback new Error 'failed to fetch config path' if ! (configModulePath = utilModel.getConfigModulePath())?
  failedSsh = false

  ks.log 'terminal:output', {text: 'starts vagrant from ' + configModulePath}

  proc = terminalModel.createPTYStream 'vagrant up', {cwd: configModulePath, env: process.env}, (err) ->
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

  _r.fromNodeCallback model.isVagrantInstalled
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      model.getStatus (err, running) ->
        return cb new Error err if err
        return cb runningMessage if running
        cb null, true
  .flatMap () ->
    _r.fromNodeCallback model.up
  .onValue (val) ->
    callback null, val
  .onError (err) ->
    return callback null, true if err == runningMessage
    return model.reloadWithNewSsh callback if err.message == "SSH connection failed"
    return callback new Error err if typeof err != "object"
    callback err

module.exports = model;
