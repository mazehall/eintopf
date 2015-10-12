_r = require 'kefir'
jetpack = require "fs-jetpack"
asar = require "asar"

utilModel = require "../util/index.coffee"
match = ["id", "index_uuid"]

model = {}
model.needBackup = false
model.restoreBackup = (backupPath, restorePath, callback) ->
  model.needBackup = if jetpack.exists backupPath then false else true
  return callback new Error 'Invalid paths given to restore backup' if ! backupPath || ! restorePath
  return callback new Error "Restoring backup failed due to missing Backup" if ! jetpack.exists backupPath

  packageList = asar.listPackage(backupPath)
  packageFile = packageList.filter (file) ->
    file = file.split "/"
    return file if file and match.indexOf(file[file.length-1]) isnt -1

  return callback new Error 'Restore backup failed due to faulty backup' if packageFile.length == 0

  machineId = asar.extractFile backupPath, packageFile[0].slice 1
  utilModel.machineIdRegistered machineId.toString(), (error) ->
    if error
      return utilModel.removeFileAsync backupPath, ->
        model.needBackup = true
        callback? error

    asar.extractAll backupPath, restorePath
    callback? arguments...

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