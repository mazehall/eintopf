_r = require 'kefir'
config = require 'config'

appConfig = config.get 'app'

vagrantFileModel = require '../vagrant/file.coffee'
vagrantRunModel = require '../vagrant/run.coffee'

states =
  vagrantFile: false
  vagrantRun: false
  running: false
  failed: false


model = {};
model.getState = () ->
  states.datetime = new Date()
  return states

# 1 check vagrant file
# 2 start and monitor vagrant
# 3 profit
model.run = () ->
  return _r
  .fromNodeCallback (cb) ->
    vagrantFileModel.install cb
  .flatMap () ->
    states.vagrantFile = true
    return _r
    .fromNodeCallback (cb) ->
      vagrantRunModel.run cb
  .onValue (val) ->
    states.vagrantRun = true
    states.running = true
    console.log 'setup on value', val
  .onError (err) ->
    states.failed = true

module.exports = model;