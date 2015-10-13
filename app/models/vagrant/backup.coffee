_r = require 'kefir'
jetpack = require "fs-jetpack"
asar = require "asar"

utilModel = require "../util/index.coffee"
match = ["id", "index_uuid"]

model = {}
model.needBackup = false
model.restoreMachineId = (backupPath, restorePath, callback) ->
  utilModel.fetchEintopfMachineId (error, uuid, name) ->
    return callback? error if error

    structure = ["machines", name, "virtualbox"];
    machineId = jetpack.cwd restorePath
    writePath = "#{machineId.path()}/#{structure.join('/')}"
    machineId = machineId.dir path for path in structure if not jetpack.exists writePath

    write = jetpack.writeAsync "#{writePath}/id", uuid, {atomic: true}
    write.then -> callback? null, true
    write.fail -> callback? arguments...

model.restoreBackup = (backupPath, restorePath, callback) ->
  model.needBackup = if jetpack.exists backupPath then false else true
  return callback new Error 'Invalid paths given to restore backup' if ! backupPath || ! restorePath
  return callback new Error "Restoring backup failed due to missing Backup" if ! jetpack.exists backupPath

  removeBackup = ->
    model.needBackup = true
    utilModel.removeFileAsync backupPath, -> callback? new Error 'Restore backup failed due to faulty backup' if jetpack.exists backupPath

  restoreBackup = ->
    asar.extractAll backupPath, restorePath
    callback? null, true

  restoreMachineId = ->
    model.needBackup = true
    model.restoreMachineId backupPath, restorePath, (error) ->
      removeBackup()
      callback? error, true

  packageList = asar.listPackage(backupPath)
  packageFile = packageList.filter (file) ->
    file = file.split "/"
    return file if file and match.indexOf(file[file.length-1]) isnt -1

  return restoreMachineId() if packageFile.length is 0

  # restore backup when archived id is registered in virtualbox
  machineId = asar.extractFile backupPath, packageFile[0].slice 1
  utilModel.machineIdRegistered machineId.toString(), (error) ->
    return restoreMachineId() if error
    return restoreBackup()

model.createBackup = (backupPath, restorePath, callback) ->
  return callback new Error 'Invalid paths given to create backup' if ! backupPath || ! restorePath

  asar.createPackage restorePath, backupPath, ->
    return callback null, true

model.checkBackup = (callback) ->
  return callback new Error "backup failed: invalid config path" if ! (configPath = utilModel.getConfigModulePath())

  vagrantFolder = jetpack.cwd configPath, ".vagrant"
  vagrantBackup = jetpack.cwd configPath, ".vagrant.backup"

  # fails when vagrantFolder does not exist aka when vagrant was destroyed
  _r.fromPromise jetpack.findAsync vagrantFolder.path(), {matching: match}, "inspect"
  .flatMap (files) ->
    return _r.fromNodeCallback (cb) ->
      return model.restoreBackup vagrantBackup.path(), vagrantFolder.path(), cb if files.length != match.length
      model.createBackup vagrantBackup.path(), vagrantFolder.path(), cb
  .onError callback
  .onValue () ->
    callback null, true

module.exports = model;