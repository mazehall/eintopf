_r = require 'kefir'
git  = require 'gift'
jetpack = require 'fs-jetpack'
fs = require 'fs'
path = require "path"
crypto = require "crypto"
ks = require 'kefir-storage'

utilModel = require '../util/'
customModel = require './customization.coffee'

projectHashes = []

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

model.getProject = (id) ->
  for own d, i of (ks.get('projects:list') || [])
    return i if i.id == id
  return null

model.installProject = (project, callback) ->
  return callback new Error 'Invalid description data' if ! project?.id

  pattern = if project.pattern then true else false
  projectUrl = if pattern then project.patternUrl else project.url
  project.id = project.dirName if ! pattern

  return callback new Error 'Invalid description data' if ! project.id || ! projectUrl
  return callback new Error 'Could not resolve config path' if ! (projectsPath = utilModel.getProjectsPath())?
  return callback new Error 'Project description with this id already exists' if utilModel.isProjectInstalled project.id

  project.path = jetpack.cwd(projectsPath).path(project.id)

  _r.fromPromise jetpack.dirAsync projectsPath
  .flatMap (cb) ->
    _r.fromNodeCallback (cb) ->
      git.clone projectUrl, project.path, cb
  .flatMap -> # do additional pattern stuff if pattern
    return _r.constant true if ! pattern
    _r.fromNodeCallback (cb) ->
      model.patternPostInstall project, cb
  .flatMap -> # reload projects to enforce view update
    _r.fromNodeCallback (cb) ->
      model.loadProjects cb
  .onValue ->
    callback null, project
  .onError (err) ->
    model.deleteProject project, () ->
      return callback new Error err?.message || 'Error: failed to clone git repository'

model.patternPostInstall = (project, callback) ->
  return callback new Error 'Invalid description data' if ! project?.path

  projectDir = jetpack.cwd project.path
  packagePath = projectDir.cwd 'package.json'
  recipe = {}

  _r.fromNodeCallback (cb) ->
    utilModel.loadJsonAsync packagePath.path(), cb
  .map (content) -> # set changed config
    content.name = project.id;
    content.eintopf = {} if ! content.eintopf
    content.eintopf.name = project.name;
    content.eintopf.description = project.description;
    content.eintopf.mediabg = project.mediabg;
    content.eintopf.src = project.src;

    content.eintopf.parent =
      id: project.patternId
      name: project.patternName
      url: project.patternUrl
    recipe = content
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      utilModel.writeJsonAsync packagePath.path(), recipe, cb
  .flatMap -> # remove .git folder
    _r.fromNodeCallback (cb) ->
      utilModel.removeFileAsync projectDir.path('.git'), cb
  .onError callback
  .onValue ->
    callback null, true

model.customizeProject = (project, callback) ->
  return callback new Error 'Invalid description data' if ! project?.id

  _r.fromNodeCallback (cb) ->
    customModel.saveCustomization project, cb
  .flatMap ->
    _r.fromNodeCallback model.loadProjects
  .onError callback
  .onValue (val) ->
    callback null, val

