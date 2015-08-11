_r = require 'kefir'
config = require 'config'

appConfig = config.get 'app'

vagrantFileModel = require '../vagrant/file.coffee'
vagrantRunModel = require '../vagrant/run.coffee'

defaultStates =
  vagrantFile: false
  vagrantRun: false
  running: false
  failed: false
  errorMessage: null
  state: null

states = JSON.parse(JSON.stringify(defaultStates));

model = {};
model.getState = () ->
  states.datetime = new Date()
  return states

# 1 reset states
# 2 run setup again
model.restart = () ->
  return false if states.state == "running"
  states = JSON.parse(JSON.stringify(defaultStates));
  model.run()

# 1 check vagrant file
# 2 start and monitor vagrant
# 3 profit
model.run = () ->
  return false if states.state == "running"
  states.state = "running"

  return _r
  .fromNodeCallback (cb) ->
    vagrantFileModel.install cb
  .flatMap () ->
    states.vagrantFile = true
    return _r
    .fromNodeCallback (cb) ->
      return cb 'test'
      vagrantRunModel.run cb
  .onValue () ->
    states.vagrantRun = true
    states.running = true
  .onError (err) ->
    states.vagrantFile = "failed" if states.vagrantFile == false
    states.vagrantRun = "failed" if states.vagrantRun == false
    states.errorMessage = err.message
    states.failed = true
  .onEnd () ->
    states.state = "done"

module.exports = model;