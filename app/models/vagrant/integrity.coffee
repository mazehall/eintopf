_r = require 'kefir'
jetpack = require "fs-jetpack"
NodeRSA = require 'node-rsa'
forge = require 'node-forge'

utilModel = require "../util/index.coffee"
terminalModel = require "../util/terminal.coffee"

model = {}
model.restoreMachineId = (id, path, callback) ->
  return callback new Error 'invalid parameters' if ! id || ! path

  _r.fromPromise jetpack.writeAsync path, id, {atomic: true}
  .onError callback
  .onValue ->
    return callback null, true

model.restoreFromMachineFolder = (callback) ->
  return callback new Error "Invalid config path" if ! (configPath = utilModel.getConfigModulePath())

  vagrantDir = jetpack.cwd configPath, ".vagrant"
  restorePath = null

  _r.fromPromise jetpack.findAsync vagrantDir.path(), {matching: ["./machines/*"]}, "inspect"
  .flatMap (folders) ->
    return _r.fromNodeCallback (cb) ->
      return cb new Error "can't maintain integrity with multiple machine folders" if folders.length > 1
      restorePath = jetpack.cwd(folders[0].absolutePath, "virtualbox", "id").path()
      cb null, folders[0].name
  .flatMap (machineName) -> # check that machine exists
    return _r.fromNodeCallback (cb) ->
      model.getMachine machineName, cb
  .flatMap (machine) ->
    return _r.fromNodeCallback (cb) ->
      model.restoreMachineId machine.UUID, restorePath, cb
  .onError callback
  .onValue ->
    return callback null, true

model.getMachine = (machineId, callback) ->
  result = {}

  _r.fromNodeCallback (cb) ->
    utilModel.runCmd 'VBoxManage showvminfo --machinereadable ' + machineId, null, null, cb
  .onError callback
  .onValue (resultString) ->
    for line in resultString.split("\n")
      val = line.split("=")
      result[val[0]] = if typeof val[1] == "string" then val[1].replace(/^"/g, '').replace(/"$/g, '') else null
    return callback null, result

model.checkMachineId = (machineId, callback) ->
  _r.fromNodeCallback (cb) -> model.getMachine machineId, cb
  .onError (err) -> # restore only on virtual box error
    return model.restoreFromMachineFolder callback if err?.message.match /^VBoxManage/
    return callback err
  .onValue ->
    return callback null, true

model.checkMachineIntegrity = (callback) ->
  return callback new Error "Invalid config path" if ! (configPath = utilModel.getConfigModulePath())

  vagrantDir = jetpack.cwd configPath, ".vagrant"

  # check that exactly one .vagrant/machines/*/virtualbox/id exists
  _r.fromPromise jetpack.findAsync vagrantDir.path(), {matching: ["./machines/*/virtualbox/id"]}
  .flatMap (files) ->
    return _r.fromNodeCallback (cb) ->
      return cb new Error "can't maintain integrity with multiple machine folders" if files.length > 1
      cb null, files.pop()
  .flatMap (idFile) -> # read if file exists
    return _r.constant null if ! idFile
    _r.fromPromise jetpack.readAsync idFile
  .flatMap (id) ->
    return _r.fromNodeCallback (cb) ->
      return model.checkMachineId id, cb if id # check that current id is actually in use ...
      model.restoreFromMachineFolder cb # ... otherwise restore
  .onError callback
  .onValue (val) ->
    return callback null, val

model.recreateMachineSshKeys = (callback) ->
  return callback new Error "Invalid config path" if ! (configPath = utilModel.getConfigModulePath())

  vagrantDir = jetpack.cwd configPath, ".vagrant"
  keys = model.generateKeyPair()

  _r.fromPromise jetpack.findAsync vagrantDir.path(), {matching: ["./machines/*/virtualbox"]}, "inspect"
  .flatMap (folders) ->
    return _r.fromNodeCallback (cb) ->
      return cb new Error "can't maintain integrity with multiple machine folders" if folders.length > 1
      cb null, folders[0]
  .flatMap (vagrantDir) -> # write private key file
    _r.fromNodeCallback (cb) ->
      utilModel.writeFile vagrantDir.absolutePath + "/private_key", keys.privateKey, cb
  .flatMap () -> # deploy public key to vm authorized_keys
    _r.fromNodeCallback (cb) ->
      model.deployVagrantAuthorizedKey keys.publicSSHKey, cb
  .onError callback
  .onValue ->
    callback null, true

#@todo 1024 or 2048? (cpu load...)
model.generateKeyPair = ->
  result = {}

  key = new NodeRSA({b:1024});
  result.privateKey = key.exportKey 'private'
  result.publicKey = key.exportKey 'pkcs8-public-pem'

  publicKey = forge.pki.publicKeyFromPem result.publicKey;
  result.publicSSHKey =  forge.ssh.publicKeyToOpenSSH publicKey, 'vagrant'
  result

model.deployVagrantAuthorizedKey = (publicSSHKey, callback) ->
  return callback new Error "Invalid public key" if ! publicSSHKey
  return callback new Error "Invalid config path" if ! (configPath = utilModel.getConfigModulePath())

  cmd = "vagrant ssh -c \"echo '" + publicSSHKey + "' >> /home/vagrant/.ssh/authorized_keys\""

  proc = terminalModel.createPTYStream cmd, {cwd: configPath}, (err, result) ->
    return callback err if err
    return callback null, true

  if proc.pty
    proc.stdout.on 'data', (val) ->
      if (val.match /(vagrant@(.*) password:)/ )
        terminalModel.writeIntoPTY 'vagrant'
  else # use stdin when not in pty mode
    proc.stdin.on 'data', (val) ->
      if (val.match /(vagrant@(.*) password:)/ )
        terminalModel.writeIntoPTY 'vagrant'

module.exports = model;
