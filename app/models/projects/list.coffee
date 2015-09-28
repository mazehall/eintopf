_r = require 'kefir'
git  = require 'gift'
jetpack = require 'fs-jetpack'
mazehall = require 'mazehall/lib/modules'
fs = require 'fs'
child = require 'child_process'

utilModel = require '../util/'
watcherModel = require '../stores/watcher.coffee'

projects = []

runCmd = (cmd, config, logName, callback) ->
  config = {} if ! config
  output = ''

  sh = 'sh'
  shFlag = '-c'

  if process.platform == 'win32'
    sh = process.env.comspec || 'cmd'
    shFlag = '/d /s /c'
    config.windowsVerbatimArguments = true

  proc = child.spawn sh, [shFlag, cmd], config
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
  return callback new Error 'could not resolve config path' if ! (configModulePath = utilModel.getConfigModulePath())?
  return callback new Error 'invalid or unsupported git url' if !(projectDir = getProjectNameFromGitUrl(gitUrl))?

  jetpack.dirAsync configModulePath
  .then (dir) ->
    dir.dirAsync 'configs'
    .then (dir) ->
      git.clone gitUrl, dir.path(projectDir), (err) ->
        return model.initProject projectDir, callback if ! err
        model.deleteProject {id: projectDir, path: dir.path(projectDir)}, () ->
          return callback new Error err?.message || 'Error: failed to clone gir repository'
  .fail callback

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

    certsPath = jetpack.cwd(projectDir, 'certs').path()
    model.copyCertsToProxyFolder certsPath, (err, result) ->
      return callback null, project if err && err.code == "ENOENT"
      return callback err if err
      callback null, project

model.loadProject = (projectDir, callback) ->
  return callback new Error 'invalid project dir given' if ! projectDir?
  return callback new Error 'could not resolve config path' if ! (configModulePath = utilModel.getConfigModulePath())?

  dst = jetpack.cwd configModulePath, 'configs', projectDir
  dst.readAsync 'package.json', 'json'
  .then (config) ->
    return callback new Error 'package does not seem to be a eintopf project' if ! config.eintopf?

    project = config.eintopf
    jetpack.findAsync dst.path(), {matching: ["README*.{md,markdown,mdown}"], absolutePath: true}, "inspect"
    .then (markdowns) ->
      project['path'] = dst.path()
      project['scripts'] = config.scripts if config.scripts
      project['id'] = config.name
      project['markdowns'] = markdowns

      if ! model.getProject project.id
        projects.push project
      else
        for own d, i of projects
          projects[d] = project if i.id == project.id

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
    x.pkg.eintopf && typeof x.pkg.eintopf is "object"
  .onValue (val) ->
    jetpack.cwd(val.path).findAsync val.path, {matching: ["README*.{md,markdown,mdown}"], absolutePath: true}, "inspect"
    .then (markdowns) ->
      val.pkg.eintopf['path'] = val.path
      val.pkg.eintopf['scripts'] = val.pkg.scripts
      val.pkg.eintopf['id'] = val.pkg.name
      val.pkg.eintopf['markdowns'] = markdowns
      foundProjects.push val.pkg.eintopf
  .onEnd () ->
    projects = foundProjects
    watcherModel.set 'projects:list', projects

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
  runCmd project.scripts["start"], {cwd: project.path}, logName

model.stopProject = (project, callback) ->
  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?
  logName = "res:project:stop:#{project.id}"

  return watcherModel.log logName, "script stop does not exist\n" unless project.scripts["stop"]
  runCmd project.scripts["stop"], {cwd: project.path}, logName

model.updateProject = (project, callback) ->
  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?
  logName = "res:project:update:#{project.id}"

  watcherModel.log logName, ["Start pulling...\n"]
  runCmd "git pull", {cwd: project.path}, logName, (err, result) ->
    return callback err if err
    model.initProject project.path, callback

model.callAction = (project, action, callback) ->
  if callback?
    return callback new Error 'invalid project given' if typeof project != "object" || ! project.path? || ! action?
    return callback new Error 'invalid script name' if project.scripts? or action.script? or project.scripts[action.script]?
  logName = "res:project:action:script:#{project.id}"

  return watcherModel.log logName, "script '#{action.script}' does not exists\n" unless project.scripts[action.script]
  runCmd project.scripts[action.script], {cwd: project.path}, logName

watcherModel.propertyToKefir 'containers:list'
.onValue ->
  for project, index in projects
    ((projectIndex)->
      getRunningProjectContainers project, (containers) ->
        return false if ! projects[projectIndex]
        projects[projectIndex].state = if containers.length > 0 then "running" else "exit"
    )(index)

    watcherModel.set "projects:list", projects
module.exports = model;
