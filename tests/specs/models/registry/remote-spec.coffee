'use strict';

rewire = require "rewire"

model = null

remoteSample1 = [
  {
    "name": "remote sample",
    "url": "https://foo"
  }
]


describe 'registry', ->

  beforeEach ->
    model = rewire "../../../../src/models/registry/remote.coffee"

  describe 'loadUrl()', ->
    jsonReturn = null
    endResult = null

    beforeEach ->
      jsonReturn = '[{"name": "test", "url": "http://foo"}]'
      endResult = {statusCode: 200}

      model.__set__ "https",
        request: jasmine.createSpy('server.https').andCallFake (option, callback) ->
          res = endResult
          res.end = -> res
          res.on = (method, callback) ->
            return res unless method is "end"
            res.chunk = jsonReturn
            callback res
            return res
          return callback res

      model.__set__ "http",
        request: jasmine.createSpy('server.http').andCallFake (option, callback) ->
          res = endResult
          res.end = -> res
          res.on = (method, callback) ->
            return res unless method is "end"
            res.chunk = jsonReturn
            callback res
            return res
          return callback res

      url = require 'url'
      spyOn(url, 'parse').andCallThrough()
      model.__set__ 'url', url

    it 'should return parsed json result', (done) ->
      model.loadUrl 'http://foo', (err, json) ->
        expect(err).toBeFalsy()
        expect(json).toEqual(JSON.parse(jsonReturn))
        done()

    it 'should parse url', (done) ->
      model.loadUrl 'http://foo', ->
        expect(model.__get__('url').parse).toHaveBeenCalled()
        done()

    it 'should call https server', (done) ->
      model.loadUrl 'https://foo', ->
        expect(model.__get__('https').request).toHaveBeenCalled()
        done()

    it 'should call http server', (done) ->
      model.loadUrl 'http://foo', ->
        expect(model.__get__('http').request).toHaveBeenCalled()
        done()

    it 'should fail on server error', (done) ->
      model.__set__ "http",
        request: jasmine.createSpy('server.http').andCallFake (option, callback) ->
          res = endResult
          res.end = -> res
          res.on = (method, callback) ->
            return res unless method is "error"
            callback new Error 'test'
          return callback res

      model.loadUrl 'http://foo', (err) ->
        expect(err).toBeTruthy()
        done()

    it 'should fail on non 2xx status code', (done) ->
      endResult = {statusCode: 500}

      model.loadUrl 'http://foo', (err) ->
        expect(err).toBeTruthy()
        done()

    it 'should fail on unsupported url protocol', (done) ->
      model.loadUrl 'file://home/dev/test', (err) ->
        expect(err).toBeTruthy()
        done()

    it 'should fail on invalid json result', (done) ->
      jsonReturn = "{{invalid: json//"

      model.loadUrl 'http://foo', (err) ->
        expect(err).toBeTruthy()
        done()


  describe 'loadFromUrls()', ->
    remoteResult = null

    beforeEach ->
      remoteResult = remoteSample1

      spyOn(model, 'loadUrl').andCallFake (url, callback) ->
        setTimeout ->
          return callback new Error 'error' if url == 'http://error'
          callback null, remoteResult
        , 0

    it 'should return result when called with string', (done) ->
      model.loadFromUrls 'http://foo-reg', (err, result) ->
        expect(result).toEqual(remoteSample1)
        done()

    it 'should return result when called with array', (done) ->
      model.loadFromUrls ['http://foo-reg'], (err, result) ->
        expect(result).toEqual(remoteSample1)
        done()

    it 'should return multiple results when called with multiple urls in array', (done) ->
      model.loadFromUrls ['http://foo-reg', 'http://bar-reg'], (err, result) ->
        expect(model.loadUrl.callCount).toEqual(2)
        expect(result.length).toEqual(2)
        done()

    it 'should skip duplicate urls', (done) ->
      model.loadFromUrls ['http://foo-reg', 'http://foo-reg'], (err, result) ->
        expect(model.loadUrl.callCount).toEqual(1)
        done()

    it 'should skip duplicate urls from same registry', (done) ->
      registryData = JSON.parse(JSON.stringify(remoteSample1))
      registryData.push registryData[0]
      remoteResult = registryData

      model.loadFromUrls ['http://foo-reg'], (err, result) ->
        expect(result.length).toEqual(1)
        done()

    it 'should return empty array on server error', (done) ->
      model.loadFromUrls ['http://error'], (err, result) ->
        expect(result).toEqual([])
        done()

    it 'should return partial result on partial error', (done) ->
      model.loadFromUrls ['http://foo-reg', 'http://error'], (err, result) ->
        expect(result).toEqual(remoteSample1)
        done()
