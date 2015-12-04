'use strict';

rewire = require 'rewire'

model = null
samples =
  publicKey: '----\nrandomPublicKey\n----'
  privateKey: '----\nrandomPrivateKey\n----'
  publicSSHKey: 'ssh-rsa randomPublicSSHKey test'
  faultyPublicSSHKey: 'randomPublicSSHKey test'
  stdInPass: 'vagrant@127.0.0.1 password:'
  absolutePath: '/tmp/rnd/path'
  configPath: '/tmp/rnd/config/path'


describe "getSSHConfig", ->

  machineMock =
    sshConfig: jasmine.createSpy('getVagrantMachine').andCallFake (callback) ->
      callback null, {}

  beforeEach ->
    model = rewire "../../../../models/vagrant/ssh.coffee"
    model.__set__ 'vagrantModel',
      getVagrantMachine: jasmine.createSpy('getVagrantMachine').andCallFake ->
        machineMock

  it 'should call vagrantModel.getVagrantMachine without parameters', (done) ->
    model.getSSHConfig ->
      expect(model.__get__('vagrantModel').getVagrantMachine).toHaveBeenCalledWith()
      done()

  it 'should call machine.sshConfig with callback', (done) ->
    model.getSSHConfig ->
      expect(machineMock.sshConfig).toHaveBeenCalledWith(jasmine.any(Function))
      done()

  it 'should call machine.sshConfig with own callback', (done) ->
    callback = ->
      expect(machineMock.sshConfig).toHaveBeenCalledWith(callback)
      done()

    model.getSSHConfig callback

  it 'should fail without machine', (done) ->
    model.__get__('vagrantModel').getVagrantMachine.andCallFake -> null

    model.getSSHConfig (err) ->
      expect(err).toBeTruthy()
      done()

describe "deployPublicKeyStdInCallback", ->

  beforeEach ->
    model = rewire "../../../../models/vagrant/ssh.coffee"
    model.__set__ 'terminalModel',
      writeIntoPTY: jasmine.createSpy('writeIntoPTY').andCallFake ->

  it 'should call terminalModel.writeIntoPTY with vagrant', ->
    model.deployPublicKeyStdInCallback samples.stdInPass

    expect(model.__get__('terminalModel').writeIntoPTY).toHaveBeenCalledWith('vagrant')

  it 'should not call terminalModel.writeIntoPTY', ->
    model.deployPublicKeyStdInCallback 'rndInput'
    model.deployPublicKeyStdInCallback 'another input'
    model.deployPublicKeyStdInCallback 'and even more input'

    expect(model.__get__('terminalModel').writeIntoPTY.callCount).toBe(0)


describe "deployKeys", ->

  beforeEach ->
    model = rewire "../../../../models/vagrant/ssh.coffee"
    spyOn(model, 'deployPrivateKey').andCallFake (privateKey, callback) ->
      process.nextTick -> callback null, true # be async
    spyOn(model, 'deployPublicKey').andCallFake (publicKey, callback) ->
      process.nextTick -> callback null, true

  it 'should call callback with result true', (done) ->
    model.deployKeys samples.privateKey, samples.publicKey, (err, result) ->
      expect(result).toBeTruthy()
      done()

  it 'should call deployPublicKey ', (done) ->
    model.deployKeys samples.privateKey, samples.publicKey, ->
      expect(model.deployPublicKey).toHaveBeenCalledWith(samples.publicKey, jasmine.any(Function))
      done()

  it 'should call deployPublicKey ', (done) ->
    model.deployKeys samples.privateKey, samples.publicKey, ->
      expect(model.deployPrivateKey).toHaveBeenCalledWith(samples.privateKey, jasmine.any(Function))
      done()

  it 'should fail with deployPrivateKey', (done) ->
    expected = new Error 'something went wrong'

    model.deployPrivateKey.andCallFake (privateKey, callback) ->
      callback expected

    model.deployKeys samples.privateKey, samples.publicKey, (err) ->
      expect(err).toBe(expected)
      done()

  it 'should not call deployPublicKey on deployPrivateKey failure', (done) ->
    model.deployPrivateKey.andCallFake (privateKey, callback) ->
      callback new Error 'something went wrong'

    model.deployKeys samples.privateKey, samples.publicKey, ->
      expect(model.deployPublicKey.callCount).toBe(0)
      done()

  it 'should fail with deployPublicKey', (done) ->
    expected = new Error 'something went wrong'

    model.deployPublicKey.andCallFake (privateKey, callback) ->
      callback expected

    model.deployKeys samples.privateKey, samples.publicKey, (err) ->
      expect(err).toBe(expected)
      done()

