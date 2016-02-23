_r = require 'kefir'
ks = require 'kefir-storage'

config = require '../stores/config'
vagrantFsModel = require '../vagrant/fs.coffee'
vagrantRunModel = require '../vagrant/run.coffee'
vagrantBackupModel = require '../vagrant/backup.coffee'

appConfig = config.get 'app'

inSetup = false
defaultStates =
  setupVagrantFile: false
  setupVagrantVM: false
  setupError: null
  state: 'setup'


model = {};

model.getVagrantSshConfigAndSetIt = (callback) ->
  _r.fromNodeCallback (cb) -> vagrantRunModel.getSshConfig cb
  .onValue (val) ->
    ks.setChildProperty 'settings:list', 'vagrantSshConfig', val
    callback? null, val

model.run = () ->
  return false if inSetup
  inSetup = true
  states = JSON.parse(JSON.stringify(defaultStates));

  ks.set 'states:live', states # reset states

  _r.fromNodeCallback (cb) -> # deploy vagrant file
    vagrantFsModel.copyVagrantFile cb
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      vagrantBackupModel.checkBackup (err, result) -> cb null, true
  .flatMap () -> # start vagrant
    states.setupVagrantFile = true
    ks.set 'states:live', states

    _r.fromNodeCallback (cb) ->
      vagrantRunModel.run cb
  .flatMap ->
    _r.fromCallback (cb) ->
      model.getVagrantSshConfigAndSetIt cb
  .onValue ->
    ks.setChildProperty 'states:live', 'setupVagrantVM', true
    ks.setChildProperty 'states:live', 'state', 'cooking'
    vagrantBackupModel.checkBackup -> return if vagrantBackupModel.needBackup is true #@todo does not create new backups
  .onError (err) ->
    ks.setChildProperty 'states:live', 'setupVagrantFile', 'failed' if states.setupVagrantFile == false
    ks.setChildProperty 'states:live', 'setupVagrantVM', 'failed' if states.setupVagrantVM == false
    ks.setChildProperty 'states:live', 'setupError', err.message
  .onEnd () ->
    inSetup = false

module.exports = model;