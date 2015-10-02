_r = require 'kefir'
git  = require 'gift'
jetpack = require 'fs-jetpack'
mazehall = require 'mazehall/lib/modules'
fs = require 'fs'
child = require 'child_process'

utilModel = require '../util/'
watcherModel = require '../stores/watcher.coffee'
watcherModel.set 'projects:list', []

getRunningProjectContainers = (project, callback) ->
  return callback [] unless project.path?
  dataset = ""
  process = child.exec "docker-compose ps", {cwd: project.path}
  process.stdout.on "data",(buffer) ->
    dataset += buffer.toString()

  process.on "close", ->
    dataset = dataset.split(/\n/).slice 2
    running = dataset.filter (name) ->
      return name.match(/^\w+/) if name.match /Up /

    callback running if callback?

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
  return watcherModel.get 'projects:list'

model.getProject = (id) ->
  for own d, i of watcherModel.get 'projects:list'
    return i if i.id == id
  return null

model.installProject = (gitUrl, callback) ->
  return callback new Error 'could not resolve config path' if ! (projectsPath = utilModel.getProjectsPath())?
  return callback new Error 'invalid or unsupported git url' if !(projectId = utilModel.getProjectNameFromGitUrl(gitUrl))?
  return callback new Error 'Project already exists' if utilModel.isProjectInstalled projectId

  projectDir = jetpack.cwd projectsPath, projectId
  _r.fromPromise jetpack.dirAsync projectsPath
  .flatMap (cb) ->
    _r.fromNodeCallback (cb) ->
      git.clone gitUrl, projectDir.path(), cb
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      return model.loadProject projectDir.path(), cb
  .onValue (project) ->
    model.loadProjects () ->
      callback null, project
  .onError (err) ->
    model.deleteProject {id: projectId, path: projectDir.path()}, () ->
      return callback new Error err?.message || 'Error: failed to clone git repository'

model.loadProject = (projectPath, callback) ->
  return callback new Error 'invalid project dir given' if ! projectPath?
  projectDir = jetpack.cwd projectPath

  packageStream = _r.fromNodeCallback (cb) ->
    utilModel.loadJsonAsync projectDir.path("package.json"), cb
  markDownStream = _r.fromNodeCallback (cb) ->
    utilModel.loadMarkdowns projectPath, (err, result) ->
      return cb null, [] if err
      cb null, result
  certsStream = _r.fromNodeCallback (cb) ->
    utilModel.loadCertFiles projectDir.path("certs"), (err, result) ->
      return cb null, [] if err
      cb null, result

  _r.zip [packageStream, markDownStream, certsStream]
  .endOnError()
  .onError callback
  .onValue (result) ->
    config = result[0]
    return callback new Error 'Package does not seem to be a eintopf project' if ! config?.eintopf

    project = config.eintopf
    project['path'] = projectPath
    project['scripts'] = config.scripts if config.scripts
    project['id'] = config.name
    project['markdowns'] = result[1] if result[1]

    if result[2]
      for file in result[2]
        file.host = file.name.slice(0, -4)
    project['certs'] = result[2] if result[2]

    callback null, project

# main implementation to load projects
model.loadProjects = (callback) ->
  return false if ! (projectsPath = utilModel.getProjectsPath())?
  foundProjects = []
  projectCerts = []

  _r.stream dirEmitter projectsPath
  .onError () ->
    watcherModel.set 'projects:list', foundProjects
  .filter (project) ->
    project if project.path?
  .flatMap (project) ->
    _r.fromNodeCallback (cb) ->
      model.loadProject project.path, cb
  .onValue (project) ->
    foundProjects.push(project)
    projectCerts = projectCerts.concat project.certs if project.certs
  .onEnd () ->
    watcherModel.set 'projects:certs', projectCerts
    watcherModel.set 'projects:list', foundProjects
    return callback null, [foundProjects, projectCerts] if callback

model.deleteProject = (project, callback) ->
  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?

  jetpack.removeAsync project.path
  .fail (error) ->
    callback error
  .then ->
    watcherModel.log 'res:project:delete:' + project.id
    model.loadProjects()
    callback null, true

model.startProject = (project, callback) ->
  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?
  logName = "res:project:start:#{project.id}"

  return watcherModel.log logName, "script start does not exist\n" unless project.scripts["start"]
  utilModel.runCmd project.scripts["start"], {cwd: project.path}, logName

model.stopProject = (project, callback) ->
  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?
  logName = "res:project:stop:#{project.id}"

  return watcherModel.log logName, "script stop does not exist\n" unless project.scripts["stop"]
  utilModel.runCmd project.scripts["stop"], {cwd: project.path}, logName

model.updateProject = (project, callback) ->
  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?
  logName = "res:project:update:#{project.id}"

  watcherModel.log logName, ["Start pulling...\n"]
  utilModel.runCmd "git pull", {cwd: project.path}, logName, (err, result) ->
    return callback err if err
    model.loadProjects callback

model.callAction = (project, action, callback) ->
  if callback?
    return callback new Error 'invalid project given' if typeof project != "object" || ! project.path? || ! action?
    return callback new Error 'invalid script name' if project.scripts? or action.script? or project.scripts[action.script]?
  logName = "res:project:action:script:#{project.id}"

  return watcherModel.log logName, "script '#{action.script}' does not exists\n" unless project.scripts[action.script]
  utilModel.runCmd project.scripts[action.script], {cwd: project.path}, logName

module.exports = model;


watcherModel.propertyToKefir 'containers:list'
.onValue ->
  projects = watcherModel.get 'projects:list'
  for project, index in projects
    ((projectIndex)->
      getRunningProjectContainers project, (containers) ->
        return false if ! projects[projectIndex]
        projects[projectIndex].state = if containers.length > 0 then "running" else "exit"
    )(index)

    watcherModel.set "projects:list", projects

# monitor certificate changes and sync them accordingly
_r.merge [watcherModel.propertyToKefir('projects:certs'), watcherModel.propertyToKefir('proxy:certs')]
.throttle 1000
.onValue (val) ->
  return false if ! (proxyCertsPath = utilModel.getProxyCertsPath())?
  projectCerts = if val.name == 'projects:certs' then val.newValue else watcherModel.get 'projects:certs'

  utilModel.syncCerts proxyCertsPath, projectCerts, ->

# reload projects every minute
projectsEventStream = _r.interval(60000, 'reload')
.onValue () ->
  model.loadProjects()