describe "deployPrivateKey", ->

  beforeEach ->
    model = rewire "../../../../models/vagrant/ssh.coffee"
    model.__set__ 'vagrantModel',
      getOnlyVirtualBoxDir: jasmine.createSpy('getOnlyVirtualBoxDir').andCallFake (callback) ->
        process.nextTick -> callback null, absolutePath: samples.absolutePath
    model.__set__ 'utilModel',
      writeFile: jasmine.createSpy('writeFile').andCallFake (path, content, callback) ->
        process.nextTick -> callback null, true

  it 'should return true in callback', (done) ->
    model.deployPrivateKey samples.privateKey, (err, result) ->
      expect(result).toBeTruthy()
      done()

  it 'should fail when private key is empty', (done) ->
    model.deployPrivateKey '', (err) ->
      expect(err).toBeTruthy()
      done()

  it 'should fail when private key is not string', (done) ->
    model.deployPrivateKey {}, (err) ->
      expect(err).toBeTruthy()
      done()

  it 'should fail when getOnlyVirtualBoxDir fails', (done) ->
    expected = new Error 'something went wrong'

    model.__get__('vagrantModel').getOnlyVirtualBoxDir.andCallFake (callback) ->
      process.nextTick -> callback expected

    model.deployPrivateKey samples.privateKey, (err) ->
      expect(err).toBe(expected)
      done()

  it 'should fail when writeFile fails', (done) ->
    expected = new Error 'something went wrong'

    model.__get__('utilModel').writeFile.andCallFake (path, content, callback) ->
      process.nextTick -> callback expected

    model.deployPrivateKey samples.privateKey, (err) ->
      expect(err).toBe(expected)
      done()

  it 'should call getOnlyVirtualBoxDir with callback', (done) ->
    model.deployPrivateKey samples.privateKey, ->
      expect(model.__get__('vagrantModel').getOnlyVirtualBoxDir).toHaveBeenCalledWith(jasmine.any(Function))
      done()

  it 'should call writeFile with correct params', (done) ->
    expectedPath = samples.absolutePath + "/private_key"

    model.deployPrivateKey samples.privateKey, ->
      expect(model.__get__('utilModel').writeFile).toHaveBeenCalledWith(expectedPath, samples.privateKey, jasmine.any(Function))
      done()


describe "installNewKeys", ->

  beforeEach ->
    model = rewire "../../../../models/vagrant/ssh.coffee"
    model.__set__ 'vagrantModel',
      getOnlyVirtualBoxDir: jasmine.createSpy('getOnlyVirtualBoxDir').andCallFake (callback) ->
        process.nextTick -> callback null, absolutePath: samples.absolutePath
    model.__set__ 'rsaModel',
      createKeyPairForSSH: jasmine.createSpy('createKeyPairForSSH').andCallFake (label, callback) ->
        process.nextTick -> callback null, {privateKey: samples.privateKey, publicKey: samples.publicKey, publicSSHKey: samples.publicSSHKey}
    spyOn(model, 'deployKeys').andCallFake (privateKey, publicKey, callback) ->
      callback null, true

  it 'should return true in callback', (done) ->
    model.installNewKeys (err, result) ->
      expect(result).toBeTruthy()
      done()

  it 'should fail on getOnlyVirtualBoxDir', (done) ->
    expected = new Error 'something went wrong'

    model.__get__('vagrantModel').getOnlyVirtualBoxDir.andCallFake (callback) ->
      process.nextTick -> callback expected

    model.installNewKeys (err) ->
      expect(err).toBe(expected)
      done()

  it 'should fail on createKeyPairForSSH', (done) ->
    expected = new Error 'something went wrong'

    model.__get__('rsaModel').createKeyPairForSSH.andCallFake (label, callback) ->
      process.nextTick -> callback expected

    model.installNewKeys (err) ->
      expect(err).toBe(expected)
      done()

  it 'should fail on deployKeys', (done) ->
    expected = new Error 'something went wrong'

    model.deployKeys.andCallFake (privateKey, publicKey, callback) ->
      process.nextTick -> callback expected

    model.installNewKeys (err) ->
      expect(err).toBe(expected)
      done()

  it 'should call getOnlyVirtualBoxDir with callback', (done) ->
    model.installNewKeys ->
      expect(model.__get__('vagrantModel').getOnlyVirtualBoxDir).toHaveBeenCalledWith(jasmine.any(Function))
      done()

  it 'should call getOnlyVirtualBoxDir with callback', (done) ->
    model.installNewKeys ->
      expect(model.__get__('rsaModel').createKeyPairForSSH).toHaveBeenCalledWith('vagrant', jasmine.any(Function))
      done()

  it 'should call getOnlyVirtualBoxDir with callback', (done) ->
    model.installNewKeys ->
      expect(model.deployKeys).toHaveBeenCalledWith(samples.privateKey, samples.publicSSHKey, jasmine.any(Function))
      done()


