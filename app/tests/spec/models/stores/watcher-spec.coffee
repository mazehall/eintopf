'use strict';

rewire = require "rewire"

model = null
data =
  "null": null
  "bTrue": true
  "bFalse": false
  "string": "I am string"

  "object":
    "null": null
    "bTrue": true
    "bFalse": false
    "string": "I am string too"
    "object": {"key": "val1", "key": "val2"}
    "array": [ "aval1", "aval2"]

  "array": [
    null
    true
    false
    "I am string too"
    {"key": "val1", "key": "val2"}
    ["aval1", "aval2"]
  ]

# set cloned object to avoid object referencing issues
cloneObject = (obj) -> JSON.parse(JSON.stringify(obj))

describe 'get', ->

  beforeEach ->
    model = rewire "../../../../models/stores/watcher.coffee"
    model.__set__ '_store', cloneObject data

  it "Should return null", ->
    expect(model.get 'null').toBeNull()

  it "Should return boolean true", ->
    expect(model.get 'bTrue').toBe(true)

  it "Should return boolean false", ->
    expect(model.get 'bFalse').toBe(false)

  it "Should return correct string", ->
    expect(model.get 'string').toBe(data.string)

  it "Should return complete object", ->
    expect(model.get 'object').toEqual(data.object)

  it "Should return complete array", ->
    expect(model.get 'array').toEqual(data.array)

  it "object changes should not change the storage data through object reference", ->
    objectData = model.get 'object'
    objectData.string = "Changed string"
    objectData.something = "new property"

    expect(model.__get__ '_store').toEqual(data)

  it "Should fail when no property given", ->
    expect(model.get '').toBeFalsy()
    expect(model.get null).toBeFalsy()

  it "Should return undefined if property does not exist", ->
    expect(model.get 'entropy').toBeUndefined()

#@todo implementation??
describe 'getProperty', ->


describe 'log', ->

  beforeEach ->
    model = rewire "../../../../models/stores/watcher.coffee"
    model.__set__ '_store', cloneObject data

  it "Should set log entries", ->
    logData = ['first entry', 'second entry', 'third entry']

    for line in logData
      model.log 'log', line

    expect(model.__get__('_store').log).toEqual(logData)

  it "Should remove lines when max lines reached", ->
    logData = ['first entry', 'second entry', 'third entry', 'fourth entry']

    model.__set__ 'linesMax', 2

    for line in logData
      model.log 'log', line

    expect(model.__get__('_store').log).toEqual([logData[2], logData[3]])

  it "Should replace existing property if it is no array", ->
    model.__set__ '_store', {"log": {"1": "a line"}}

    logData = ['first entry', 'second entry', 'third entry']

    for line in logData
      model.log 'log', line

    expect(model.__get__('_store').log).toEqual(logData)

  it "Should fail when no property given", ->
    logData = ['first entry', 'second entry', 'third entry']

    model.log '', logData[0]
    model.log null, logData[1]

    expect(model.__get__('_store').log).toBeUndefined()

  it "Should log empty line", ->
    logData = ['first entry', '', null, false]

    for line in logData
      model.log 'log', line

    expect(model.__get__('_store').log).toEqual(logData)

# @todo missing functional test (watchAndEmitProperty)
describe 'set', ->

  beforeEach ->
    model = rewire "../../../../models/stores/watcher.coffee"
    model.__set__ '_store', cloneObject data

  it "Should set string", ->
    val = 'new value'

    model.set 'new', val
    expect(model.__get__('_store').new).toBe(val)

  it "Should set boolean", ->
    model.set 'newFalse', false
    model.set 'newTrue', true

    expect(model.__get__('_store').newFalse).toBe(false)
    expect(model.__get__('_store').newTrue).toBe(true)

  it "Should set null", ->
    model.set 'new1', null
    model.set 'new2'

    expect(model.__get__('_store').new1).toBeNull()
    expect(model.__get__('_store').new2).toBeNull()

  it "Should set object", ->
    val = {"k1": "v1", "k2": "v2"}

    model.set 'newObj', val
    expect(model.__get__('_store').newObj).toBe(val)

  it "Should set array", ->
    val = ["v1", "v2"]

    model.set 'newAr', val
    expect(model.__get__('_store').newAr).toBe(val)

  it "Should overwrite existing property", ->
    val = 'new value'

    model.set 'string', "first"
    model.set 'string', val

    expect(model.__get__('_store').string).toBe(val)

  it "Should fail when no property given", ->
    expect(model.set '', 'something').toBeFalsy()
    expect(model.set null, 'something').toBeFalsy()


