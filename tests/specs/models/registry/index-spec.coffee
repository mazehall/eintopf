'use strict';

rewire = require "rewire"
_r = require 'kefir'
ks = rewire "kefir-storage"

model = null

defaultRegistry = [
  {
    "name": "Default sample",
    "url": "https://foo",
    "registryUrl": "default"
  }
]
remoteRegistry = [
  {
    "name": "remote sample",
    "url": "https://bar",
    "registryUrl": "remote"
  }
]


describe 'registry', ->

  beforeEach ->
    process.env.REGISTRY_URL = ''

    model = rewire "../../../../src/models/registry/index.coffee"
    model.__set__ 'defaultRegistry', JSON.parse(JSON.stringify(defaultRegistry))
    model.__set__ 'registryConfig', { public: 'http://registry.eintopf.io/files/projects.json', private: 'http://registry.eintopf.io/files/projects.json' }


  describe 'init()', ->

    beforeEach ->
      spyOn(model, 'initPublic').andCallFake
      spyOn(model, 'initPrivatesRemote').andCallFake
      spyOn(model, 'initPrivatesLocal').andCallFake

    it 'should call initPublic and init privates', ->
      model.init();

      expect(model.initPublic).toHaveBeenCalled()
      expect(model.initPrivatesRemote).toHaveBeenCalled()
      expect(model.initPrivatesLocal).toHaveBeenCalled()


  describe 'initPublic()', ->

    beforeEach ->
      ks.set 'registry:public', null

      spyOn(model, 'map').andCallFake (val) -> return val
      spyOn(model, 'streamFromPublic').andCallFake -> return _r.constant remoteRegistry

    it 'should call map and set remote result', (done) ->
      model.initPublic()
      .onEnd ->
        expect(model.map).toHaveBeenCalledWith(remoteRegistry)
        expect(ks.get('registry:public')).toEqual(remoteRegistry)
        done()

    it 'should set default registry on remote error', (done) ->
      model.streamFromPublic.andCallFake -> return _r.constantError new Error 'bad error'

      model.initPublic()
      .onEnd ->
        expect(ks.get('registry:public')).toEqual(defaultRegistry)
        done()

    it 'should set default registry on empty remote result', (done) ->
      model.streamFromPublic.andCallFake -> return _r.constant []

      model.initPublic()
      .onEnd ->
        expect(ks.get('registry:public')).toEqual(defaultRegistry)
        done()

    it 'should not continue when empty remote result and precursor exists', (done) ->
      ks.set 'registry:public', defaultRegistry
      model.streamFromPublic.andCallFake -> return _r.constant []

      model.initPublic()
      .onEnd ->
        expect(model.map).not.toHaveBeenCalled();
        done()

    it 'should not continue when error and precursor exists', (done) ->
      ks.set 'registry:public', defaultRegistry
      model.streamFromPublic.andCallFake -> return _r.constantError new Error 'bad error'

      model.initPublic()
      .onEnd ->
        expect(model.map).not.toHaveBeenCalled();
        done()


  describe 'initPrivatesRemote()', ->

    beforeEach ->
      ks.set 'registry:private:remote', null

      spyOn(model, 'map').andCallFake (val) -> return val
      spyOn(model, 'streamFromPrivates').andCallFake -> return _r.constant remoteRegistry

    it 'should call map and set remote result', (done) ->
      model.initPrivatesRemote()
      .onEnd ->
        expect(model.map).toHaveBeenCalledWith(remoteRegistry)
        expect(ks.get('registry:private:remote')).toEqual(remoteRegistry)
        done()

    it 'should set empty array on remote error', (done) ->
      model.streamFromPrivates.andCallFake -> return _r.constantError new Error 'something'

      model.initPrivatesRemote()
      .onEnd ->
        expect(ks.get('registry:private:remote')).toEqual([])
        done()

    it 'should not set when empty remote result and precursor exists', (done) ->
      ks.set 'registry:private:remote', defaultRegistry
      model.streamFromPrivates.andCallFake -> return _r.constant []

      model.initPrivatesRemote()
      .onEnd ->
        expect(model.map).not.toHaveBeenCalled();
        done()

    it 'should not continue when error and precursor exists', (done) ->
      ks.set 'registry:private:remote', defaultRegistry
      model.streamFromPrivates.andCallFake -> return _r.constantError new Error 'bad error'

      model.initPrivatesRemote()
      .onEnd ->
        expect(model.map).not.toHaveBeenCalled();
        done()


  describe 'initPrivatesLocal()', ->

    beforeEach ->
      ks.set 'registry:private:local', null

      spyOn(model, 'map').andCallFake (val) -> return val

      local = model.__get__ 'local'
      spyOn(local, 'getRegistryAsArray').andCallFake (callback) ->
        setTimeout ->
          callback null, remoteRegistry
        , 0

    it 'should call map and set remote result', (done) ->
      model.initPrivatesLocal()
      .onEnd ->
        expect(model.map).toHaveBeenCalledWith(remoteRegistry)
        expect(ks.get('registry:private:local')).toEqual(remoteRegistry)
        done()

    it 'should set empty array on error', (done) ->
      local = model.__get__('local').getRegistryAsArray.andCallFake (callback) ->
        setTimeout ->
          callback new Error 'something happened'
        , 0

      model.initPrivatesLocal()
      .onEnd ->
        expect(ks.get('registry:private:local')).toEqual([])
        done()


  describe 'addLocalEntryFromUrl()', ->

    beforeEach ->
      spyOn(model, 'initPrivatesLocal').andCallFake ->

      local = model.__get__ 'local'
      spyOn(local, 'streamAddEntryFromUrl').andCallFake -> _r.constant true


    it 'should call streamAddEntryFromUrl, initPrivatesLocal and return true in callback', (done) ->
      model.addLocalEntryFromUrl 'http://foo', (err, result) ->
        expect(model.__get__('local').streamAddEntryFromUrl).toHaveBeenCalled()
        expect(model.initPrivatesLocal).toHaveBeenCalled()
        expect(result).toBeTruthy()
        done()

    it 'should fail on error', (done) ->
      model.__get__('local').streamAddEntryFromUrl.andCallFake -> _r.constantError new Error 'test error'

      model.addLocalEntryFromUrl 'http://foo', (err) ->
        expect(err).toBeTruthy()
        done()

  describe 'map()', ->

    beforeEach ->
      utils = require "../../../../src/models/util/index.coffee"
      spyOn(utils, 'typeIsArray').andCallThrough()
      spyOn(utils, 'getProjectNameFromGitUrl').andCallFake -> return 'testMe'
      spyOn(utils, 'isProjectInstalled').andCallFake -> return false

      model.__set__ 'utils', utils

    it 'should return null on non array', ->
      (expect(model.map test).toBeNull()) for test in [undefined, null, 'string', {"object": true}]

    it 'should add id property', ->
      expect(model.map(defaultRegistry)[0].id).toBeTruthy()

    it 'should call getProjectNameFromGitUrl and generate dir name property', ->
      expect(model.map(defaultRegistry)[0].dirName).toEqual('testMe')
      expect(model.__get__('utils').getProjectNameFromGitUrl).toHaveBeenCalled()

    it 'should call isProjectInstalled and set installed flag false', ->
      expect(model.map(defaultRegistry)[0].installed).toBeFalsy()
      expect(model.__get__('utils').isProjectInstalled).toHaveBeenCalledWith('testMe')

    it 'should call isProjectInstalled and set install flag true', ->
      utils = rewire "../../../../src/models/util/index.coffee"
      spyOn(utils, 'typeIsArray').andCallThrough()
      spyOn(utils, 'getProjectNameFromGitUrl').andCallFake -> return 'testMe'
      spyOn(utils, 'isProjectInstalled').andCallFake -> return true
      model.__set__ 'utils', utils

      expect(model.map(defaultRegistry)[0].installed).toBeTruthy()
      expect(model.__get__('utils').isProjectInstalled).toHaveBeenCalledWith('testMe')

    it "should not call isProjectInstalled when pattern", ->
      registry = JSON.parse(JSON.stringify(defaultRegistry))
      registry[0].pattern = true

      model.map(registry)
      expect(model.__get__('utils').isProjectInstalled).not.toHaveBeenCalled()


  describe 'remapRegistries()', ->

    beforeEach ->
      spyOn(model, 'map').andCallFake (val) -> return val

      ks.set 'registry:public', defaultRegistry
      ks.set 'registry:private:remote', remoteRegistry

    it 'should call map with public and private:remote data', (done) ->
      model.remapRegistries()
      .onEnd ->
        expect(model.map).toHaveBeenCalledWith(defaultRegistry)
        expect(model.map).toHaveBeenCalledWith(remoteRegistry)
        done()

    it 'should set mapped registries', (done) ->
      expected = 'remapped stuff'
      model.map.andCallFake -> return expected

      model.remapRegistries()
      .onEnd ->
        ks.get 'registry:public', expected
        ks.get 'registry:private:remote', expected
        done()


  describe 'streamFromPublic()', ->

    beforeEach ->
      remote = require "../../../../src/models/registry/remote.coffee"
      spyOn(remote, 'loadFromUrls').andCallFake (uri, callback) ->
        setTimeout -> callback null, remoteRegistry
        , 0
      model.__set__ 'remote', remote

    it 'should call loadFromUrls() from remote', (done) ->
      model.streamFromPublic()
      .onEnd ->
        expect(model.__get__('remote').loadFromUrls).toHaveBeenCalled()
        done()

    it 'should emit remote result', (done) ->
      emitCheck = jasmine.createSpy('emitCheck');

      model.streamFromPublic()
      .onValue emitCheck
      .onEnd ->
        expect(emitCheck).toHaveBeenCalledWith(remoteRegistry)
        done()

    it 'should fail when not configured', (done) ->
      model.__set__ 'registryConfig', { }
      errorCheck = jasmine.createSpy('errorCheck');

      model.streamFromPublic()
      .onError errorCheck
      .onEnd ->
        expect(errorCheck).toHaveBeenCalled()
        done()

    it 'should fail on remote error', (done) ->
      remote = rewire "../../../../src/models/registry/remote.coffee"
      spyOn(remote, 'loadFromUrls').andCallFake (uri, callback) ->
        setTimeout -> callback new Error 'one error', null
        , 0
      model.__set__ 'remote', remote

      errorCheck = jasmine.createSpy('errorCheck');

      model.streamFromPublic()
      .onError errorCheck
      .onEnd ->
        expect(errorCheck).toHaveBeenCalled()
        done()

  describe 'streamFromPrivates()', ->

    beforeEach ->
      remote = require "../../../../src/models/registry/remote.coffee"
      spyOn(remote, 'loadFromUrls').andCallFake (uri, callback) ->
        setTimeout -> callback null, remoteRegistry
        , 0
      model.__set__ 'remote', remote

    it 'should call loadFromUrls() from remote', (done) ->
      model.streamFromPrivates()
      .onEnd ->
        expect(model.__get__('remote').loadFromUrls).toHaveBeenCalled()
        done()

    it 'should emit remote result', (done) ->
      emitCheck = jasmine.createSpy('emitCheck');

      model.streamFromPrivates()
      .onValue emitCheck
      .onEnd ->
        expect(emitCheck).toHaveBeenCalledWith(remoteRegistry)
        done()

    it 'should allow multiple configured urls in array', (done) ->
      model.__set__ 'registryConfig', { private: ['http://registry.eintopf.io/files/projects.json'] }
      emitCheck = jasmine.createSpy('emitCheck');

      model.streamFromPrivates()
      .onValue emitCheck
      .onEnd ->
        expect(emitCheck).toHaveBeenCalledWith(remoteRegistry)
        done()

    it 'should fail when not configured', (done) ->
      model.__set__ 'registryConfig', { }
      errorCheck = jasmine.createSpy('errorCheck');

      model.streamFromPrivates()
      .onError errorCheck
      .onEnd ->
        expect(errorCheck).toHaveBeenCalled()
        done()

    it 'should fail on remote error', (done) ->
      remote = rewire "../../../../src/models/registry/remote.coffee"
      spyOn(remote, 'loadFromUrls').andCallFake (uri, callback) ->
        setTimeout -> callback new Error 'one error', null
        , 0
      model.__set__ 'remote', remote

      errorCheck = jasmine.createSpy('errorCheck');

      model.streamFromPrivates()
      .onError errorCheck
      .onEnd ->
        expect(errorCheck).toHaveBeenCalled()
        done()
