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
  return false if ! self? || ! propertyName?
  watch _store, propertyName, () ->
    self.emit 'change', {name: propertyName, oldValue: _storeOld[propertyName], newValue: _store[propertyName]}
    _storeOld[propertyName] = _store[propertyName]

model = () ->
  events.EventEmitter.call this
util.inherits model, events.EventEmitter

model.prototype.set = (propertyName, value) ->
  return false if ! propertyName?
  value = null if typeof value == "undefined"
  watchAndEmitProperty this, propertyName if typeof _store[propertyName] == "undefined"
  _store[propertyName] = value

# append new values on the property as array
model.prototype.log = (propertyName, value) ->
  return false if ! propertyName?
  this.set propertyName, [] if ! typeIsArray _store[propertyName]
  _store[propertyName].push value

  if linesMax? && _store[propertyName].length > linesMax
    _store[propertyName].shift()

model.prototype.get = (propertyName) ->
  return false if ! propertyName?
  _store[propertyName]

model.prototype.unset = (propertyName) ->
  return false if ! propertyName?
  return true if typeof _store[propertyName] == "undefined"
  unwatch _store, propertyName, () ->
    delete _storeOld[propertyName] if _storeOld[propertyName]?
    delete _store[propertyName]

model.prototype.toKefir = () ->
  _r.fromEvents this, 'change'

model.prototype.propertyToKefir = (propertyName) ->
  _r.fromEvents this, 'change'
  .filter (x) ->
    x if x.name? && x.name == propertyName

module.exports = new model()
