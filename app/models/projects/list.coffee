_r = require 'kefir'
git  = require 'gift'
jetpack = require 'fs-jetpack'
mazehall = require 'mazehall/lib/modules'
fs = require 'fs'
child = require 'child_process'

utilModel = require '../util/'
watcherModel = require '../stores/watcher.coffee'

projects = []

getProjectNameFromGitUrl = (gitUrl) ->
  return null if !(projectName = gitUrl.match(/^[:]?(?:.*)[\/](.*)(?:s|.git)?[\/]?$/))?
  return projectName[1].substr(0, projectName[1].length-4) if projectName[1].match /\.git$/i
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

model.getProject = (id) ->
  for own d, i of projects
    return i if i.id == id
  return null

model.installProject = (gitUrl, callback) ->
  if ! callback?
    callback = (err, result) ->
      res = {}
      res.errorMessage = err.message if err? && typeof err == 'object'
      res.status = if err then 'error' else 'success'
      watcherModel.set 'res:projects:install', res

  return callback new Error 'could not resolve config path' if ! (configModulePath = utilModel.getConfigModulePath())?
  return callback new Error 'invalid or unsupported git url' if !(projectDir = getProjectNameFromGitUrl(gitUrl))?

  jetpack.dirAsync configModulePath
  .then (dir) ->
    dir.dirAsync 'configs'
    .then (dir) ->
      git.clone gitUrl, dir.path(projectDir), (err) ->
        return callback new Error err.message if err
        model.loadProject projectDir, callback
  .fail (err) ->
    callback err

model.loadProject = (projectDir, callback) ->
  return callback new Error 'invalid project dir given' if ! projectDir?
  return callback new Error 'could not resolve config path' if ! (configModulePath = utilModel.getConfigModulePath())?

  dst = jetpack.cwd configModulePath, 'configs', projectDir
  dst.readAsync 'package.json', 'json'
  .then (config) ->
    return callback new Error 'package does not seem to be a eintopf project' if ! config.eintopf?

    project = config.eintopf
    project['path'] = dst.path()
    project['scripts'] = config.scripts if config.scripts
    project['id'] = config.name

    projects.push project
    watcherModel.set 'projects:list', projects
    callback null, project
  .fail callback

model.loadProjects = () ->
  return false if ! (configModulePath = utilModel.getConfigModulePath())?
  foundProjects = []

  _r.stream dirEmitter jetpack.cwd(configModulePath, 'configs').path()
  .onError () -> #@todo remove in release - this is only for dev
    projects = foundProjects
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
    watcherModel.set 'projects:list', projects

#@todo add project running state
model.startProject = (project, callback) ->
  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?

  process = child.exec 'npm start', {cwd: project.path}
  process.stdout.on 'data',(chunk) ->
    watcherModel.log 'res:project:start:' + project.id, chunk
  process.stderr.on 'data',(chunk) ->
    watcherModel.log 'res:project:start:' + project.id, chunk


model.stopProject = (project, callback) ->
  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?

  process = child.exec 'npm stop', {cwd: project.path}
  process.stdout.on 'data',(chunk) ->
    watcherModel.log 'res:project:stop:' + project.id, chunk
  process.stderr.on 'data',(chunk) ->
    watcherModel.log 'res:project:stop:' + project.id, chunk


module.exports = model;
