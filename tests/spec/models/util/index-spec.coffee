'use strict';

config = require 'config'
rewire = require 'rewire'

model = null

fromPromise = (value) ->
  return new Promise (resolve) -> resolve value

failFromPromise = (error) ->
  return new Promise (resolve, reject) -> reject new Error error

describe "set config", ->

  beforeEach ->
    model = rewire "../../../../src/models/util/index.coffee"
    model.setConfig config

  it 'should return false when no object was set', ->
    expect(model.setConfig('string')).toBeFalsy()
    expect(model.setConfig(12345)).toBeFalsy()

  it 'should return true when object was set', ->
    expect(model.setConfig(config)).toBeTruthy()


describe "resolve path", ->
  orig = null

  beforeEach ->
    orig = process.env
    model = rewire "../../../../src/models/util/index.coffee"
    model.setConfig config

    spyOn(model, 'getHome').andCallFake -> '/home/mock'

  afterEach ->
    process.env = orig

  it "should return same on absolute path", ->
    expect(model.resolvePath('/ab/so/lute')).toBe '/ab/so/lute'

  it "should map relative paths", ->
    expect(model.resolvePath('./lu/te')).toBe process.cwd() + '/lu/te'
    expect(model.resolvePath('./')).toBe process.cwd() + '/'

  it "should map relative home paths (~)", ->
    expect(model.resolvePath('~/.lu/te')).toBe '/home/mock/.lu/te'
    expect(model.resolvePath('~')).toBe '/home/mock'
    expect(model.resolvePath('~/')).toBe '/home/mock/'


describe "get home", ->
  origEnvs = null

  beforeEach ->
    origEnvs = process.env
    this.originalPlatform = process.platform

    model = rewire "../../../../src/models/util/index.coffee"
    model.setConfig config

    Object.defineProperty process, 'platform', value: 'linux'
    process.env.USERPROFILE = 'c:/Users/someone'
    process.env.HOME = '/home/someone'
    process.env.EINTOPF_HOME = ''

  afterEach ->
    process.env = origEnvs
    Object.defineProperty process, 'platform',
      value: this.originalPlatform

  it "should return windows home", ->
    Object.defineProperty process, 'platform', value: 'win32'

    expect(model.getHome()).toBe(process.env.USERPROFILE);

  it "should return linux home", ->
    expect(model.getHome()).toBe(process.env.HOME);

  it "should ignore EINTOPF_HOME env", ->
    process.env.EINTOPF_HOME = '/totally/different/path'
    expect(model.getHome()).toBe(process.env.HOME);


describe "get Eintopf home", ->
  origEnvs = null

  beforeEach ->
    origEnvs = process.env
    model = rewire "../../../../src/models/util/index.coffee"
    model.setConfig config

    spyOn(model, 'getHome').andCallFake -> '/home/mock'
    spyOn(model, 'resolvePath').andCallFake -> '/home/custom/mock'
    process.env.EINTOPF_HOME = ''

  afterEach ->
    process.env = origEnvs

  it "should return getHome()", ->
    result = model.getEintopfHome()
    expect(model.getHome).toHaveBeenCalled()
    expect(result).toBe('/home/mock')

  it "should return resolvePath result", ->
    process.env.EINTOPF_HOME = '/my/custom/home';

    result = model.getEintopfHome()

    expect(model.resolvePath).toHaveBeenCalledWith(process.env.EINTOPF_HOME)
    expect(result).toBe('/home/custom/mock');

  it "should return null on relative path", ->
    process.env.EINTOPF_HOME = './relative/home';

    result = model.getEintopfHome()
    expect(result).toBeNull()

describe "remove file async", ->

  beforeEach ->
    model = rewire "../../../../src/models/util/index.coffee"
    model.__set__ "model.getConfigModulePath", -> return "/tmp/eintopf/default"
    model.__set__ "jetpack.removeAsync", () -> return fromPromise true

  it 'should fail without path parameter', (done) ->
    model.removeFileAsync null, (err) ->
      expect(err.message).toBe("Invalid path");
      done()

  it 'should call jetpack.removeAsync with parameter', (done) ->
    path = "/tmp/eintopf/default/.vagrant.backup"
    model.__set__ "jetpack.removeAsync", jasmine.createSpy('removeAsync').andCallFake () -> return fromPromise true

    model.removeFileAsync path, (err, result) ->
      expect(model.__get__ "jetpack.removeAsync").toHaveBeenCalledWith(path)
      done()

  it 'should return error on remove failure', (done) ->
    model.__set__ "jetpack.removeAsync", jasmine.createSpy('removeAsync').andCallFake () -> return failFromPromise "promise failure"

    model.removeFileAsync "/tmp/eintopf/default/.vagrant.backup", (err) ->
      expect(err.message).toBe("promise failure")
      done()

  it 'should return true on removal success', (done) ->
    model.removeFileAsync "/tmp/eintopf/default/.vagrant.backup", (err, result) ->
      expect(err).toBeFalsy()
      expect(result).toBeTruthy()
      done()