describe 'setChildProperty', ->

  beforeEach ->
    model = rewire "../../../../models/stores/watcher.coffee"
    model.__set__ '_store', cloneObject data
    spyOn(model, 'set').andCallThrough()

  it 'Should set string', ->
    val = 'something'

    model.setChildProperty 'object', 'new', val

    expect(model.__get__('_store').object.new).toBe(val)

  it "Should set boolean", ->
    model.setChildProperty 'object', 'newFalse', false
    model.setChildProperty 'object', 'newTrue', true

    expect(model.__get__('_store').object.newFalse).toBe(false)
    expect(model.__get__('_store').object.newTrue).toBe(true)

  it "Should set null", ->
    model.setChildProperty 'object', 'new1', null
    model.setChildProperty 'object', 'new2'

    expect(model.__get__('_store').object.new1).toBeNull()
    expect(model.__get__('_store').object.new2).toBeNull()

  it "Should set object", ->
    val = {"k1": "v1", "k2": "v2"}

    model.setChildProperty 'object', 'newObj', val
    expect(model.__get__('_store').object.newObj).toBe(val)

  it "Should set array", ->
    val = ["v1", "v2"]

    model.setChildProperty 'object', 'newAr', val
    expect(model.__get__('_store').object.newAr).toBe(val)

  it "Should overwrite existing property", ->
    val = 'new value'

    model.setChildProperty 'object', 'string', "first"
    model.setChildProperty 'object', 'string', val

    expect(model.__get__('_store').object.string).toBe(val)

  it "Should work with arrays", ->
    val = 'something'

    model.setChildProperty 'array', 'new', val

    model.setChildProperty 'array', 'string', "first"
    model.setChildProperty 'array', 'string', val

    expect(model.__get__('_store').array.new).toBe(val)
    expect(model.__get__('_store').array.string).toBe(val)

  it "Should fail when no property or childname given", ->
    expect(model.setChildProperty '', 'something', 'something').toBeFalsy()
    expect(model.setChildProperty null, 'something', 'something').toBeFalsy()

    expect(model.setChildProperty 'object', '', 'something').toBeFalsy()
    expect(model.setChildProperty 'object', null, 'something').toBeFalsy()

  it "should fail when property is not an object or array", ->
    expect(model.setChildProperty 'string', 'something', 'something').toBeFalsy()


  # functional tests

  it 'Should not call set() when object exists', ->
    val = 'something'

    model.setChildProperty 'object', 'new', val

    expectedObject = data
    expectedObject.object.new = val

    expect(model.set.callCount).toBe(0)

  it 'Should call set() when object does not exist', ->
    val = 'something'

    model.setChildProperty 'newObject', 'new', val

    expect(model.set).toHaveBeenCalledWith 'newObject', {"new": val}

#@todo use case? fails + improve testing
describe 'unset', ->

  beforeEach ->
    model = rewire "../../../../models/stores/watcher.coffee"
    model.__set__ '_store', cloneObject data

#  it 'Should remove property from store', ->
#    model.unset 'object'
#
#    expect(model.__get__('_store').object).toBeUndefined()

  it "Should return true if undefined", ->
    expect(model.unset 'notExistend').toBeTruthy()

  it "Should fail when no property given", ->
    expect(model.unset '').toBeFalsy()
    expect(model.unset null).toBeFalsy()

#@todo use cases? improve testing
describe 'toKefir', ->

  beforeEach ->
    model = rewire "../../../../models/stores/watcher.coffee"
    model.__set__ '_store', cloneObject data

  it "should return observable", ->
    expect(model.toKefir()).toEqual(jasmine.any(Object))

#@todo use cases? improve testing
describe 'propertyToKefir', ->

  beforeEach ->
    model = rewire "../../../../models/stores/watcher.coffee"
    model.__set__ '_store', cloneObject data

  it "should return observable", ->
    expect(model.propertyToKefir('object')).toEqual(jasmine.any(Object))