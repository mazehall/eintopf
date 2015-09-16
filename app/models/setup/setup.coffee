_r = require 'kefir'
config = require '../stores/config'

appConfig = config.get 'app'
utilModel = require "../util"
jetpack = require "fs-jetpack"
asar = require "asar"
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

watchVagrantSshConfigAndSetIt = () ->
  _r.withInterval 5000, (emitter) ->
    vagrantRunModel.getSshConfig (err, result) ->
      return emitter.error err if err
      emitter.emit result
  .onValue (val) ->
    watcherModel.setProperty 'settings:list', 'vagrantSshConfig', val
  .onError (err) ->
    watcherModel.setProperty 'settings:list', 'vagrantSshConfig', {}

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

model.checkBackup = () ->
  vagrantFolder = jetpack.cwd "#{utilModel.getConfigModulePath()}/.vagrant"
  vagrantBackup = vagrantFolder.path() + ".backup"
  folderExists  = jetpack.exists vagrantFolder.path()
  backupExists  = jetpack.exists vagrantBackup

  if backupExists and folderExists is false
    console.log "backup:", "vagrant directory does not exists, delete old backup file"

  if folderExists is "dir"
    match = ["id", "index_uuid"]
    files = jetpack.find vagrantFolder.path(), {matching: match}, "inspect"

    if files.length is match.length and backupExists is not "file"
      return asar.createPackage vagrantFolder.path(), vagrantBackup, ->
        console.log "backup:", "vagrant backup created at:", vagrantBackup

    if files.length isnt match.length
      console.log "backup:", "vagrant directory '#{vagrantFolder.path()} is corrupt"

      if backupExists is false or backupExists isnt "file"
        console.log "backup:", "=> no backup found!"
      else
        packageList = asar.listPackage(vagrantBackup)
        packageFile = packageList.filter (file) ->
          file = file.split "/"
          return file if file and match.indexOf(file[file.length-1]) isnt -1

        if packageFile and packageFile.length isnt 0
          asar.extractAll vagrantBackup, vagrantFolder.path()
          console.log "backup:", "=> vagrant directory restored!"
        else
          console.log "backup:", " => invalid backup file, backup deleted!"
          jetpack.remove vagrantBackup

  return model

watchVagrantSshConfigAndSetIt()
module.exports = model;