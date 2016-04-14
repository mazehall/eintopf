'use strict';

rewire = require "rewire"

model = null

registry =
  "https://foo":
    "name": "Default foo sample",
    "url": "https://foo",
    "registryUrl": "local"
  "https://bar":
    "name": "Default bar sample",
    "url": "https://bar",
    "registryUrl": "local"

recipe =
  name: 'foo sample recipe'
  description: 'foo sample recipe description'
  mediabg: undefined
  src: undefined
  url: 'http://foo'

packageJson =
  "name": "node-sample",
  "eintopf": {
    "name": "node sample",
    "description": "desc sample",
    "mediabg": '#6779b5',
    "src": 'data:image/png;base64,....'
  }

describe 'local registry', ->

  beforeEach ->
    model = rewire "../../../../src/models/registry/local.coffee"


  describe 'getRegistry()', ->

    beforeEach ->
      model.__set__ 'registryData', null

      utils = model.__get__ 'utils'
      spyOn(utils, 'getConfigModulePath').andCallFake -> return '/path/to/eintopf/module'
      spyOn(utils, 'loadJsonAsync').andCallFake (path, callback) -> return callback null, registry

    it 'should return registry data', ->
      model.getRegistry (err, result) ->
        expect(result).toEqual(registry)

    it 'should call loadJson with correct path', ->
      model.getRegistry ->
        expect(model.__get__('utils').getConfigModulePath).toHaveBeenCalled()
        expect(model.__get__('utils').loadJsonAsync).toHaveBeenCalledWith('/path/to/eintopf/module/registry.json', jasmine.any(Function))

    it 'should fail on error', ->
      model.__get__('utils').loadJsonAsync.andCallFake (path, callback) -> return callback new Error 'somehting'

      model.getRegistry (err) ->
        expect(err).toBeTruthy()

    it 'should fail when failing to fetch eintopf config module path', ->
      model.__get__('utils').getConfigModulePath.andCallFake -> return null

      model.getRegistry (err) ->
        expect(err).toBeTruthy()

    it 'should immediately return already loaded registry', ->
      model.__set__ 'registryData', registry

      model.getRegistry (err, result) ->
        expect(model.__get__('utils').getConfigModulePath).not.toHaveBeenCalled()
        expect(model.__get__('utils').loadJsonAsync).not.toHaveBeenCalled()
        expect(result).toEqual(registry)


  describe 'getRegistryAsArray()', ->

    beforeEach ->
      spyOn(model, 'getRegistry').andCallFake (callback) -> callback null, registry

    it 'should return expected array', ->
      expected = [ registry['https://foo'], registry['https://bar'] ]

      model.getRegistryAsArray (err, result) ->
        expect(result).toEqual(expected)

    it 'should fail on error', ->
      exception = new Error 'something'
      model.getRegistry.andCallFake (callback) -> callback exception

      model.getRegistryAsArray (err) ->
        expect(err).toBe(exception)

    it 'should return empty array when json content is not an object', ->
      model.getRegistry.andCallFake (callback) -> callback null, 'not a object'
      model.getRegistryAsArray (err, result) ->
        expect(result).toEqual([])

      model.getRegistry.andCallFake (callback) -> callback null, null
      model.getRegistryAsArray (err, result) ->
        expect(result).toEqual([])

  describe 'saveRegistry()', ->

    beforeEach ->
      model.__set__ 'registryData', null

      utils = model.__get__ 'utils'
      spyOn(utils, 'getConfigModulePath').andCallFake -> return '/path/to/eintopf/module'
      spyOn(utils, 'writeJsonAsync').andCallFake (path, content, callback) -> return callback null, true

    it 'should set saved registryData and return true', ->
      model.saveRegistry registry, (err, result) ->
        expect(model.__get__('registryData')).toEqual(registry)
        expect(result).toBeTruthy()

    it 'should call writeJsonAsync with expected parameters', ->
      expectedPath = '/path/to/eintopf/module/registry.json'

      model.saveRegistry registry, ->
        expect(model.__get__('utils').writeJsonAsync).toHaveBeenCalledWith(expectedPath, registry, jasmine.any(Function))

    it 'should fail when saving fails', ->
      model.__get__('utils').writeJsonAsync.andCallFake (path, content, callback) -> return callback new Error 'something'

      model.saveRegistry registry, (err) ->
        expect(err).toBeTruthy()

    it 'should fail when failing to fetch eintopf config module path', ->
      model.__get__('utils').getConfigModulePath.andCallFake -> return null

      model.saveRegistry registry, (err) ->
        expect(err).toBeTruthy()

    it 'should not set registry data on error', ->
      model.__get__('utils').writeJsonAsync.andCallFake (path, content, callback) -> return callback new Error 'something'

      model.saveRegistry registry, (err) ->
        expect(model.__get__ 'registryData').toBeNull()


  describe 'saveEntry()' , ->

    beforeEach ->
      spyOn(model, 'getRegistry').andCallFake (callback) -> callback null, null
      spyOn(model, 'saveRegistry').andCallFake (content, callback) -> callback null, true

    it 'should call return true', (done) ->
      model.saveEntry recipe, (err, result) ->
        expect(result).toBeTruthy()
        done()

    it 'should call save registry with expected data when registry empty', (done) ->
      expected = {}
      expected[recipe.url] = recipe
      expected[recipe.url].registryUrl = 'local' # should be added in logic

      model.saveEntry recipe, ->
        expect(model.saveRegistry).toHaveBeenCalledWith(expected, jasmine.any(Function))
        done()

    it 'should call save registry with expected data when registry filled', (done) ->
      expected = registry
      expected[recipe.url] = recipe
      expected[recipe.url].registryUrl = 'local' # should be added in logic

      model.getRegistry.andCallFake (callback) -> callback null, registry

      model.saveEntry recipe, ->
        expect(model.saveRegistry).toHaveBeenCalledWith(expected, jasmine.any(Function))
        done()

    it 'should overwrite existing entry with expected data', (done) ->
      expected = registry
      expected[recipe.url] = recipe
      expected[recipe.url].registryUrl = 'local' # should be added in logic

      model.getRegistry.andCallFake (callback) -> callback null, expected

      model.saveEntry recipe, ->
        expect(model.saveRegistry).toHaveBeenCalledWith(expected, jasmine.any(Function))
        done()

    it 'should fail when recipe does not have name property', (done) ->
      model.saveEntry {url: 'http://foo'}, (err) ->
        expect(err).toBeTruthy()
        done()

    it 'should fail when recipe does not have url property', (done) ->
      model.saveEntry {name: 'foo recipe sample'}, (err) ->
        expect(err).toBeTruthy()
        done()

    it 'should fail on getRegistry error', (done) ->
      expected = new Error 'something'
      model.getRegistry.andCallFake (callback) -> callback expected

      model.saveEntry recipe, (err) ->
        expect(err).toBe(expected)
        done()

    it 'should fail on saveRegistry error', (done) ->
      expected = new Error 'something'
      model.saveRegistry.andCallFake (content, callback) -> callback expected

      model.saveEntry recipe, (err) ->
        expect(err).toBe(expected)
        done()

  describe 'streamAddEntryFromUrl()', ->

    beforeEach ->
      spyOn(model, 'saveEntry').andCallFake (recipe, callback) -> callback null, true

      utils = model.__get__ 'utils'
      spyOn(utils, 'getProjectNameFromGitUrl').andCallFake -> return 'something'
      spyOn(utils, 'loadJsonAsync').andCallFake (path, callback) -> return callback null, packageJson

      tmp = model.__get__ 'tmp'
      spyOn(tmp, 'dir').andCallFake (opts, callback) -> return callback null, '/tmp/eintopf_123xy'

      git = model.__get__ 'git'
      spyOn(git, 'clone').andCallFake (url, dir, callback) -> return callback null, {path: '/tmp/eintopf_123xy'}

    it 'should emit true', (done) ->
      expected = jasmine.createSpy('onValue').andCallFake (val) ->

      model.streamAddEntryFromUrl 'http://foo'
      .onValue expected
      .onEnd ->
        expect(expected).toHaveBeenCalledWith(true)
        done()

    it 'should call tmp.dir() with correct parameters', (done) ->
      expected = { mode: '0750', prefix: 'eintopf_', unsafeCleanup: true}

      model.streamAddEntryFromUrl 'http://foo'
      .onEnd ->
        expect(model.__get__('tmp').dir).toHaveBeenCalledWith(expected, jasmine.any(Function))
        done()

    it 'should call git.clone() with correct parameters', (done) ->
      expectedUrl = 'http://foo'
      expectedDirName = '/tmp/eintopf_123xy'

      model.streamAddEntryFromUrl expectedUrl
      .onEnd ->
        expect(model.__get__('git').clone).toHaveBeenCalledWith(expectedUrl, '/tmp/eintopf_123xy', jasmine.any(Function))
        done()

    it 'should call utils.loadJsonAsync() with correct parameters', (done) ->
      expected = '/tmp/eintopf_123xy/package.json'

      model.streamAddEntryFromUrl 'http://foo'
      .onEnd ->
        expect(model.__get__('utils').loadJsonAsync).toHaveBeenCalledWith(expected, jasmine.any(Function))
        done()

    it 'should call saveEntry with mapped recipe', (done) ->
      projectUrl = 'http://foo'

      expected =
        name: packageJson.eintopf.name
        description: packageJson.eintopf.description
        mediabg: packageJson.eintopf.mediabg
        src: packageJson.eintopf.src
        url: projectUrl

      model.streamAddEntryFromUrl projectUrl
      .onEnd ->
        expect(model.saveEntry).toHaveBeenCalledWith(expected, jasmine.any(Function))
        done()

    it 'should fail when package.json does not have eintopf.name property', (done) ->
      expected = jasmine.createSpy('onError').andCallFake (err) ->
      model.__get__('utils').loadJsonAsync.andCallFake (path, callback) -> return callback null, {eintopf: {description: 'test'}}

      model.streamAddEntryFromUrl  'http://foo'
      .onError expected
      .onEnd ->
        expect(expected).toHaveBeenCalled()
        done()

    it 'should fail when getProjectNameFromGitUrl fails', (done) ->
      expected = jasmine.createSpy('onError').andCallFake (err) ->
      model.__get__('utils').getProjectNameFromGitUrl.andCallFake -> return null

      model.streamAddEntryFromUrl ''
      .onError expected
      .onEnd ->
        expect(expected).toHaveBeenCalled()
        done()

    it 'should fail when tmp.dir fails', (done) ->
      expected = jasmine.createSpy('onError').andCallFake (err) ->
      model.__get__('tmp').dir.andCallFake (opts, callback) -> return callback new Error 'something'

      model.streamAddEntryFromUrl 'http://foo'
      .onError expected
      .onEnd ->
        expect(expected).toHaveBeenCalled()
        done()

    it 'should fail when git.clone fails', (done) ->
      expected = jasmine.createSpy('onError').andCallFake (err) ->
      model.__get__('git').clone.andCallFake (projectUrl, dirName, callback) -> return callback new Error 'something'

      model.streamAddEntryFromUrl 'http://foo'
      .onError expected
      .onEnd ->
        expect(expected).toHaveBeenCalled()
        done()

    it 'should fail when utils.loadJsonAsync fails', (done) ->
      expected = jasmine.createSpy('onError').andCallFake (err) ->
      model.__get__('utils').loadJsonAsync.andCallFake (path, callback) -> return callback new Error 'something'

      model.streamAddEntryFromUrl 'http://foo'
      .onError expected
      .onEnd ->
        expect(expected).toHaveBeenCalled()
        done()

    it 'should fail when saveEntry fails', (done) ->
      expected = jasmine.createSpy('onError').andCallFake (err) ->
      model.saveEntry.andCallFake (recipe, callback) -> return callback new Error 'something'

      model.streamAddEntryFromUrl 'http://foo'
      .onError expected
      .onEnd ->
        expect(expected).toHaveBeenCalled()
        done()

