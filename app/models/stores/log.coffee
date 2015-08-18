_r = require 'kefir'

max_lines = 300

_streams = {}
_logs = {}

detachStream = (name) ->
  if _streams[name]?
    delete _streams[name]

model = {}
model.getStream = (name) ->
  return _streams[name] if (name && _streams[name]?)

model.getLogs = (name) ->
  return _logs[name] if (name && _logs[name]?)

model.fromChildProcess = (name, child, callback) ->
  return callback new Error 'invalid params' if !name? || typeof child != 'object' || child.constructor.name != "ChildProcess"

  log = []

  #@todo check necessity of events exit, close, error
  stream = _r.stream (emitter) ->
    #_emitters[name] = emitter

    child.stdout.on 'data',(chunk) ->
      emitter.emit chunk
    child.stderr.on 'data',(chunk) ->
      emitter.emit chunk
    child.on 'error', (err) ->
      emitter.error err
    child.on 'close', () ->
      emitter.end()
  .onEnd () ->
    detachStream name

  _streams[name] = stream
  _logs[name] = stream
  .slidingWindow max_lines || 300
  .toProperty()
  .log('log stream toproperty')

  callback null, stream

module.exports = model