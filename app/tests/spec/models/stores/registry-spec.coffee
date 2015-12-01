'use strict';

rewire = require "rewire"

describe "registry", ->

  model = null
  noop = -> @
  beforeEach ->
    model = rewire "../../../../models/stores/registry.coffee"
    model.__set__ "https", {request: (option, callback) -> callback? end: noop, on: noop}
    model.__set__ "http",  {request: (option, callback) -> callback? end: noop, on: noop}
    model.__set__ "model.loadRegistryContent", (url, callback) -> callback?(null, [])
    model.__set__ "registryConfig", {public: []}

  it "should contain a 'public' and 'private' key", (done) ->
    model.loadRegistry (error, data) ->
      expect(data.public).toBeDefined()
      expect(data.private).toBeDefined()
      done()

  it "should return the default registry if the public url is unreachable", (done) ->
    model.__set__ "model.loadRegistryContent", (url, callback) -> callback new Error
    model.__set__ "defaultRegistry", {defaultRegistry: true}
    model.loadRegistry (error, data) ->
      done expect(data.public).toEqual {defaultRegistry: true}

  it "should return the private registry as a array when defined in the config", (done) ->
    privateRegistryContent = ["private", {}, {}, {name: null, version: 0.11}]
    model.__set__ "registryConfig", {private: ["https://bar", "https://baz"]}
    model.__set__ "model.loadPrivateRegistryContent", (privates, callback) ->
      callback null, privateRegistryContent

    model.loadRegistry (error, data) ->
      expect(data.private).toEqual any Array
      expect(data.private).toEqual privateRegistryContent
      done()

  it "should return the private registry as a array when public url is unreachable", (done) ->
    privateRegistryContent = ["private", {}, {}, {name: null, version: 3.21}]
    model.__set__ "registryConfig", {private: ["https://bar", "https://baz"]}
    model.__set__ "model.loadRegistryContent", (url, callback) -> callback new Error "404"
    model.__set__ "model.loadPrivateRegistryContent", (privates, callback) ->
      callback null, privateRegistryContent

    model.loadRegistry (error, data) ->
      done expect(data.private).toEqual privateRegistryContent

  it "should return none error object when public url is unreachable", (done) ->
    model.__set__ "registryConfig", {private: ["https://bar", "https://baz"]}
    model.__set__ "model.loadRegistryContent", (url, callback) -> callback new Error "404"

    model.loadRegistry (error, data) ->
      expect(error).toBeNull()
      expect(data).toEqual any Object
      done()

  it "should call 'model.loadRegistryContent' with the defined public url", (done) ->
    model.__set__ "publicRegistry", "https://foo.bar"
    model.__set__ "model.loadRegistryContent", (url) ->
      done expect(url).toEqual "https://foo.bar"
    model.loadRegistry()

  it "should call 'model.loadPrivateRegistryContent' when any private urls exist", (done) ->
    spyOn(model, "loadPrivateRegistryContent").andCallThrough()
    model.__set__ "registryConfig", {private: ["https://bar", "https://baz"]}
    model.loadRegistry ->
      done expect(model.loadPrivateRegistryContent).toHaveBeenCalled()

  it "should not called 'model.loadPrivateRegistryContent' when no private url´s given", (done) ->
    spyOn(model, "loadPrivateRegistryContent").andCallThrough()
    model.__set__ "registryConfig", {}
    model.loadRegistry ->
      done expect(model.loadPrivateRegistryContent).not.toHaveBeenCalled()

  it "should call 'model.loadPrivateRegistryContent' when the defined private url´s", (done) ->
    spyOn(model, "loadPrivateRegistryContent").andCallThrough()
    model.__set__ "registryConfig", {private: ["https://bar", "https://baz"]}
    model.loadRegistry ->
      done expect(model.loadPrivateRegistryContent).toHaveBeenCalledWith ["https://bar", "https://baz"], any Function

  it "should call 'model.loadRegistryContent' with the defined private url", (done) ->
    spyOn(model, "loadRegistryContent").andCallThrough()
    model.__set__ "registryConfig", {private: ["https://foo.bar"], public: "https://baz.bar"}
    model.loadRegistry ->
      done expect(model.loadRegistryContent.calls[1].args[0]).toEqual "https://foo.bar"

  it "should call 'model.loadRegistryContent' with the defined private url when public url is unreachable", (done) ->
    spyOn(model, "loadRegistryContent").andCallThrough()
    model.__set__ "registryConfig", {private: ["https://foo.bar"], public: ""}
    model.loadRegistry ->
      done expect(model.loadRegistryContent.calls[1].args[0]).toEqual "https://foo.bar"

  it "should return registry object when successfully loaded", (done) ->
    model.loadRegistry (error, data) ->
      done expect(data).toEqual any Object

  it "should return registry object and not a error when successfully loaded", (done) ->
    model.loadRegistry (error) ->
      done expect(error).toEqual null

  it "should throw an error when 'model.loadRegistry' called without defined public url", ->
    model.__set__ "publicRegistry", null
    model.loadRegistry ->
    expect(model.loadRegistry).toThrow()

  it "should overwrite property 'model.loadingTimeout' via process.env", ->
    process.env.REGISTRY_INTERVAL = 1234321
    model = rewire "../../../../models/stores/registry.coffee"
    expect(process.env.REGISTRY_INTERVAL).toEqual model.__get__ "loadingTimeout"

  it "should overwrite property 'model.publicRegistry' via process.env", ->
    process.env.REGISTRY_URL = "http://foo.public"
    model = rewire "../../../../models/stores/registry.coffee"
    expect(process.env.REGISTRY_URL).toEqual model.__get__ "publicRegistry"

  it "should throw an error when invalid json received", ->
    spyOn(model, "loadRegistryContent").andCallThrough()

    model = rewire "../../../../models/stores/registry.coffee"
    model.__set__ "http",
      request: (option, callback) ->
        res = {statusCode: 200}
        res.end = -> res
        res.on = (method, callback) ->
          return res unless method is "end"
          res.chunk = "{{invalid: json//"
          callback res
          return res
        return callback res

    model.loadRegistryContent "http://foo.bar", ->
    expect(model.loadRegistryContent).toThrow()

  it "should return the error when 'model.loadRegistryContent' fails", (done) ->
    spyOn(model, "loadRegistryContent").andCallThrough()

    model = rewire "../../../../models/stores/registry.coffee"
    model.__set__ "http",
      request: (option, callback) ->
        res = {statusCode: 200}
        res.end = -> res
        res.on = (method, callback) ->
          return res unless method is "end"
          res.chunk = "{{invalid: json//"
          callback res
          return res
        return callback res

    model.loadRegistryContent "http://foo.bar", (error) ->
      expect(error).toEqual any Error
      expect(error.message).toMatch /failed to/i
      done()