_r = require 'kefir'
config = require 'config'

appConfig = config.get 'app'

vagrantFsModel = require '../vagrant/fs.coffee'
vagrantRunModel = require '../vagrant/run.coffee'
watcherModel = require '../stores/watcher.coffee'

defaultStates =
  vagrantFile: false
  vagrantRun: false
  running: false
  failed: false
  errorMessage: null
  state: 'setup'

inSetup = false

states = JSON.parse(JSON.stringify(defaultStates));

model = {};
model.getState = () ->
  states.datetime = new Date()
  return states

# 1 reset states
# 2 run setup again
model.restart = () ->
  return false if inSetup
  states = JSON.parse(JSON.stringify(defaultStates));
  model.run()

# 1 check vagrant file
# 2 start and monitor vagrant
# 3 profit
model.run = () ->
  return false if inSetup
  inSetup = true

  return _r
  .fromNodeCallback (cb) ->
    vagrantFsModel.copyVagrantFile cb
  .flatMap () ->
    states.vagrantFile = true
    watcherModel.set 'states:live', states
    return _r
    .fromNodeCallback (cb) ->
      vagrantRunModel.run cb
  .onValue () ->
    states.vagrantRun = true
    states.running = true
    states.state = "cooking"
    watcherModel.set 'states:live', states
  .onError (err) ->
    states.vagrantFile = "failed" if states.vagrantFile == false
    states.vagrantRun = "failed" if states.vagrantRun == false
    states.errorMessage = err.message
    states.failed = true
    watcherModel.set 'states:live', states
  .onEnd () ->
    inSetup = false

module.exports = model;