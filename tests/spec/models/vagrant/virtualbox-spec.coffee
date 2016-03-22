'use strict';

rewire = require 'rewire'

model = null
samples =
  path: "/tmp/somehting/something/.vagrant/machines/eintopf"
  id: "123123-asdqw-3213-1234-32121"
  vmInfoRaw: "name=\"eintopf\"\ngroups=\"/\"\nostype=\"Ubuntu (64-bit)\"\nUUID=\"123123-asdqw-3213-1234-32121\""
  vmInfoRawWin: "name=\"eintopf\"\r\ngroups=\"/\"\r\nostype=\"Ubuntu (64-bit)\"\r\nUUID=\"123123-asdqw-3213-1234-32121\""
  vmInfoMapped:
    name: "eintopf"
    groups: "/"
    ostype: "Ubuntu (64-bit)"
    UUID: "123123-asdqw-3213-1234-32121"
  vmInfoMappedExt:
    name: "eintopf"
    groups: "/"
    ostype: "Ubuntu (64-bit)"
    UUID: "123123-asdqw-3213-1234-32121"
    absolutePath: "/tmp/somehting/something/.vagrant/machines/eintopf"
    idFilePath: "/tmp/somehting/something/.vagrant/machines/eintopf/virtualbox/id"
  virtualBoxError: "VBoxManage: error: Could not find a registered machine named 'eintop'\n......"

fromPromise = (value) ->
  return new Promise (resolve) -> resolve value

failFromPromise = (error) ->
  return new Promise (resolve, reject) -> reject new Error error

describe "checkAndRestoreMachineId", ->

  beforeEach ->
    model = rewire "../../../../models/vagrant/virtualbox.coffee"
    spyOn(model, 'restoreIdFromMachineFolder').andCallFake (callback) ->
      process.nextTick -> callback null, true
    spyOn(model, 'getMachine').andCallFake (machineId, callback) ->
      process.nextTick -> callback null, samples.vmInfoMapped

  it 'should return true in callback', (done) ->
    model.checkAndRestoreMachineId samples.id, (err, result) ->
      expect(result).toBeTruthy()
      done()

  it 'should fail when getMachine fails', (done) ->
    expected = new Error 'something went wrong'

    model.getMachine.andCallFake (machineId, callback) ->
      process.nextTick -> callback expected

    model.checkAndRestoreMachineId samples.id, (err) ->
      expect(err).toBe(expected)
      done()

  it 'should not call restoreIdFromMachineFolder on non virtualbox error', (done) ->
    model.getMachine.andCallFake (machineId, callback) ->
      process.nextTick -> callback new Error 'something went wrong'

    model.checkAndRestoreMachineId samples.id, ->
      expect(model.restoreIdFromMachineFolder.callCount).toBe(0)
      done()

  it 'should call restoreIdFromMachineFolder with own callback when err is a virtualbox error', (done) ->
    callback = ->
      expect(model.restoreIdFromMachineFolder).toHaveBeenCalledWith(callback)
      done()

    model.getMachine.andCallFake (machineId, callback) ->
      process.nextTick -> callback new Error samples.virtualBoxError

    model.checkAndRestoreMachineId samples.id, callback


