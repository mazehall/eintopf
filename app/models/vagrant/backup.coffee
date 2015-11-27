_r = require 'kefir'
jetpack = require "fs-jetpack"
asar = require "asar"
spawn = require('child_process').spawn

utilModel = require "../util/index.coffee"
match = ["id", "index_uuid"]

model = {}
model.needBackup = false
model.restoreMachineId = (backupPath, restorePath, callback) ->
  @fetchEintopfMachineId (error, uuid, name) ->
    return callback? error if error

    structure = ["machines", name, "virtualbox"];
    restoreDir = jetpack.cwd restorePath
    writePath = "#{restoreDir.path()}/#{structure.join('/')}"

    if asar.listPackage(backupPath).join().indexOf("machines/#{name}/virtualbox/private_key") isnt -1
      hasPrivatekey = asar.extractFile backupPath, "machines/#{name}/virtualbox/private_key"
      jetpack.writeAsync "#{writePath}/private_key", hasPrivatekey, {atomic: true}

    write = jetpack.writeAsync "#{writePath}/id", uuid, {atomic: true}
    write.then -> callback? null, true
    write.fail -> callback? new Error 'restoring machine id failed'

model.restoreBackup = (backupPath, restorePath, callback) ->
  model.needBackup = if jetpack.exists backupPath then false else true
  return callback new Error 'Invalid paths given to restore backup' if ! backupPath || ! restorePath
  return callback new Error "Restoring backup failed due to missing Backup" if ! jetpack.exists backupPath

  removeBackup = ->
    model.needBackup = true
    utilModel.removeFileAsync backupPath, -> return if jetpack.exists backupPath

  restoreBackup = ->
    asar.extractAll backupPath, restorePath
    callback? null, true

  restoreMachineId = ->
    model.needBackup = true
    model.restoreMachineId backupPath, restorePath, (error) ->
      removeBackup()
      error = new Error 'Restore backup failed due to faulty backup' if error
      callback? error, true

  packageList = asar.listPackage(backupPath)
  packageFile = packageList.filter (file) ->
    file = file.split "/"
    return file if file and match.indexOf(file[file.length-1]) isnt -1

  return restoreMachineId() if packageFile.length is 0

  # restore backup when archived id is registered in virtualbox
  machineId = asar.extractFile backupPath, packageFile[0].slice 1
  @machineIdRegistered machineId.toString(), (error) ->
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


model.machineIdRegistered = (uuid, callback) ->
  stdout = ""
  stderr = ""

  proc = spawn "VBoxManage", ["showvminfo", "--machinereadable", uuid]
  proc.on 'error', (err) ->
    return callback? null, false
  proc.on "close", ->
    error = if stderr then new Error stderr else null
    callback? error, stdout
  proc.stdout.on "data", (chunk) -> stdout += chunk.toString()
  proc.stderr.on "data", (chunk) -> stderr += chunk.toString()
  proc

model.fetchEintopfMachineId = (callback) ->
  vagrantPath = "#{utilModel.getConfigModulePath()}/.vagrant"
  machineName = jetpack.find vagrantPath, {matching: ["machines/*"]}, "inspect"
  #@todo multiple folders support??
  machineName = machineName?[0]?.name

  return callback new Error "No machine or vagrant directory found" if ! machineName

  loadMachineId = _r.fromNodeCallback (cb) -> model.machineIdRegistered machineName, cb
  loadMachineId.onError callback
  loadMachineId.onValue (stdout) ->
    machineId = (match = stdout.match /uuid="(.*)"/i) and match?.length is 2 and match[1]
    return callback null, machineId, machineName, stdout


module.exports = model;