describe "deployPublicKey", ->

  ptyMock =
    pty: true
    stdout:
      on: jasmine.createSpy('stdout.on').andCallFake ->
    stdin:
      on: jasmine.createSpy('stdin.on').andCallFake ->

  beforeEach ->
    model = rewire "../../../../models/vagrant/ssh.coffee"
    model.__set__ 'utilModel',
      getConfigModulePath: jasmine.createSpy('getConfigModulePath').andCallFake -> samples.configPath
    model.__set__ 'terminalModel',
      createPTYStream: jasmine.createSpy('createPTYStream').andCallFake (cmd, options, callback) ->
        process.nextTick -> callback null, true
        ptyMock

    spyOn(model, 'deployPublicKeyStdInCallback').andCallFake ->

  it 'should return true in callback', (done) ->
    model.deployPublicKey samples.publicSSHKey, (err, result) ->
      expect(result).toBeTruthy()
      done()

  it 'should fail when public ssh key is empty', (done) ->
    model.deployPublicKey '', (err) ->
      expect(err).toBeTruthy()
      done()

  it 'should fail when public ssh key is not string', (done) ->
    model.deployPublicKey {}, (err) ->
      expect(err).toBeTruthy()
      done()

  it 'should fail when public ssh key does not start with ssh-rsa', (done) ->
    model.deployPublicKey samples.faultyPublicSSHKey, (err) ->
      expect(err).toBeTruthy()
      done()

  it 'should fail when getConfigModulePath returns nothing', (done) ->
    model.__get__('utilModel').getConfigModulePath.andCallFake -> null

    model.deployPublicKey samples.publicSSHKey, (err) ->
      expect(err).toBeTruthy()
      done()

  it 'should call createPTYStream with correct parameters', (done) ->
    model.deployPublicKey samples.publicSSHKey, ->
      expect(model.__get__('terminalModel').createPTYStream.argsForCall[0][0]).toContain(samples.publicSSHKey)
      done()

  it 'should call deployPublicKeyStdInCallback on data event of stdout when pty is true', (done) ->
    model.__set__ 'terminalModel',
      createPTYStream: jasmine.createSpy('createPTYStream').andCallFake (cmd, options, callback) ->
        setTimeout ->
          ptyMock.stdout.on 'data', () ->
          callback null, true
        , 10
        ptyMock

    model.deployPublicKey samples.publicSSHKey, ->
      expect(ptyMock.stdout.on).toHaveBeenCalled()
      done()

  it 'should call deployPublicKeyStdInCallback on data event of stdin when pty is false', (done) ->
    model.__set__ 'terminalModel',
      createPTYStream: jasmine.createSpy('createPTYStream').andCallFake (cmd, options, callback) ->
        setTimeout ->
          ptyMock.stdin.on 'data', () ->
          callback null, true
        , 10
        ptyMock

    model.deployPublicKey samples.publicSSHKey, ->
      expect(ptyMock.stdin.on).toHaveBeenCalled()
      done()
