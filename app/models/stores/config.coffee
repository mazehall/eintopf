config = require 'config'
jetpack = require 'fs-jetpack'

appConfig = config.get 'app'
mergedConfig = config

getPathResolvedWithRelativeHome = (fsPath) ->
  return null if typeof fsPath != "string"
  homePath = getEintopfHome()
  fsPath = fsPath.replace /^(~|~\/)/, homePath if homePath?
  return fsPath

getEintopfHome = () ->
  return process.env.EINTOPF_HOME if process.env.EINTOPF_HOME
  return process.env.USERPROFILE if process.platform == 'win32'
  return process.env.HOME

getConfigPath = () ->
  return getPathResolvedWithRelativeHome "#{getEintopfHome()}/.eintopf";

getConfigModulePath = () ->
  return null if ! (configPath = getConfigPath())? || ! appConfig.defaultNamespace
  return jetpack.cwd(configPath).path appConfig.defaultNamespace

loadAndMergeUserConfig = () ->
  return false if ! (configModulePath = getConfigModulePath())

  try
    userConfig = jetpack.cwd configModulePath
    .read 'config.json', 'json'
  catch e
    console.log 'failed to parse user configuration', e
  return false if !userConfig

  mergedConfig = {}
  config.util.extendDeep mergedConfig, config, userConfig
  config.util.attachProtoDeep mergedConfig
  config.util.runStrictnessChecks mergedConfig
  config.util.makeImmutable mergedConfig

loadAndMergeUserConfig()
module.exports = mergedConfig