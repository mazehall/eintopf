NodeRSA = require 'node-rsa'
forge = require 'node-forge'

model = {}
model.createKeyPair = (callback) ->

  process.nextTick ->
    key = new NodeRSA({b:1024});

    result = {}
    result.privateKey = key.exportKey 'private'
    result.publicKey = key.exportKey 'public'

    callback null, result

model.createKeyPairForSSH = (label, callback) ->
  model.createKeyPair (err, keys) ->
    return callback err if err

    model.publicKeyPemToPublicSSH keys.publicKey, label, (err, publicSshKey) ->
      return callback err if err
      keys.publicSSHKey = publicSshKey

      callback null, keys

model.publicKeyPemToPublicSSH = (publicKey, label, callback) ->
  process.nextTick ->
    forgedKey = forge.pki.publicKeyFromPem publicKey
    publicSSHKey = forge.ssh.publicKeyToOpenSSH forgedKey, label

    callback null, publicSSHKey

module.exports = model