describe "getMachine", ->

  beforeEach ->
    this.originalPlatform = process.platform;
    Object.defineProperty process, 'platform',
      value: 'MockOS'

    model = rewire "../../../../models/vagrant/virtualbox.coffee"
    model.__set__ 'utilModel',
      runCmd: jasmine.createSpy('runCmd').andCallFake (cmd, config, logName, logAction, callback) ->
        process.nextTick -> callback null, samples.vmInfoRaw

  afterEach ->
    Object.defineProperty process, 'platform',
      value: this.originalPlatform

  it 'should return object in callback', (done) ->
    model.getMachine samples.id, (err, result) ->
      expect(result).toEqual(jasmine.any(Object))
      done()

  it 'should run cmd only once', (done) ->
    model.getMachine samples.id, ->
      expect(model.__get__('utilModel').runCmd.callCount).toBe(1)
      done()

  it 'should fail when runCmd fails', (done) ->
    expected = new Error 'something went wrong'

    model.__get__('utilModel').runCmd.andCallFake (cmd, config, logName, logAction, callback) ->
      process.nextTick -> callback expected

    model.getMachine samples.id, (err) ->
      expect(err).toBe(expected)
      done()

  it 'should call runCmd only once when it fails on linux', (done) ->
    model.__get__('utilModel').runCmd.andCallFake (cmd, config, logName, logAction, callback) ->
      if cmd.match(/^"C:/)
        return process.nextTick -> callback new Error 'something went wrong'
      process.nextTick -> callback new Error 'sh: 1: VBoxManage: not found'

    model.getMachine samples.id, ->
      expect(model.__get__('utilModel').runCmd.callCount).toBe(1)
      done()

  it 'should call runCmd twice when first fails on windows', (done) ->
    Object.defineProperty process, 'platform',
      value: 'win32'

    model.__get__('utilModel').runCmd.andCallFake (cmd, config, logName, logAction, callback) ->
      if cmd.match(/^"C:/)
        return process.nextTick -> callback null, samples.vmInfoRaw
      process.nextTick -> callback new Error 'sh: 1: VBoxManage: not found'

    model.getMachine samples.id, ->
      expect(model.__get__('utilModel').runCmd.callCount).toBe(2)
      done()

  it 'should call runCmd with fixed vbox manage after first fail on windows', (done) ->
    Object.defineProperty process, 'platform',
      value: 'win32'

    model.__get__('utilModel').runCmd.andCallFake (cmd, config, logName, logAction, callback) ->
      process.nextTick -> callback new Error 'sh: 1: VBoxManage: not found'

    model.getMachine samples.id, ->
      expect(model.__get__('utilModel.runCmd').argsForCall[1][0]).toContain('C:\\Program Files\\Oracle\\VirtualBox\\VBoxManage.exe')
      done()

  it 'should return empty object when runCmd returns nothing', (done) ->
    model.__get__('utilModel').runCmd.andCallFake (cmd, config, logName, logAction, callback) ->
      process.nextTick -> callback null, null

    model.getMachine samples.id, (err, result) ->
      expect(result).toEqual({})
      done()

  it 'should map cmd result into correct properties', (done) ->
    model.getMachine samples.id, (err, result) ->
      expect(result).toEqual(samples.vmInfoMapped)
      done()

  it 'should map windows cmd result into correct properties', (done) ->
    model.__get__('utilModel').runCmd.andCallFake (cmd, config, logName, logAction, callback) ->
      process.nextTick -> callback null, samples.vmInfoRawWin

    model.getMachine samples.id, (err, result) ->
      expect(result).toEqual(samples.vmInfoMapped)
      done()


describe "getMachineFromMachineFolder", ->

  beforeEach ->
    model = rewire "../../../../models/vagrant/virtualbox.coffee"
    spyOn(model, 'getMachine').andCallFake (machineId, callback) ->
      process.nextTick -> callback null, samples.vmInfoMapped
    spyOn(model, 'getOnlyVirtualBoxDir').andCallFake (callback) ->
      process.nextTick -> callback null, {absolutePath: samples.path, name: samples.vmInfoMapped.name }

  afterEach -> # cleanup when properties were changed
    delete samples.vmInfoMapped.absolutePath if samples.vmInfoMapped.absolutePath
    delete samples.vmInfoMapped.idFilePath if samples.vmInfoMapped.idFilePath

  it 'should return object in callback', (done) ->
    model.getMachineFromMachineFolder (err, result) ->
      expect(result).toEqual(jasmine.any(Object))
      done()

  it 'should fail when getOnlyVirtualBoxDir fails', (done) ->
    expected = new Error 'some random error'

    model.getOnlyVirtualBoxDir.andCallFake (callback) ->
      process.nextTick -> callback expected

    model.getMachineFromMachineFolder (err) ->
      expect(err).toBe(expected)
      done()

  it 'should fail when getMachine fails', (done) ->
    expected = new Error 'some random error'

    model.getMachine.andCallFake (machineId, callback) ->
      process.nextTick -> callback expected

    model.getMachineFromMachineFolder (err) ->
      expect(err).toBe(expected)
      done()

  it 'should call getMachine with with correct parameter', (done) ->
    model.getMachineFromMachineFolder ->
      expect(model.getMachine).toHaveBeenCalledWith(samples.vmInfoMapped.name, jasmine.any(Function))
      done()

  it 'should add additional properties', (done) ->
    model.getMachineFromMachineFolder (err, result) ->
      expect(result).toEqual(samples.vmInfoMappedExt)
      done()


describe "getOnlyVirtualBoxDir", ->

  beforeEach ->
    jetpackMock =
      cwd: jasmine.createSpy('cwd').andCallFake -> jetpackMock
      path: jasmine.createSpy('cwd').andCallFake -> samples.path
      findAsync: jasmine.createSpy('findAsync').andCallFake -> fromPromise [{absolutePath: samples.path}]

    model = rewire "../../../../models/vagrant/virtualbox.coffee"
    model.__set__ 'utilModel',
      getConfigModulePath: jasmine.createSpy('getConfigModulePath').andCallFake () -> samples.path
    model.__set__ 'jetpack', jetpackMock

  it 'should return only dir object with correct absolutePath property callback', (done) ->
    model.getOnlyVirtualBoxDir (err, result) ->
      expect(result).toEqual({absolutePath: samples.path})
      done()

  it 'should fail when getConfigModulePath returns nothing', (done) ->
    model.__get__('utilModel').getConfigModulePath.andCallFake -> null

    model.getOnlyVirtualBoxDir (err) ->
      expect(err).toBeTruthy()
      done()

  it 'should fail when findAsync fails', (done) ->
    model.__get__('jetpack.findAsync').andCallFake -> return failFromPromise new Error "something went wrong"

    model.getOnlyVirtualBoxDir (err) ->
      expect(err).toBeTruthy()
      done()

  it 'should fail when findAsync returns empty array', (done) ->
    model.__get__('jetpack.findAsync').andCallFake -> return fromPromise []

    model.getOnlyVirtualBoxDir (err) ->
      expect(err).toBeTruthy()
      done()

  it 'should fail when findAsync returns more than one result', (done) ->
    model.__get__('jetpack.findAsync').andCallFake -> return fromPromise [{absolutePath: samples.path}, {absolutePath: samples.path}]

    model.getOnlyVirtualBoxDir (err) ->
      expect(err).toBeTruthy()
      done()

  it 'should call findAsync with correct parameters', (done) ->
    model.getOnlyVirtualBoxDir ->
      expect(model.__get__ 'jetpack.findAsync').toHaveBeenCalledWith(samples.path, {matching: ["./.vagrant/machines/*"]}, "inspect")
      done()

describe "restoreIdFromMachineFolder", ->

  beforeEach ->
    model = rewire "../../../../models/vagrant/virtualbox.coffee"
    model.__set__ 'utilModel',
      writeFile: jasmine.createSpy('writeFile').andCallFake (path, content, callback) ->
        process.nextTick -> callback null, true
    spyOn(model, 'getMachineFromMachineFolder').andCallFake (callback) ->
      process.nextTick -> callback null, samples.vmInfoMappedExt

  it 'should return true in callback', (done) ->
    model.restoreIdFromMachineFolder (err, result) ->
      expect(result).toBeTruthy()
      done()

  it 'should fail when getMachineFromMachineFolder fails', (done) ->
    expected = new Error 'something went totally wrong this time'

    model.getMachineFromMachineFolder.andCallFake (callback) ->
      process.nextTick -> callback expected

    model.restoreIdFromMachineFolder (err) ->
      expect(err).toBe(expected)
      done()

  it 'should fail when writeFile fails', (done) ->
    expected = new Error 'something went totally wrong this time'

    model.__get__('utilModel.writeFile').andCallFake (path, content, callback) ->
        process.nextTick -> callback expected

    model.restoreIdFromMachineFolder (err) ->
      expect(err).toBe(expected)
      done()

  it 'should fail when machine does not have the idFilePath property', (done) ->
    model.getMachineFromMachineFolder.andCallFake (callback) ->
      process.nextTick -> callback null, samples.vmInfoMapped

    model.restoreIdFromMachineFolder (err) ->
      expect(err).toBeTruthy()
      done()

  it 'should call writeFile with correct parameters', (done) ->
    model.restoreIdFromMachineFolder ->
      expect(model.__get__('utilModel').writeFile)
      .toHaveBeenCalledWith(samples.vmInfoMappedExt.absolutePath + "/virtualbox/id",
        samples.vmInfoMappedExt.UUID, jasmine.any(Function))
      done()


describe "checkMachineConsistency", ->

  beforeEach ->
    jetpackMock =
      cwd: jasmine.createSpy('cwd').andCallFake -> jetpackMock
      path: jasmine.createSpy('cwd').andCallFake -> samples.vmInfoMappedExt.idFilePath
      readAsync: jasmine.createSpy('readAsync').andCallFake -> fromPromise samples.vmInfoMappedExt.UUID

    model = rewire "../../../../models/vagrant/virtualbox.coffee"
    spyOn(model, 'getOnlyVirtualBoxDir').andCallFake (callback) ->
      process.nextTick -> callback null, {absolutePath: samples.path, name: samples.vmInfoMapped.name }
    spyOn(model, 'checkAndRestoreMachineId').andCallFake (id, callback) ->
      process.nextTick -> callback null, true
    spyOn(model, 'restoreIdFromMachineFolder').andCallFake (callback) ->
      process.nextTick -> callback null, true
    model.__set__ 'jetpack', jetpackMock

  it 'should return true in callback', (done) ->
    model.checkMachineConsistency (err, result) ->
      expect(result).toBeTruthy()
      done()

  it 'should fail when getOnlyVirtualBoxDir fails', (done) ->
    expected = new Error 'some random error'

    model.getOnlyVirtualBoxDir.andCallFake (callback) ->
      process.nextTick -> callback expected

    model.checkMachineConsistency (err) ->
      expect(err).toBe(expected)
      done()

  it 'should fail when readAsync fails', (done) ->
    model.__get__('jetpack.readAsync').andCallFake -> return failFromPromise new Error "something went wrong"

    model.checkMachineConsistency (err) ->
      expect(err).toBeTruthy()
      done()

#@todo for some reason the mock of checkAndRestoreMachineId is not used here
#  it 'should call checkAndRestoreMachineId with correct parameters if id exists', ->
#    model.checkMachineConsistency ->
#      expect(model.checkAndRestoreMachineId).toHaveBeenCalledWith(samples.vmInfoMappedExt.UUID, jasmine.any(Function))
#      done()

  it 'should call restoreIdFromMachineFolder with correct parameters if no id', ->
    model.__get__('jetpack.readAsync').andCallFake -> return fromPromise null

    model.checkMachineConsistency ->
      expect(model.restoreIdFromMachineFolder).toHaveBeenCalledWith()
      done()

#@todo test is somehow not persistent it stops randomly....
#  it 'should call readAsync with with correct parameter', (done) ->
#    model.checkMachineConsistency ->
#      expect(model.__get__('jetpack.readAsync')).toHaveBeenCalledWith(samples.vmInfoMappedExt.idFilePath)
#      done()

