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
    expect(model.__get__('_store').newObj).toEqual(val)

  it "Should set array", ->
    val = ["v1", "v2"]

    model.set 'newAr', val
    expect(model.__get__('_store').newAr).toEqual(val)

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
    expect(model.__get__('_store').object.newObj).toEqual(val)

  it "Should set array", ->
    val = ["v1", "v2"]

    model.setChildProperty 'object', 'newAr', val
    expect(model.__get__('_store').object.newAr).toEqual(val)

  it "Should overwrite existing property", ->
    val = 'new value'

    model.setChildProperty 'object', 'string', "first"
    model.setChildProperty 'object', 'string', val

    expect(model.__get__('_store').object.string).toBe(val)

  it "Should fail when no property or childname given", ->
    expect(model.setChildProperty '', 'something', 'something').toBeFalsy()
    expect(model.setChildProperty null, 'something', 'something').toBeFalsy()

    expect(model.setChildProperty 'object', '', 'something').toBeFalsy()
    expect(model.setChildProperty 'object', null, 'something').toBeFalsy()

  it "should fail when property is not an object", ->
    expect(model.setChildProperty 'string', 'something', 'something').toBeFalsy()
    expect(model.setChildProperty('array', 'new', 'something')).toBeFalsy()


describe 'toKefir', ->

  beforeEach ->
    model = rewire "../../../../models/stores/watcher.coffee"
    model.__set__ '_store', cloneObject data

  it "should return observable", ->
    stream= model.toKefir()

    expect(stream).toEqual(jasmine.any(Object))
    expect(stream.onValue).toEqual(jasmine.any(Function))
    expect(stream.onError).toEqual(jasmine.any(Function))
    expect(stream.onEnd).toEqual(jasmine.any(Function))

  it "should trigger on value event", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.toKefir().onValue onV

    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

    model.set 'testOnValue', 'testing'

  it "should trigger event with setChildProperty", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.toKefir().onValue onV

    model.setChildProperty 'newObject', 'testOnValue', 'test'
    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  #@todo configurable
  it "should not trigger event when same string", (done) ->
    _data = "strings"
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.toKefir().onValue onV

    model.set 'same', _data
    model.set 'same', _data

    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  #@todo configurable
  it "should not trigger event when same boolean", (done) ->
    _data = true
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.toKefir()
    .onValue onV

    model.set 'same', _data
    model.set 'same', _data

    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  #@todo configurable
  it "should not trigger event when same object", (done) ->
    _data = {key: 'val', key2: 'val2'}
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.toKefir()
    .onValue onV

    model.set 'same', _data
    model.set 'same', _data

    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  #@todo configurable
  it "should not trigger event when same array", (done) ->
    _data = ["test", {"test": "test"}]
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.toKefir()
    .onValue onV

    model.set 'same', _data
    model.set 'same', _data

    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  it "should trigger event in deep object", (done) ->
    _data = {key: 'val', key2: 'val2'}
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.toKefir()
    .onValue onV

    model.set 'notSame', _data
    _data.key = 'v3'
    model.set 'notSame', _data

    setTimeout ->
      expect(onV.callCount).toBe(2)
      done()
    , 0

  it "should not trigger event when setting undefined on non existing property", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.toKefir()
    .onValue onV

    model.set 'same'
    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  it "should trigger event after setting undefined on existing property", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.toKefir()
    .onValue onV

    model.set 'same'
    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  it "event value should contain property name, oldValue, newValue", (done) ->
    model.toKefir()
    .onValue (val) ->
      expect(val.hasOwnProperty("name")).toBeTruthy()
      expect(val.hasOwnProperty("oldValue")).toBeTruthy()
      expect(val.hasOwnProperty("newValue")).toBeTruthy()
      done()

    model.set 'testOnValue', 'testing'

  it "should return correct property", (done) ->
    name = 'testOnValue'
    value = 'testing'

    model.toKefir()
    .onValue (val) ->
      expect(val.name).toEqual(name)
      expect(val.newValue).toEqual(value)
      expect(val.oldValue).toBeUndefined()
      done()

    model.set name, value

  it "should return correct defined old value", (done) ->
    val1 = 'testing'
    val2 = 'more testing'

    model.toKefir()
    .onValue (val) ->
      return false if val.newValue != val2
      expect(val.oldValue).toEqual(val1)
      done()
    .onValue (val) ->
      setTimeout ->
        model.set 'testOnValue', val2 if val.newValue == val1
      , 1

    model.set 'testOnValue', val1

  it "should listen on all properties", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.toKefir().onValue onV

    model.set 'testOnValue', 'testing'
    model.set 'totallyDifferentProperty', 'more testing'

    setTimeout ->
      expect(onV.callCount).toBe(2)
      done()
    , 0

  it "should trigger event from log", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.toKefir()
    .onValue onV

    model.log 'newLog', 'first line'
    model.log 'newLog', 'second line'

    setTimeout ->
      expect(onV.callCount).toBe(2)
      done()
    , 0

# stream should react exactly as toKefir with the exception that
# this stream only reacts to the given property
describe 'propertyToKefir', ->

  beforeEach ->
    model = rewire "../../../../models/stores/watcher.coffee"
    model.__set__ '_store', cloneObject data

  it "should return observable", ->
    stream=model.propertyToKefir('testOnValue')

    expect(stream).toEqual(jasmine.any(Object))
    expect(stream.onValue).toEqual(jasmine.any(Function))
    expect(stream.onError).toEqual(jasmine.any(Function))
    expect(stream.onEnd).toEqual(jasmine.any(Function))

  it "should trigger event", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.propertyToKefir('testOnValue').onValue onV

    model.set 'testOnValue', 'testing'
    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  it "should not trigger event on other properties", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.propertyToKefir('testOnValue').onValue onV

    model.set 'totallyDifferentProperty', 'test'
    setTimeout ->
      expect(onV.callCount).toBe(0)
      done()
    , 0
