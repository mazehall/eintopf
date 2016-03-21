_r = require 'kefir'
jetpack = require "fs-jetpack"

utilModel = require "../util/index.coffee"

winVBoxManagePath = 'C:\\Program Files\\Oracle\\VirtualBox\\VBoxManage.exe' # keep slashes

model = {}

# checks that machine actually exists in virtual box if not try to restore it
model.checkAndRestoreMachineId = (machineId, callback) ->
  _r.fromNodeCallback (cb) -> model.getMachine machineId, cb
  .onError (err) -> # restore only on virtual box error
    return model.restoreIdFromMachineFolder callback if err?.message.match /^VBoxManage/
    return callback err
  .onValue ->
    return callback null, true

model.getMachine = (machineId, callback) ->
  cmdParams = "showvminfo --machinereadable " + machineId

  _r.fromNodeCallback (cb) -> # cmd response only positive when machine exists
    utilModel.runCmd 'VBoxManage ' + cmdParams, null, null, (err, result) ->
      if process.platform == "win32" && err
        return utilModel.runCmd '""' + winVBoxManagePath + '" ' + cmdParams + '"', null, null, cb
      cb err, result
  .map (resultString) ->
    result = {}
    return result if ! resultString
    for line in resultString.split(/\r?\n/)
      val = line.split("=")
      result[val[0]] = if typeof val[1] == "string" then val[1].replace(/^"/g, '').replace(/"$/g, '') else null
    result
  .onError callback
  .onValue (result) ->
    callback null, result

# get the machine from the machine folder name
# also adds the absolutePath property
model.getMachineFromMachineFolder = (callback) ->
  _r.fromNodeCallback (cb) -> model.getOnlyVirtualBoxDir cb
  .flatMap (dir) ->
    return _r.fromNodeCallback (cb) ->
      model.getMachine dir.name, (err, result) ->
        return cb err if err
        result['absolutePath'] = dir.absolutePath
        result['idFilePath'] = jetpack.cwd(dir.absolutePath, "virtualbox", "id").path()
        cb null, result
  .onError callback
  .onValue (val) ->
    callback null, val

# get current virtual box dir. There is currently only one supported.
# So if there actually are multiple one its an error!
model.getOnlyVirtualBoxDir = (callback) ->
  return callback new Error "Invalid config path" if ! (configPath = utilModel.getConfigModulePath())

  configDir = jetpack.cwd configPath

  _r.fromPromise jetpack.findAsync configDir.path(), {matching: ["./.vagrant/machines/*"]}, "inspect"
  .flatMap (folders) ->
    _r.fromNodeCallback (cb) ->
      return cb new Error "can't maintain integrity with multiple machine folders" if folders.length != 1
      cb null, folders[0]
  .onError callback
  .onValue (val) ->
    callback null, val

# restore the id file with the name of the machine folder
model.restoreIdFromMachineFolder = (callback) ->
  _r.fromNodeCallback (cb) ->
    model.getMachineFromMachineFolder cb
  .flatMap (machine) -> # machine from getMachineFromMachineFolder has the additional absolutePath property
    return _r.fromNodeCallback (cb) ->
      return callback new Error 'invalid machine given' if ! machine.idFilePath
      utilModel.writeFile machine.idFilePath, machine.UUID, cb
  .onError callback
  .onValue ->
    return callback null, true

# check that the machine is consistent if not start restoring
model.checkMachineConsistency = (callback) ->
  _r.fromNodeCallback (cb) ->
    model.getOnlyVirtualBoxDir cb
  .flatMap (dir) ->
    _r.fromPromise jetpack.readAsync jetpack.cwd(dir.absolutePath, "virtualbox", "id").path()
  .flatMap (id) ->
    return _r.fromNodeCallback (cb) ->
      return model.checkAndRestoreMachineId id, cb if id # check that current id is actually in use ...
      model.restoreIdFromMachineFolder cb # ... otherwise restore
  .onError callback
  .onValue ->
    return callback null, true

model.enumerateGuestProperties = (machineId, callback) ->
  cmdParams = "guestproperty enumerate " + machineId

  return _r.fromNodeCallback (cb) ->
    utilModel.runCmd 'VBoxManage ' + cmdParams, null, null, cb
  .flatMapErrors (err) ->
    return _r.constantError err if process.platform != "win32"
    _r.fromNodeCallback (cb) ->
      return utilModel.runCmd '""' + winVBoxManagePath + '" ' + cmdParams + '"', null, null, cb
  .onError callback
  .onValue (val) ->
    callback null, val

model.getGuestIps = (callback) ->
  _r.fromNodeCallback model.getOnlyVirtualBoxDir
  .flatMap (dir) ->
    _r.fromNodeCallback (cb) ->
      model.enumerateGuestProperties dir.name, cb
  .map (config) ->
    ips = []
    return ips if !(matched = config.match (/IP, value: (.*?),/g))

    for match in matched
      ips.push ip[1] if (ip = match.match (/IP, value: (.*?),/)) && ip[1]
    ips
  .onError callback
  .onValue (val) ->
    callback null, val

module.exports = model;
