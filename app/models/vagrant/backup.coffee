_r = require 'kefir'
jetpack = require "fs-jetpack"
asar = require "asar"

utilModel = require "../util/index.coffee"
match = ["id", "index_uuid"]

model = {}
model.restoreBackup = (backupPath, restorePath, callback) ->
  return callback new Error 'Invalid paths given to restore backup' if ! backupPath || ! restorePath
  return callback new Error "Restoring backup failed due to missing Backup" if ! jetpack.exists backupPath

  packageList = asar.listPackage(backupPath)
  packageFile = packageList.filter (file) ->
    file = file.split "/"
    return file if file and match.indexOf(file[file.length-1]) isnt -1

  if packageFile.length == 0 # remove invalid backup
    return utilModel.removeFileAsync backupPath, () ->
      return callback new Error 'Restore backup failed due to faulty backup'

  asar.extractAll backupPath, restorePath
  return callback null, true

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