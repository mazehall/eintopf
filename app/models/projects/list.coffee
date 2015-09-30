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
  jetpack.dirAsync projectsPath
  .fail callback
  .then (dir) ->
    git.clone gitUrl, projectDir.path(), (err) ->
      return model.initProject projectDir.path(), callback if ! err
      model.deleteProject {id: projectId, path: projectDir.path()}, () ->
        return callback new Error err?.message || 'Error: failed to clone gir repository'

model.copyCertsToProxyFolder = (path, callback) ->
  return callback new Error 'could not resolve config path' if ! (configModulePath = utilModel.getConfigModulePath())?

  jetpack.cwd configModulePath
  .dirAsync 'proxy'
  .then (dir) ->
    dir.dirAsync 'certs'
    .then (dir) ->
      jetpack.cwd(path).copyAsync '.', dir.path(), {overwrite:true, matching: ['*.crt', '*.key']}
      .then () ->
        callback null, true
  .fail callback

model.removeCertsFromToBeRemovedProject = (path, callback) ->
  return callback new Error 'could not resolve config path' if ! (configModulePath = utilModel.getConfigModulePath())?

  jetpack.cwd(configModulePath).dirAsync 'proxy'
  .then (dir) ->
    dir.dirAsync 'certs'
    .then (dir) ->
      jetpack.listAsync path
      .then (files) ->
        for own i, file of files
          dir.remove file if file.match(/.key$/) || file.match(/.crt$/)
        callback null, true
  .fail callback

model.initProject = (projectDir, callback) ->
  return callback new Error 'invalid project dir given' if ! projectDir

  model.loadProject projectDir, (err, project) ->
    return callback err if err

    projects = watcherModel.get 'projects:list'
    if ! model.getProject project.id
      projects.push project
    else
      for own d, i of projects
        projects[d] = project if i.id == project.id
    watcherModel.set 'projects:list', projects

    certsPath = jetpack.cwd(projectDir, 'certs').path()
    model.copyCertsToProxyFolder certsPath, (err, result) ->
      return callback null, project if err && err.code == "ENOENT"
      return callback err if err
      callback null, project

model.loadProject = (projectDir, callback) ->
  return callback new Error 'invalid project dir given' if ! projectDir?

  dst = jetpack.cwd projectDir
  dst.readAsync 'package.json', 'json'
  .fail callback
  .then (config) ->
    return callback new Error 'package does not seem to be a eintopf project' if ! config?.eintopf

    project = config.eintopf
    jetpack.findAsync dst.path(), {matching: ["README*.{md,markdown,mdown}"], absolutePath: true}, "inspect"
    .then (markdowns) ->
      project['path'] = dst.path()
      project['scripts'] = config.scripts if config.scripts
      project['id'] = config.name
      project['markdowns'] = markdowns
      callback null, project

model.loadProjects = () ->
  return false if ! (projectsPath = utilModel.getProjectsPath())?
  foundProjects = []

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
  .onEnd () ->
    watcherModel.set 'projects:list', foundProjects

model.deleteProject = (project, callback) ->
  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?

  certsPath = jetpack.cwd(project.path, 'certs').path()
  model.removeCertsFromToBeRemovedProject certsPath, (err, result) ->
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
    model.initProject project.path, callback

model.callAction = (project, action, callback) ->
  if callback?
    return callback new Error 'invalid project given' if typeof project != "object" || ! project.path? || ! action?
    return callback new Error 'invalid script name' if project.scripts? or action.script? or project.scripts[action.script]?
  logName = "res:project:action:script:#{project.id}"

  return watcherModel.log logName, "script '#{action.script}' does not exists\n" unless project.scripts[action.script]
  utilModel.runCmd project.scripts[action.script], {cwd: project.path}, logName

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

module.exports = model;
