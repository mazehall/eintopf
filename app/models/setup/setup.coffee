_r = require 'kefir'
jetpack = require "fs-jetpack"

config = require '../stores/config'
vagrantFsModel = require '../vagrant/fs.coffee'
vagrantRunModel = require '../vagrant/run.coffee'
vagrantSSHModel = require '../vagrant/ssh.coffee'
vagrantIntegrityModel = require '../vagrant/integrity.coffee'
watcherModel = require '../stores/watcher.coffee'

appConfig = config.get 'app'

defaultStates =
  vagrantFile: false
  vagrantRun: false
  running: false
  failed: false
  errorMessage: null
  state: 'setup'

inSetup = false

states = JSON.parse(JSON.stringify(defaultStates));

getVagrantSshConfigAndSetIt = (callback) ->
  _r.fromNodeCallback (cb) -> vagrantSSHModel.getSSHConfig cb
  .onValue (val) ->
    watcherModel.setProperty 'settings:list', 'vagrantSshConfig', val
  .onEnd ->
    callback? null

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
    _r.fromNodeCallback (cb) ->
      vagrantIntegrityModel.checkMachineIntegrity (err, result) -> cb null, true
  .flatMap () ->
    states.vagrantFile = true
    watcherModel.set 'states:live', states
    return _r
    .fromNodeCallback (cb) ->
      vagrantRunModel.run cb
  .flatMap ->
    _r.fromCallback (cb) ->
      getVagrantSshConfigAndSetIt cb
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