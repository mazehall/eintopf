_r = require 'kefir'
ks = require 'kefir-storage'

dockerListModel = require '../../models/docker/list.coffee'
dockerProxyModel = require '../../models/docker/proxy.coffee'
dockerEventStream = require '../../models/docker/events.coffee'


beat = _r.interval 1000, 'tick'
stream = _r.pool()


model = {}

model.enable = ->
  stream.plug(beat) if stream._isEmpty()

model.disable = ->
  stream.unplug(beat) if ! stream._isEmpty()


# update docker container list
stream.onValue () ->
  dockerListModel.loadContainers()


###########
# monitor proxy container
stream.throttle 10000
.flatMap () ->
  _r.fromNodeCallback (cb) ->
    dockerProxyModel.monitorProxy cb
.onError (err) ->
  connectCodes = ['ECONNREFUSED', 'ECONNRESET']
  ks.setChildProperty 'states:live', 'proxy', false

  if connectCodes.indexOf(err.code) >= 0
    ks.setChildProperty 'states:live', 'proxyError', 'Cannot connect to docker'
  else
    ks.setChildProperty 'states:live', 'proxyError', err.message
.onValue ->
  ks.setChildProperty 'states:live', 'proxy', true
  ks.setChildProperty 'states:live', 'proxyError', null


# clear inspect data if container was destroyed
dockerEventStream
.filter (event) ->
  event?.value?.id && event.type == 'destroy'
.onValue (event) ->
  ks.setChildProperty 'containers:inspect', event.value.id, null


# update inspect running state on die and start container
dockerEventStream
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


module.exports = model