model.loadProject = (projectPath, callback) ->
  return callback new Error 'invalid project dir given' if ! projectPath?
  projectDir = jetpack.cwd projectPath

  packageStream = _r.fromNodeCallback (cb) ->
    utilModel.loadJsonAsync projectDir.path("package.json"), cb
  readMeStream = _r.fromNodeCallback (cb) ->
    utilModel.loadReadme projectPath, (err, result) ->
      return cb null, [] if err
      cb null, result
  certsStream = _r.fromNodeCallback (cb) ->
    utilModel.loadCertFiles projectDir.path("certs"), (err, result) ->
      return cb null, [] if err
      cb null, result
  customStream = _r.fromNodeCallback (cb) ->
    customModel.getProject path.basename(projectPath), (err, result) ->
      return cb null, {} if err
      cb null, result

  _r.zip [packageStream, readMeStream, certsStream, customStream]
  .endOnError()
  .onError callback
  .onValue (result) ->
    config = result[0]
    return callback new Error 'Package does not seem to be a eintopf project' if ! config?.eintopf

    project = config.eintopf
    project['path'] = projectPath
    project['scripts'] = config.scripts if config.scripts
    project['id'] = path.basename(projectPath).toLowerCase()
    project['composeId'] = project.id.replace(/[^a-zA-Z0-9]/ig, "")
    project['readme'] = result[1] || ''

    # use customizations
    project['name'] = result[3].name if result[3]?.name?
    project['description'] = result[3].description if result[3]?.description?
    project['mediabg'] = result[3].mediabg if result[3]?.mediabg?
    project['src'] = result[3].src if result[3]?.src?

    project['hash'] = crypto.createHash("md5").update(JSON.stringify(project)).digest "hex"

    # reuse projects for installed recipes list
    project['local'] = true
    project['installed'] = true

    # keep existing checked states
    (project['state'] = cachedProject.state if cachedProject.name == project.name) for cachedProject in (ks.get('projects:list') || [])

    if result[2]
      for file in (result[2] || [])
        file.host = file.name.slice(0, -4)
    project['certs'] = result[2] if result[2]

    ks.set 'project:detail:' + project.id, project if project.hash != projectHashes[project.id]
    projectHashes[project.id] = project.hash

    callback null, project

# main implementation to load projects
model.loadProjects = (callback) ->
  return false if ! (projectsPath = utilModel.getProjectsPath())?
  foundProjects = []
  projectCerts = []

  _r.stream dirEmitter projectsPath
  .onError () ->
    ks.set 'projects:list', foundProjects
  .filter (project) ->
    project if project.path?
  .flatMap (project) ->
    _r.fromNodeCallback (cb) ->
      model.loadProject project.path, cb
  .onValue (project) ->
    foundProjects.push(project)
    projectCerts = projectCerts.concat project.certs if project.certs
  .onEnd () ->
    foundProjects.sort (a, b) ->
      return -1 if a.name < b.name
      return 1 if a.name > b.name
      return 0;

    ks.set 'projects:certs', projectCerts
    ks.set 'projects:list', foundProjects
    return callback null, [foundProjects, projectCerts] if callback

model.deleteProject = (project, callback) ->
  error = null

  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?
  error = 'Project action already running' if ks.getChildProperty 'locks', 'projects:' + project.id
  logName = "res:project:delete:#{project.id}"

  if error? # log the error when project exists
    ks.log logName, error
    return callback? new Error error

  jetpack.removeAsync project.path
  .fail (error) ->
    callback error
  .then ->
    ks.log logName
    model.loadProjects()
    callback null, true

model.updateProject = (project, callback) ->
  error = null

  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?
  error = 'Project action already running' if ks.getChildProperty 'locks', 'projects:' + project.id
  logName = 'project:log:' + project.id

  if error? # log the error when project exists
    ks.log logName, error
    return callback? new Error error

  ks.setChildProperty 'locks', 'projects:' + project.id, true
  utilModel.runCmd "git pull", {cwd: project.path}, logName, 'git pull', (err, result) ->
    ks.setChildProperty 'locks', 'projects:' + project.id, false
    return callback err if err
    model.loadProjects callback

model.startProject = (projectId, callback) ->
  return model.callAction projectId, 'start', callback

model.stopProject = (projectId, callback) ->
  return model.callAction projectId, 'stop', callback

model.callAction = (projectId, action, callback) -> #@todo one log for one project
  logName = 'project:log:' + projectId
  lock = ['start', 'stop'].indexOf(action) >= 0
  error = null

  return callback? new Error 'Invalid project action' if !projectId || !action || !(project = model.getProject projectId)
  error = 'Project action already running' if ks.getChildProperty 'locks', 'projects:' + projectId
  error = 'Project action undefined' if ! project.scripts?[action]?

  if error? # log the error when project exists
    ks.log logName, error
    return callback? new Error error

  ks.setChildProperty 'locks', 'projects:' + projectId, true if lock
  utilModel.runCmd project.scripts[action], {cwd: project.path}, logName, action, (err, result) ->
    ks.setChildProperty 'locks', 'projects:' + projectId, false if lock
    callback? err, result

module.exports = model;
