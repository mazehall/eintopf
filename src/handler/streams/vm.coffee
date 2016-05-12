_r = require 'kefir'
ks = require 'kefir-storage'

vagrantRunModel = require '../../models/vagrant/run.coffee'


beat = _r.interval 1000, 'tick'
stream = _r.pool()


model = {}

model.enable = ->
  stream.plug(beat) if stream._isEmpty()

model.disable = ->
  stream.unplug(beat) if ! stream._isEmpty()


# monitors vm state
stream.throttle 10000
.flatMap ->
  _r.fromNodeCallback (cb) ->
    vagrantRunModel.getStatus cb
.onError ->
  ks.setChildProperty 'states:live', 'vagrant', false
.onValue (val) ->
  ks.setChildProperty 'states:live', 'vagrant', val

module.exports = model