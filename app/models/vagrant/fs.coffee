config = require 'config'
path = require 'path'
fse = require 'fs-extra'
_r = require 'kefir'

appConfig = config.get 'app'

getHomePath = () ->
  return process.env.USERPROFILE if process.platform == 'win32'
  return process.env.HOME

getResolvedHomePath = (fsPath) ->
  if typeof fsPath == "string" && fsPath.match(/^~/)
    homePath = getHomePath()
    return null if ! homePath?
    fsPath = path.join homePath, fsPath.substr 1
  return fsPath

model = {}
model.getConfigPath = () ->
  configPath = appConfig.configPath
  return null if ! configPath
  return getResolvedHomePath appConfig.configPath

model.getProjectsPath = () ->
  projectPath = appConfig.projectsPath
  return null if ! projectPath
  return getResolvedHomePath projectPath

model.getConfigModulePath = () ->
  configPath = model.getConfigPath()
  return null if ! configPath? || ! appConfig.defaultNamespace
  return path.join configPath, appConfig.defaultNamespace


model.copyVagrantFile = (callback) ->
  configModulePath = model.getConfigModulePath()
  return callback new Error 'copy failed' if ! configModulePath?

  src = path.join process.cwd(), appConfig.pathDefaultVagrantFile
  dst = path.join configModulePath, 'Vagrantfile'

  _r.fromNodeCallback (cb) ->
    fse.ensureDir configModulePath, cb
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      fse.copy src, dst, cb
  .onValue (val) ->
    return callback null, val
  .onError (err) ->
    return callback new Error err


module.exports = model;