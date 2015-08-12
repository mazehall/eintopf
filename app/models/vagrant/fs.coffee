config = require 'config'
jetpack = require 'fs-jetpack'

appConfig = config.get 'app'

getHomePath = () ->
  return process.env.USERPROFILE if process.platform == 'win32'
  return process.env.HOME

getPathResolvedWithRelativeHome = (fsPath) ->
  return null if typeof fsPath != "string"
  homePath = getHomePath()
  fsPath = fsPath.replace /^(~|~\/)/, homePath if homePath?
  return fsPath

model = {}
model.getConfigPath = () ->
  return null if ! (configPath = appConfig.configPath)?
  return getPathResolvedWithRelativeHome appConfig.configPath

model.getProjectsPath = () ->
  return null if ! (projectPath = appConfig.projectsPath)?
  return getPathResolvedWithRelativeHome projectPath

model.getConfigModulePath = () ->
  return null if ! (configPath = model.getConfigPath())? || ! appConfig.defaultNamespace
  return jetpack.cwd(configPath).path appConfig.defaultNamespace

model.copyVagrantFile = (callback) ->
  configModulePath = model.getConfigModulePath()
  pathDefaultVagrantFile = appConfig.pathDefaultVagrantFile
  return cb new Error 'copy failed due to misconfiguration' if ! configModulePath? || ! pathDefaultVagrantFile?

  src = jetpack.cwd(appConfig.pathDefaultVagrantFile).path()

  jetpack.dirAsync configModulePath
  .then (dir) ->
    jetpack.copyAsync src, dir.path("Vagrantfile"), {overwrite: false}
  .then () ->
    callback null, true
  .fail (err) -> # ignore already exists error
    return callback null, true if typeof err == "object" && err.message.match /^Destination path already exists/
    callback err

module.exports = model;