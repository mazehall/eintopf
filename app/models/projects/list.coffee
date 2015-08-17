_r = require 'kefir'
git  = require 'gift'
jetpack = require 'fs-jetpack'
mazehall = require 'mazehall/lib/modules'
fs = require 'fs'

vagrantFsModel = require '../vagrant/fs.coffee'

projects = []

getProjectNameFromGitUrl = (gitUrl) ->
  return null if !(projectName = gitUrl.match(/^[:]?(?:.*)[\/](.*)(?:s|.git)[\/]?$/))?
  return projectName[1]

# emit subdirectory content through emitter
dirEmitter = (path) ->
  (emitter) ->
    fs.readdir path, (err, files) ->
      emitter.error err if err
      return false if ! files?

      files.forEach (file) ->
        val =
          module: file
          path: jetpack.cwd(path, file).path()
        emitter.emit(val)
      emitter.end()

model = {};
model.getList = () ->
  return projects

model.installProjectList = (gitUrl, callback) ->
  return callback new Error 'could not resolve config path' if ! (configModulePath = vagrantFsModel.getConfigModulePath())?
  return callback new Error 'invalid or unsupported git url' if !(projectDir = getProjectNameFromGitUrl(gitUrl))?

  jetpack.dirAsync configModulePath
  .then (dir) ->
    dir.dirAsync 'configs'
    .then (dir) ->
      git.clone gitUrl, dir.path(projectDir), (err) ->
        return callback new Error err.message if err
        model.loadProject projectDir, (err) ->
          return callback err if err
          callback null, true
  .fail (err) ->
    callback err

model.loadProject = (projectDir, callback) ->
  return callback new Error 'invalid project dir given' if ! projectDir?
  return callback new Error 'could not resolve config path' if ! (configModulePath = vagrantFsModel.getConfigModulePath())?

  dst = jetpack.cwd configModulePath, 'configs', projectDir
  dst.readAsync 'package.json', 'json'
  .then (config) ->
    return callback new Error 'package does not seem to be a eintopf project' if ! config.eintopf?

    project = config.eintopf
    project['path'] = dst.path()
    project['scripts'] = config.scripts if config.scripts
    project['id'] = config.name

    projects.push project
    callback null, project
  .fail callback

model.loadProjects = () ->
  return false if ! (configModulePath = vagrantFsModel.getConfigModulePath())?
  foundProjects = []

  _r.stream dirEmitter jetpack.cwd(configModulePath, 'configs').path()
  .flatMap mazehall.readPackageJson
  .filter (x) ->
    x.pkg.mazehall && x.pkg.eintopf && typeof x.pkg.eintopf is "object"
  .onValue (val) ->
    val.pkg.eintopf['path'] = val.path
    val.pkg.eintopf['scripts'] = val.pkg.scripts
    val.pkg.eintopf['id'] = val.pkg.name
    foundProjects.push val.pkg.eintopf
  .onEnd () ->
    projects = foundProjects

module.exports = model;