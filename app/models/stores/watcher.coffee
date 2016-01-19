WatchJS = require "watchjs"
util = require 'util'
events = require "events"
_r = require 'kefir'
watch = WatchJS.watch
unwatch = WatchJS.unwatch

linesMax = 300

_storeOld = {}
_store = {}

typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

watchAndEmitProperty = (self, propertyName) ->
  return false if !(!!self) || !(!!propertyName)
  watch _store, propertyName, () ->
    self.emit 'change', {name: propertyName, oldValue: _storeOld[propertyName], newValue: _store[propertyName]}
    _storeOld[propertyName] = _store[propertyName]

model = () ->
  events.EventEmitter.call this
  this.setMaxListeners 22
util.inherits model, events.EventEmitter

model.prototype.set = (propertyName, value) ->
  return false if !(!!propertyName)
  value = null if typeof value == "undefined"

  watchAndEmitProperty this, propertyName if typeof _store[propertyName] == "undefined"
  _store[propertyName] = JSON.parse(JSON.stringify(value))

model.prototype.setChildProperty = (propertyName, childName, value) ->
  return false if !(!!propertyName) || !(!!childName) || typeIsArray(_store[propertyName]) || !(typeof _store[propertyName] == "object" || typeof _store[propertyName] == "undefined")
  value = null if typeof value == "undefined"

  if typeof _store[propertyName] == "undefined"
    property = {}
    property[childName] = value
  else
    property = _store[propertyName]
    property[childName] = value

  return this.set propertyName, property

# append new values on the property as array
model.prototype.log = (propertyName, value) ->
  return false if !(!!propertyName)
  return this.set propertyName, [value] if ! typeIsArray _store[propertyName]
  _store[propertyName].push value

  if linesMax? && _store[propertyName].length > linesMax
    _store[propertyName].shift()

# clone objects to avoid unnecessary triggers because setting again after manipulation could trigger multiple change events
model.prototype.get = (propertyName) ->
  return false if !(!!propertyName)
  if typeof _store[propertyName] == "object"
    return JSON.parse(JSON.stringify(_store[propertyName]))
  _store[propertyName]

model.prototype.toKefir = () ->
  _r.fromEvents this, 'change'

model.prototype.propertyToKefir = (propertyName) ->
  return false if !(!!propertyName)
  _r.fromEvents this, 'change'
  .filter (x) ->
    x.name? && x.name == propertyName

module.exports = new model()
