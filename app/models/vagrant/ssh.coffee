_r = require 'kefir'

utilModel = require '../util/index.coffee'
rsaModel = require '../util/rsa.coffee'
terminalModel = require '../util/terminal.coffee'
vbModel = require './virtualbox.coffee'

model = {}

# reacts on password input and writes the default 'vagrant' password
model.deployPublicKeyStdInCallback = (val) ->
  if (val.match /(vagrant@(.*) password:)/ )
    terminalModel.writeIntoPTY 'vagrant'

# deploy ssh key pair to the vagrant machine
model.deployKeys = (privateKey, publicKey, callback) ->
  _r.fromNodeCallback (cb) ->
    model.deployPrivateKey privateKey, cb
  .flatMap ->
    _r.fromNodeCallback (cb) ->
      model.deployPublicKey publicKey, cb
  .onError callback
  .onValue ->
    callback null, true

# deploy private key as a file in the .vagrant/.. directory
model.deployPrivateKey = (privateKey, callback) ->
  return callback new Error 'invalid private key' if ! privateKey || typeof privateKey != "string"

  _r.fromNodeCallback (cb) ->
    vbModel.getOnlyVirtualBoxDir cb
  .flatMap (vagrantDir) ->
    _r.fromNodeCallback (cb) ->
      utilModel.writeFile vagrantDir.absolutePath + "/virtualbox/private_key", privateKey, cb
  .onError callback
  .onValue ->
    callback null, true

# create new ssh keys and deploy them afterwards
# the vm has to run while deploying
model.installNewKeys = (callback) ->
  _r.fromNodeCallback (cb) ->
    vbModel.getOnlyVirtualBoxDir cb
  .flatMap ->
    _r.fromNodeCallback (cb) ->
      rsaModel.createKeyPairForSSH 'vagrant', cb
  .flatMap (keys) ->
    _r.fromNodeCallback (cb) ->
      model.deployKeys keys.privateKey, keys.publicSSHKey, cb
  .onError callback
  .onValue ->
    callback null, true

# deploy public ssh key into vagrant machine ~/.ssh/authorized_keys
model.deployPublicKey = (publicSSHKey, callback) ->
  return callback new Error 'invalid public key' if ! publicSSHKey || typeof publicSSHKey != "string"
  return callback new Error 'invalid public key' if ! publicSSHKey.match(/^ssh-rsa/)
  return callback new Error "Invalid config path" if ! (configPath = utilModel.getConfigModulePath())

  cmd = "vagrant ssh -c \"echo '" + publicSSHKey + "' >> /home/vagrant/.ssh/authorized_keys\""

  proc = terminalModel.createPTYStream cmd, {cwd: configPath}, (err) ->
    return callback err if err
    return callback null, true

  stdIn = if proc.pty then proc.stdout else proc.stdin
  stdIn.on 'data', model.deployPublicKeyStdInCallback

module.exports = model;