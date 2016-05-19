'use strict';

config = require 'config'
rewire = require 'rewire'

model = null

fromPromise = (value) ->
  return new Promise (resolve) -> resolve value

failFromPromise = (error) ->
  return new Promise (resolve, reject) -> reject new Error error

describe 'local registry', ->
  origEnv = null

  beforeEach ->
    origEnv = process.env
    model = rewire "../../../../src/models/util/index.coffee"
    spyOn(model, 'getConfigModulePath').andCallFake -> '/home/test/.eintopf/default'

  afterEach ->
    process.env = origEnv

  describe "initConfig", ->
    readConfig = {registry: {"private": ["http://127.0.0.1/eintopf-projects.json"]}}

    beforeEach ->
      mockConfig = rewire "config"
      mockConfig.util.extendDeep = jasmine.createSpy('util.extendDeep').andCallThrough()
      model.__set__ 'config', mockConfig

      jetpack = model.__get__ 'jetpack'
      spyOn(jetpack, 'read').andCallFake -> return readConfig

    it 'should call jetpack.read and config.util.extendDeep with correct params', ->
      model.initConfig()
      expect(model.__get__('jetpack').read).toHaveBeenCalledWith '/home/test/.eintopf/default/config.json', 'json'
      expect(model.__get__('config').util.extendDeep).toHaveBeenCalledWith model.__get__('config'), readConfig

    it 'should fail when no config module path', ->
      model.getConfigModulePath.andCallFake -> null

      model.initConfig()
      expect(model.__get__('jetpack').read).not.toHaveBeenCalled()
      expect(model.__get__('config').util.extendDeep).not.toHaveBeenCalled()

    it 'should catch jetpack.read exceptions', ->
      model.__get__('jetpack').read.andCallFake -> throw new Error 'failed to parse Json'
      model.initConfig()

    it 'should catch config.util.extendDeep exceptions', ->
      model.__get__('config').util.extendDeep.andCallFake -> throw new Error 'Cannot redefine property: refreshInterval'
      model.initConfig()

  describe "resolve path", ->

    beforeEach ->
      spyOn(model, 'getHome').andCallFake -> '/home/mock'

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

    beforeEach ->
      this.originalPlatform = process.platform

      model = rewire "../../../../src/models/util/index.coffee"

      Object.defineProperty process, 'platform', value: 'linux'
      process.env.USERPROFILE = 'c:/Users/someone'
      process.env.HOME = '/home/someone'
      process.env.EINTOPF_HOME = ''

    afterEach ->
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

    beforeEach ->
      model = rewire "../../../../src/models/util/index.coffee"

      spyOn(model, 'getHome').andCallFake -> '/home/mock'
      spyOn(model, 'resolvePath').andCallFake -> '/home/custom/mock'
      process.env.EINTOPF_HOME = ''

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