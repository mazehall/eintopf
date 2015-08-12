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

model.copyVagrantFile = (cb) ->
  configModulePath = model.getConfigModulePath()
  pathDefaultVagrantFile = appConfig.pathDefaultVagrantFile
  return cb new Error 'copy failed due to misconfiguration' if ! configModulePath? || ! pathDefaultVagrantFile?

  jetpack.readAsync pathDefaultVagrantFile
  .fail cb
  .then (data) ->
    jetpack.dirAsync configModulePath
    .fail cb
    .then (dir) ->
      dir.fileAsync 'Vagrantfile', {content: data}
      .fail cb
      .then () ->
        return cb null, true

module.exports = model;