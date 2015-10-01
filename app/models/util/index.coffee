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

module.exports.loadCertsFiles = (path, callback) ->
  jetpack.findAsync path, {matching: ['*.crt', '*.key'], absolutePath: true}, "inspect"
  .fail (err) ->
    callback err
  .then (certs) ->
    callback null, certs

module.exports.getProjectsPath = () ->
  return null if ! (configModulePath = @getConfigModulePath())
  return jetpack.cwd(configModulePath).path('configs')

module.exports.getProxyCertsPath = () ->
  return null if ! (configModulePath = @getConfigModulePath())
  return jetpack.cwd(configModulePath).path('proxy/certs')

module.exports.getProjectNameFromGitUrl = (gitUrl) ->
  return null if !(projectName = gitUrl.match(/^[:]?(?:.*)[\/](.*)(?:s|.git)?[\/]?$/))?
  return projectName[1].substr(0, projectName[1].length-4) if projectName[1].match /\.git$/i
  return projectName[1]

module.exports.typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

module.exports.folderExists = (path) ->
  return null if ! path
  return true if jetpack.exists(path) == "dir"
  return false

#@todo refactoring: use clear naming (renaming project|recommendations and not just here)
module.exports.isProjectInstalled = (projectId) ->
  return null if ! projectId || ! (projectsPath = @getProjectsPath())
  return @folderExists jetpack.cwd(projectsPath).path(projectId)

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
