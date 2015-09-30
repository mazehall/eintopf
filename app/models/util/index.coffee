config = require 'config'
jetpack = require 'fs-jetpack'
spawn = require('child_process').spawn

watcherModel = require '../stores/watcher.coffee'

# use original config first and let it overwrite later with the custom config
module.exports.setConfig = (newConfig) ->
  return false if ! newConfig || typeof newConfig != "object"
  config = newConfig
  return true

module.exports.getPathResolvedWithRelativeHome = (fsPath) ->
  return null if typeof fsPath != "string"
  homePath = @getEintopfHome()
  fsPath = fsPath.replace /^(~|~\/)/, homePath if homePath?
  return fsPath

module.exports.getEintopfHome = () ->
  return process.env.EINTOPF_HOME if process.env.EINTOPF_HOME
  return process.env.USERPROFILE if process.platform == 'win32'
  return process.env.HOME

module.exports.getConfigPath = () ->
  return @getPathResolvedWithRelativeHome "#{@getEintopfHome()}/.eintopf";

module.exports.getConfigModulePath = () ->
  return null if ! (configPath = @getConfigPath())? || ! config?.app?.defaultNamespace
  return jetpack.cwd(configPath).path config.app.defaultNamespace

module.exports.loadUserConfig = (callback) ->
  return callback new Error 'Failed to get config module path' if ! (configModulePath = @getConfigModulePath())
  @loadJson  jetpack.cwd(configModulePath).path('config.json'), callback

module.exports.loadJson = (path, callback) ->
  return callback new Error 'Invalid path' if ! path

  try
    userConfig = jetpack.read path, 'json'
  catch err
    return callback err

  return callback null, userConfig

module.exports.loadJsonAsync = (path, callback) ->
  return callback new Error 'Invalid path' if ! path

  jetpack.readAsync path, 'json'
  .fail callback
  .then (json) ->
    callback null, json

module.exports.runCmd = (cmd, config, logName, callback) ->
  config = {} if ! config
  output = ''

  sh = 'sh'
  shFlag = '-c'

  if process.platform == 'win32'
    sh = process.env.comspec || 'cmd'
    shFlag = '/d /s /c'
    config.windowsVerbatimArguments = true

  proc = spawn sh, [shFlag, cmd], config
  proc.on 'error', (err) ->
    return callback err if callback
  proc.on 'close', (code, signal) ->
    return callback null, output if callback
  proc.stdout.on 'data', (chunk) ->
    watcherModel.log logName, chunk.toString() if logName
    output += chunk.toString()
  proc.stderr.on 'data', (chunk) ->
    watcherModel.log logName, chunk.toString() if logName
    output += chunk.toString()
