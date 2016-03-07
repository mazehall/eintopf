_r = require 'kefir'
git  = require 'gift'
jetpack = require 'fs-jetpack'
fs = require 'fs'
path = require "path"
crypto = require "crypto"
ks = require 'kefir-storage'

utilModel = require '../util/'
ks.set 'projects:list', []

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
model.getList = () ->
  return ks.get 'projects:list'

model.getProject = (id) ->
  for own d, i of ks.get 'projects:list'
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

model.cloneProject = (project, callback) ->
  return callback new Error 'Invalid description data' if ! project?.patternId || ! project.patternUrl || ! project.id
  return callback new Error 'Could not resolve config path' if ! (projectsPath = utilModel.getProjectsPath())?
  return callback new Error 'Project description with this id already exists' if utilModel.isProjectInstalled project.id

  projectDir = jetpack.cwd projectsPath, project.id
  packagePath = projectDir.cwd('package.json')
  mappedId = project.id.replace(/[^a-zA-Z0-9]/ig, "")

  _r.fromNodeCallback (cb) ->
    git.clone project.patternUrl, projectDir.path(), cb
  .flatMap -> # load project definition
    _r.fromNodeCallback (cb) ->
      utilModel.loadJsonAsync packagePath.path(), cb
  .flatMap (packageData) -> # set changed config
    packageData.name = project.id;
    packageData.eintopf = {} if ! packageData.eintopf
    packageData.eintopf.name = project.name;
    packageData.eintopf.description = project.description;
    packageData.eintopf.mediabg = project.mediabg;
    packageData.eintopf.src = project.src;
    packageData.pattern ={}
    packageData.pattern.id = project.patternId;
    packageData.pattern.name = project.patternName;
    packageData.patternUrl = project.patternUrl;

    _r.fromNodeCallback (cb) ->
      utilModel.writeJsonAsync packagePath.path(), packageData, cb
  .flatMap -> # remove .git folder
    _r.fromNodeCallback (cb) ->
      utilModel.removeFileAsync projectDir.path('.git'), cb
  .flatMap -> # reload projects
    _r.fromNodeCallback (cb) ->
      model.loadProjects cb
  .onError (err) -> # remove files on error
    model.deleteProject {id: mappedId, path: projectDir.path()}, () ->
      return callback new Error err?.message || 'failed to clone project pattern'
  .onValue (val) ->
    project.id = mappedId
    callback null, project


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

  _r.zip [packageStream, readMeStream, certsStream]
  .endOnError()
  .onError callback
  .onValue (result) ->
    config = result[0]
    return callback new Error 'Package does not seem to be a eintopf project' if ! config?.eintopf

    project = config.eintopf
    project['path'] = projectPath
    project['scripts'] = config.scripts if config.scripts
    project['id'] = path.basename(projectPath).replace(/[^a-zA-Z0-9]/ig, "")
    project['readme'] = result[1] || ''
    project['hash'] = crypto.createHash("md5").update(JSON.stringify(config)).digest "hex"

    # keep existing running states
    (project['state'] = cachedProject.state if cachedProject.name == project.name) for cachedProject in ks.get 'projects:list'

    if result[2]
      for file in result[2]
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
  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?

  jetpack.removeAsync project.path
  .fail (error) ->
    callback error
  .then ->
    ks.log 'res:project:delete:' + project.id
    model.loadProjects()
    callback null, true

model.startProject = (project, callback) ->
  return callback? new Error 'invalid project given' if typeof project != "object" || ! project.path?
  logName = "res:project:start:#{project.id}"

  ks.setChildProperty 'locks', 'projects:' + project.id, true

  return ks.log logName, "script start does not exist\n" unless project.scripts?["start"]
  stream = utilModel.runCmd project.scripts["start"], {cwd: project.path}, logName, (err, stdOut) ->
    ks.setChildProperty 'locks', 'projects:' + project.id, false
    callback? err, stdOut

model.stopProject = (project, callback) ->
  return callback? new Error 'invalid project given' if typeof project != "object" || ! project.path?
  logName = "res:project:stop:#{project.id}"

  ks.setChildProperty 'locks', 'projects:' + project.id, true

  return ks.log logName, "script stop does not exist\n" unless project.scripts?["stop"]
  utilModel.runCmd project.scripts["stop"], {cwd: project.path}, logName, (err, stdOut) ->
    ks.setChildProperty 'locks', 'projects:' + project.id, false
    callback? err, stdOut

model.updateProject = (project, callback) ->
  return callback new Error 'invalid project given' if typeof project != "object" || ! project.path?
  logName = "res:project:update:#{project.id}"

  ks.log logName, ["Start pulling...\n"]
  utilModel.runCmd "git pull", {cwd: project.path}, logName, (err, result) ->
    return callback err if err
    model.loadProjects callback

model.callAction = (project, action, callback) ->
  if callback?
    return callback new Error 'invalid project given' if typeof project != "object" || ! project.path? || ! action?
    return callback new Error 'invalid script name' if project.scripts? or action.script? or project.scripts[action.script]?
  logName = "res:project:action:script:#{project.id}"

  return ks.log logName, "script '#{action.script}' does not exists\n" unless project.scripts?[action.script]
  utilModel.runCmd project.scripts[action.script], {cwd: project.path}, logName

module.exports = model;
