_r = require 'kefir'
ks = require 'kefir-storage'
DockerEvents = require 'docker-events'

dockerModel = require '.'
dockerListModel = require './list.coffee'

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

#######################
# runtime streams
#

# update inspect running state on die and start container
eventStream
.filter (event) ->
  event?.value?.id && ['die', 'start'].indexOf(event.type) >= 0
.map  (event) ->
  event.container = ks.getChildProperty 'containers:inspect', event.value.id
  event
.filter (event) -> event.container?
.onValue (event) ->
  event.container.running = if event.type == 'start' then true else false
  ks.setChildProperty 'containers:inspect', event.value.id, event.container
  dockerListModel.initApps event.container

# clear inspect data if container was destroyed
eventStream
.filter (event) ->
  event?.value?.id && event.type == 'destroy'
.onValue (event) ->
  ks.setChildProperty 'containers:inspect', event.value.id, null