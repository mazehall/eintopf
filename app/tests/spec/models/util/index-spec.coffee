'use strict';

config = require 'config'
rewire = require 'rewire'
Q = require 'q'

async = (run) ->
  return () ->
    done = false
    waitsFor () -> return done
    run () -> done = true

fromPromise = (value) ->
  deferred = Q.defer()
  deferred.resolve value
  return deferred.promise

failFromPromise = (error) ->
  deferred = Q.defer()
  deferred.reject(new Error(error))
  return deferred.promise

describe "set config", ->

  model = null
  beforeEach ->
    model = rewire "../../../../models/util/index.coffee"
    model.setConfig config

  it 'should return false when no object was set', ->
    expect(model.setConfig('string')).toBeFalsy()
    expect(model.setConfig(12345)).toBeFalsy()

  it 'should return true when object was set', ->
    expect(model.setConfig(config)).toBeTruthy()

describe "get Eintopf home", ->
  orig = process.env

  model = null
  beforeEach ->
    model = rewire "../../../../models/util/index.coffee"
    model.setConfig config

  afterEach ->
    process.env = orig

  it "should return windows home"
  it "should return linux home"

  it "should return custom home", ->
    process.env.EINTOPF_HOME = '/my/custom/home';
    expect(model.getEintopfHome()).toBe(process.env.EINTOPF_HOME);

describe "remove file async", ->

  model = null
  beforeEach ->
    model = rewire "../../../../models/util/index.coffee"
    model.__set__ "model.getConfigModulePath", -> return "/tmp/eintopf/default"
    model.__set__ "jetpack.removeAsync", () -> return fromPromise true

  it 'should fail without path parameter', async (done) ->
    model.removeFileAsync null, (err) ->
      expect(err.message).toBe("Invalid path");
      done()

  it 'should call jetpack.removeAsync with parameter', async (done) ->
    path = "/tmp/eintopf/default/.vagrant.backup"
    model.__set__ "jetpack.removeAsync", jasmine.createSpy('removeAsync').andCallFake () -> return fromPromise true

    model.removeFileAsync path, (err, result) ->
      expect(model.__get__ "jetpack.removeAsync").toHaveBeenCalledWith(path)
      done()

  it 'should return error on remove failure', async (done) ->
    model.__set__ "jetpack.removeAsync", jasmine.createSpy('removeAsync').andCallFake () -> return failFromPromise "promise failure"

    model.removeFileAsync "/tmp/eintopf/default/.vagrant.backup", (err) ->
      expect(err.message).toBe("promise failure")
      done()

  it 'should return true on removal success', async (done) ->
    model.removeFileAsync "/tmp/eintopf/default/.vagrant.backup", (err, result) ->
      expect(err).toBeFalsy()
      expect(result).toBeTruthy()
      done()