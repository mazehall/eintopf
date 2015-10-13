'use strict';

rewire = require 'rewire'


fromPromise = (value) ->
  return new Promise (resolve) -> resolve value

failFromPromise = (error) ->
  return new Promise (resolve, reject) -> reject new Error error

describe "check backup", ->

  model = null
  beforeEach ->
    model = rewire "../../../../models/vagrant/backup.coffee"
    model.match = ["id", "index_uuid"]
    model.__set__ "utilModel.getConfigModulePath", -> return "/tmp/eintopf/default"
    model.__set__ "model.createBackup", (backupPath, restorePath, callback) -> return callback null, true
    model.__set__ "model.restoreBackup", (backupPath, restorePath, callback) -> return callback null, true

  it 'should fail without config module path', (done)->
    model.__set__ "utilModel.getConfigModulePath", -> return null

    model.checkBackup (err, result) ->
      expect(err.message).toBe("backup failed: invalid config path");
      done()

  it 'should not call create or restore backup when config path failure', (done)->
    model.__set__ "utilModel.getConfigModulePath", -> return null

    spyOn model, "restoreBackup"
    spyOn model, "createBackup"

    model.checkBackup () ->
      expect(model.restoreBackup.wasCalled).toBeFalsy();
      expect(model.createBackup.wasCalled).toBeFalsy();
      done()

  it 'should only call restore backup with params when no vagrant files found', (done)->
    model.__set__ "jetpack.findAsync", () -> return fromPromise []

    spyOn(model, "restoreBackup").andCallThrough()
    spyOn(model, "createBackup").andCallThrough()

    model.checkBackup (err, result) ->
      expect(model.restoreBackup).toHaveBeenCalledWith("/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", jasmine.any(Function))
      expect(model.createBackup.wasCalled).toBeFalsy();
      done()

  it 'should call jetpack.findAsync with parameter', (done) ->
    path = "/tmp/eintopf/default/.vagrant"
    model.__set__ "jetpack.findAsync", jasmine.createSpy('findAsync').andCallFake () -> return fromPromise ["one", "two"]

    model.checkBackup (err, result) ->
      expect(model.__get__ "jetpack.findAsync").toHaveBeenCalledWith(path, jasmine.any(Object), "inspect")
      done()

  it 'should fail when jetpack.findAsync fails', (done) ->
    path = "/tmp/eintopf/default/.vagrant"
    model.__set__ "jetpack.findAsync", jasmine.createSpy('findAsync').andCallFake () -> return failFromPromise "promise failure"

    model.checkBackup (err, result) ->
      expect(err.message).toBe("promise failure")
      done()

  it 'should only call restore backup when vagrant files do not match', (done)->
    model.__set__ "jetpack.findAsync", () -> return fromPromise ["one"]

    spyOn(model, "restoreBackup").andCallThrough()
    spyOn(model, "createBackup").andCallThrough()

    model.checkBackup (err, result) ->
      expect(model.restoreBackup).toHaveBeenCalled()
      expect(model.createBackup.wasCalled).toBeFalsy();
      done()

  it 'should only call create backup with params when vagrant files match', (done)->
    model.__set__ "jetpack.findAsync", () -> return fromPromise ["one", "two"]

    spyOn(model, "restoreBackup").andCallThrough()
    spyOn(model, "createBackup").andCallThrough()

    model.checkBackup (err, result) ->
      expect(model.createBackup).toHaveBeenCalledWith("/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", jasmine.any(Function))
      expect(model.restoreBackup.wasCalled).toBeFalsy();
      done()

  it 'should return error when create backup failed', (done)->
    model.__set__ "jetpack.findAsync", () -> return fromPromise ["one", "two"]

    spyOn(model, "createBackup").andCallFake (backupPath, restorePath, callback) ->
      callback new Error 'just a test'

    model.checkBackup (err, result) ->
      expect(model.createBackup).toHaveBeenCalled()
      expect(err).toBeTruthy()
      done()

  it 'should return error when restore backup failed', (done)->
    model.__set__ "jetpack.findAsync", () -> return fromPromise []

    spyOn(model, "restoreBackup").andCallFake (backupPath, restorePath, callback) ->
      callback new Error 'just a test'

    model.checkBackup (err, result) ->
      expect(model.restoreBackup).toHaveBeenCalled()
      expect(err).toBeTruthy()
      done()

  it 'should return true when create backup succeeded', (done)->
    model.__set__ "jetpack.findAsync", () -> return fromPromise ["one", "two"]

    spyOn(model, "createBackup").andCallFake (backupPath, restorePath, callback) ->
      callback null, true

    model.checkBackup (err, result) ->
      expect(model.createBackup).toHaveBeenCalled()
      expect(err).toBeFalsy()
      expect(result).toBeTruthy()
      done()

  it 'should return true when restore backup succeeded', (done)->
    model.__set__ "jetpack.findAsync", () -> return fromPromise []

    spyOn(model, "restoreBackup").andCallFake (backupPath, restorePath, callback) ->
      callback null, true

    model.checkBackup (err, result) ->
      expect(model.restoreBackup).toHaveBeenCalled()
      expect(err).toBeFalsy()
      expect(result).toBeTruthy()
      done()

