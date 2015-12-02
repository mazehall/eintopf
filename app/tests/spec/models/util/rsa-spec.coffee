'use strict';

rewire = require 'rewire'

model = null
samples = {
  rndPublicKey: '----\nrandomPublicKey\n----',
  rndPrivateKey: '----\nrandomPrivateKey\n----',
  rndPublicSSHKey: 'ssh-rsa randomPublicSSHKey test',
  forgeResult: ['something'],
  label: 'testing'
}

describe "createKeyPair", ->

  beforeEach ->
    model = rewire "../../../../models/util/rsa.coffee"
    model.__set__ 'NodeRSA', jasmine.createSpy('NodeRSA').andCallFake ->
      return {
        exportKey: (format) ->
          return samples.rndPublicKey if format == 'public'
          return samples.rndPrivateKey if format == 'private'
      }

  it 'should only return private and public pem', (done) ->
    expected = {
      privateKey: samples.rndPrivateKey
      publicKey: samples.rndPublicKey
    }

    model.createKeyPair (err, keys) ->
      expect(keys).toEqual(expected)
      done()

  it 'should call NodeRSA with 1024 bits option', (done)->
    model.createKeyPair ->
      expect(model.__get__ 'NodeRSA').toHaveBeenCalledWith({b:1024})
      done()

describe "publicKeyPemToPublicSSH" , ->

  beforeEach ->
    model = rewire "../../../../models/util/rsa.coffee"
    model.__set__ 'forge',
      pki:
        publicKeyFromPem: jasmine.createSpy('forge.pki.publicKeyFromPem').andCallFake ->
          samples.forgeResult
      ssh:
        publicKeyToOpenSSH: jasmine.createSpy('forge.ssh.publicKeyToOpenSSH').andCallFake ->
          samples.rndPublicSSHKey

  it 'should return public ssh key', (done) ->
    model.publicKeyPemToPublicSSH samples.rndPublicKey, samples.label, (err, key) ->
      expect(key).toBe(samples.rndPublicSSHKey)
      done()

  it 'should call forge.pki.publicKeyFromPem with the public key', (done) ->
    model.publicKeyPemToPublicSSH samples.rndPublicKey, samples.label, ->
      expect(model.__get__('forge').pki.publicKeyFromPem).toHaveBeenCalledWith(samples.rndPublicKey)
      done()

  it 'should call forge.ssh.publicKeyToOpenSSH with forged key and label', (done) ->
    model.publicKeyPemToPublicSSH samples.rndPublicKey, samples.label, ->
      expect(model.__get__('forge').ssh.publicKeyToOpenSSH).toHaveBeenCalledWith(samples.forgeResult, samples.label)
      done()

describe "createKeyPairForSSH" , ->

  beforeEach ->
    model = rewire "../../../../models/util/rsa.coffee"
    spyOn(model, 'createKeyPair').andCallFake (callback) ->
      callback null,
        privateKey: samples.rndPrivateKey,
        publicKey: samples.rndPublicKey
    spyOn(model, 'publicKeyPemToPublicSSH').andCallFake (publicKey, label, callback) ->
      callback null,
        samples.rndPublicSSHKey

  it 'should return private, public and public ssh keys', (done) ->
    expected = {
      privateKey: samples.rndPrivateKey,
      publicKey: samples.rndPublicKey,
      publicSSHKey: samples.rndPublicSSHKey
    }

    model.createKeyPairForSSH samples.label, (err, keys) ->
      expect(keys).toEqual(expected)
      done()

  it 'should call createKeyPair with a callback', (done) ->
    model.createKeyPairForSSH samples.label, ->
      expect(model.createKeyPair).toHaveBeenCalledWith(jasmine.any(Function))
      done()

  it 'should call publicKeyPemToPublicSSH with correct parameters', (done) ->
    model.createKeyPairForSSH samples.label, ->
      expect(model.publicKeyPemToPublicSSH).toHaveBeenCalledWith(samples.rndPublicKey, samples.label,jasmine.any(Function))
      done()

  it 'should fail on createKeyPair error', (done) ->
    expected = new Error 'something went wrong'

    model.createKeyPair.andCallFake (callback) -> callback expected

    model.createKeyPairForSSH samples.label, (err) ->
      expect(err).toBe(expected)
      done()

  it 'should fail on publicKeyPemToPublicSSH error', (done) ->
    expected = new Error 'something went wrong'

    model.publicKeyPemToPublicSSH.andCallFake (publicKey, label, callback) -> callback expected

    model.createKeyPairForSSH samples.label, (err) ->
      expect(err).toBe(expected)
      done()