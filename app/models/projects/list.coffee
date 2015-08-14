git  = require 'gift'
jetpack = require 'fs-jetpack'

vagrantFsModel = require '../vagrant/fs.coffee'

projects = [
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
        return callback new Error err.message if err
        callback null, true
  .fail (err) ->
    callback err

module.exports = model;