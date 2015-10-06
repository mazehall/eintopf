'use strict';

config = require 'config'

customConfig = require "../../../../models/stores/config.coffee"

describe "config store", ->

  it 'should return a object', ->
    expect(typeof customConfig).toBe('object')

  it 'should inherit config functions', ->
    expect(customConfig.has).toBe(config.has)
    expect(customConfig.get).toBe(config.get)

  it 'should inherit config util functions', ->
    expect(typeof customConfig.util).toBe('object')
    expect(customConfig.util.setModuleDefaults).toBe(config.util.setModuleDefaults)
    expect(customConfig.util.makeImmutable).toBe(config.util.makeImmutable)

  it 'should still have a working get function', ->
    expect(customConfig.get('test.key')).toBe('value')

  it 'should throw error when setting existing var because of immutability', ->
    setConfigTestVar = ->
      config.test.key = 'someOtherValue';
    expect(setConfigTestVar).toThrow("Cannot assign to read only property 'key' of #<Object>")