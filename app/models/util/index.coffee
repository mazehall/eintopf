config = require 'config'
jetpack = require 'fs-jetpack'
shell = require 'shell'

appConfig = config.get 'app'

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
  return null if ! (configPath = @getConfigPath())? || ! appConfig.defaultNamespace
  return jetpack.cwd(configPath).path appConfig.defaultNamespace

module.exports.openExternalUrl = (url) ->
  return false if ! url?
  shell.openExternal url