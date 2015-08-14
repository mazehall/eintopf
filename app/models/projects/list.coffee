_r = require 'kefir'
git  = require 'gift'
jetpack = require 'fs-jetpack'
mazehall = require 'mazehall/lib/modules'
fs = require 'fs'

vagrantFsModel = require '../vagrant/fs.coffee'

projects = []
dummyProjects = [
  {
    id: '1',
    name: "Projectproject Item 1",
    desc: "extra beschreibung"
  },
  {
    id: '2',
    name: "Projectproject Item 2",
    desc: "extra beschreibung"
  },
  {
    id: '3',
    name: "Projectproject Item 3",
    desc: "extra beschreibung"
  },
  {
    id: '4',
    name: "Projectproject Item 4",
    desc: "extra beschreibung"
  },
  {
    id: '5',
    name: "Projectproject Item 5",
    desc: "extra beschreibung"
  },
  {
    id: '6',
    name: "Projectproject Item 6",
    desc: "extra beschreibung"
  },
  {
    id: '7',
    name: "Projectproject Item 7",
    desc: "extra beschreibung"
  },
  {
    id: '8',
    name: "Projectproject Item 8",
    desc: "extra beschreibung"
  }
]

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
  return callback new Error 'invalid or unsupported git url' if !(projectName = getProjectNameFromGitUrl(gitUrl))?

  jetpack.dirAsync configModulePath
  .then (dir) ->
    dir.dirAsync 'configs'
    .then (dir) ->
      git.clone gitUrl, dir.path(projectName), (err, result) ->
        model.loadProjects()
        return callback new Error err.message if err
        callback null, true
  .fail (err) ->
    callback err

model.loadProjects = () ->
  return callback new Error 'could not resolve config path' if ! (configModulePath = vagrantFsModel.getConfigModulePath())?
  foundProjects = dummyProjects

  #@todo emit project changes to all connections
  #@todo renaming dbox property to eintopf
  #@todo generate project id (md5?)
  directoryStream = _r.stream dirEmitter jetpack.cwd(configModulePath, 'configs').path()
  packagesStream = directoryStream
  .flatMap mazehall.readPackageJson
  .filter (x) ->
    x.pkg.mazehall && x.pkg.dbox && typeof x.pkg.dbox is "object"
  .onValue (val) ->
    val.pkg.dbox['path'] = val.path
    val.pkg.dbox['scripts'] = val.pkg.scripts
    foundProjects.push val.pkg.dbox
  .onEnd () ->
    projects = foundProjects

module.exports = model;