describe "create Backup", ->

  model = null
  beforeEach ->
    model = rewire "../../../../models/vagrant/backup.coffee"
    model.match = ["id", "index_uuid"]
    model.__set__ "utilModel.getConfigModulePath", -> return "/tmp/eintopf/default"
    model.__set__ "asar.createPackage", (restorePath, backupPath, callback) -> return callback null, true

  it 'should fail without a path parameter', (done) ->
    model.createBackup null, 'test', (err) ->
      expect(err.message).toBe("Invalid paths given to create backup");
      done()

  it 'should call asar.createPackage with parameters', (done) ->
    model.__set__ "asar.createPackage", jasmine.createSpy('removeAsync').andCallFake (restorePath, backupPath, callback) -> return callback null, true

    model.createBackup "/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", (err, result) ->
      expect(model.__get__ "asar.createPackage").toHaveBeenCalledWith("/tmp/eintopf/default/.vagrant", "/tmp/eintopf/default/.vagrant.backup", jasmine.any(Function));
      done()

  it 'should return true after creating the package', (done) ->
    model.createBackup "/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", (err, result) ->
      expect(err).toBeFalsy()
      expect(result).toBeTruthy()
      done()

describe "restore backup", ->

  model = null
  beforeEach ->
    model = rewire "../../../../models/vagrant/backup.coffee"
    model.match = ["id", "index_uuid"]/
    model.__set__ "utilModel.getConfigModulePath", -> return "/tmp/eintopf/default"
    model.__set__ "jetpack.exists", (backupPath) -> return true
    model.__set__ "utilModel.removeFileAsync", (backupPath, callback) -> return callback null, true
    model.__set__ "asar.extractAll", (backupPath, restorePath) -> return true
    model.__set__ "asar.listPackage", (backupPath) ->
      return ["/machines/eintopf/virtualbox/id", "/machines/eintopf/virtualbox/index_uuid"]

  it 'should fail without a path parameter', (done) ->
    model.restoreBackup null, null, (err, result) ->
      expect(err.message).toBe("Invalid paths given to restore backup")
      done()

  it 'should fail without an existing backup file', (done) ->
    model.__set__ "jetpack.exists", (backupPath) -> return false

    model.restoreBackup "/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", (err, result) ->
      expect(err.message).toBe("Restoring backup failed due to missing Backup")
      done()

  it 'should only call remove backup with parameters when filtered vagrant files are empty', (done) ->
    model.__set__ "asar.listPackage", jasmine.createSpy('listPackage').andCallFake (backupPath) ->
      return []
    model.__set__ "asar.extractAll", jasmine.createSpy('extractAll').andCallThrough()
    model.__set__ "utilModel.removeFileAsync", jasmine.createSpy('removeFileAsync').andCallFake (backupPath, callback) -> return callback null, true

    model.restoreBackup "/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", (err, result) ->
      expect(model.__get__("utilModel.removeFileAsync")).toHaveBeenCalledWith("/tmp/eintopf/default/.vagrant.backup", jasmine.any(Function))
      expect(model.__get__("asar.extractAll").wasCalled).toBeFalsy();
      done()

  it 'should only call remove backup when uuid is not registered', (done) ->
    model.__set__ "utilModel.machineIdRegistered", createSpy().andCallFake (uuid, callback) -> callback true
    model.__set__ "utilModel.removeFileAsync", createSpy().andCallFake (backup, callback) -> callback null, true
    model.__set__ "asar.extractFile", -> "uuid#00000"
    model.__set__ "asar.extractAll", createSpy().andCallThrough()

    model.restoreBackup "/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", ->
      expect(model.__get__("utilModel.machineIdRegistered")).toHaveBeenCalled()
      expect(model.__get__("utilModel.removeFileAsync")).toHaveBeenCalledWith "/tmp/eintopf/default/.vagrant.backup", any Function
      expect(model.__get__("asar.extractAll").wasCalled).toBeFalsy()
      done()

  it 'should return static error after removing the backup', (done) ->
    model.__set__ "asar.listPackage", jasmine.createSpy('listPackage').andCallFake (backupPath) -> return []

    model.restoreBackup "/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", (err, result) ->
      expect(err.message).toBe("Restore backup failed due to faulty backup");
      done()

  it 'should call only asar.extractAll with parameters when vagrant files match all', (done) ->
    model.__set__ "asar.extractAll", jasmine.createSpy('extractAll').andCallFake (backupPath, restorePath) -> return true
    model.__set__ "utilModel.removeFileAsync", jasmine.createSpy('removeFileAsync').andCallFake (backupPath, callback) -> return callback null, true
    model.__set__ "utilModel.machineIdRegistered", (uuid, callback) -> callback null, null
    model.__set__ "asar.extractFile", -> "uuid#00000"

    model.restoreBackup "/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", (err, result) ->
      expect(model.__get__("asar.extractAll")).toHaveBeenCalledWith("/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant")
      expect(model.__get__("utilModel.removeFileAsync").wasCalled).toBeFalsy();
      done()

  it 'should call only asar.extractAll with parameters when at least on vagrant file matches', (done) ->
    model.__set__ "asar.listPackage", (backupPath) -> return ["/machines/eintopf/virtualbox/id"]
    model.__set__ "asar.extractAll", jasmine.createSpy('extractAll').andCallFake (backupPath, restorePath) -> return true
    model.__set__ "utilModel.removeFileAsync", jasmine.createSpy('removeFileAsync').andCallFake (backupPath, callback) -> return callback null, true
    model.__set__ "utilModel.machineIdRegistered", createSpy().andCallFake (uuid, callback) -> callback null
    model.__set__ "asar.extractFile", -> "uuid#00000"

    model.restoreBackup "/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", (err, result) ->
      expect(model.__get__("asar.extractAll")).toHaveBeenCalledWith("/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant")
      expect(model.__get__("utilModel.removeFileAsync").wasCalled).toBeFalsy();
      expect(model.__get__("utilModel.machineIdRegistered")).toHaveBeenCalledWith "uuid#00000", any Function
      done()

  it 'should return true in callback on success', (done) ->
    model.restoreBackup "/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", (err, result) ->
      expect(result).toBeTruthy()
      expect(err).toBeFalsy();
      done()

  it "should check if the archived uuid registered in virtualbox", (done) ->
    model.__set__ "asar.extractFile", -> "uuid#00000"
    model.__set__ "utilModel.machineIdRegistered", (uuid) ->
      done expect(uuid).toEqual "uuid#00000"

    model.restoreBackup "/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", -> return

  it "should return false for the default needBackup value", (done) ->
    done expect(model.__get__("model.needBackup")).toEqual false

  it "should set the needBackup flag when a existing backup file was removed", (done) ->
    model.__set__ "utilModel.removeFileAsync", createSpy().andCallFake (path, callback) -> callback null
    model.__set__ "asar.listPackage", createSpy().andCallFake -> []
    model.restoreBackup "/tmp/eintopf/default/.vagrant.backup", "/tmp/eintopf/default/.vagrant", ->
      done expect(model.__get__("model.needBackup")).toBeTruthy()