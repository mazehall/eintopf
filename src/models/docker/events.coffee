_r = require 'kefir'
DockerEvents = require 'docker-events'

dockerModel = require '.'

eventStream = _r.pool()


dockerEvents = new DockerEvents {docker: dockerModel.docker}
dockerEvents.start();

dockerEvents.on "create", (message) -> eventStream.plug _r.constant {type: 'create', value: message}
dockerEvents.on "start", (message) -> eventStream.plug _r.constant {type: 'start', value: message}
dockerEvents.on "stop", (message) -> eventStream.plug _r.constant {type: 'stop', value: message}
dockerEvents.on "destroy", (message) -> eventStream.plug _r.constant {type: 'destroy', value: message}
dockerEvents.on "die", (message) -> eventStream.plug _r.constant {type: 'die', value: message}
dockerEvents.on "error", (err) ->
  if err.code == "ECONNRESET" || err.code == "ECONNREFUSED" #try to reconnect after timeout
    setTimeout () ->
      dockerEvents.stop()
      dockerEvents.start()
      eventStream.plug _r.constant {type: 'reconnect'}
    , 10000


module.exports = eventStream
