config = require '../stores/config'
jetpack = require 'fs-jetpack'
utilModel = require '../util/'
appConfig = config.get 'app'

model = {}

model.copyVagrantFile = (callback) ->
  configModulePath = utilModel.getConfigModulePath()
  pathDefaultVagrantFile = appConfig.pathDefaultVagrantFile
  return cb new Error 'copy failed due to misconfiguration' if ! configModulePath? || ! pathDefaultVagrantFile?

  src = jetpack.cwd(appConfig.pathDefaultVagrantFile).path()

  jetpack.dirAsync configModulePath
  .then (dir) ->
    jetpack.copyAsync src, dir.path("Vagrantfile"), {overwrite: false}
  .then () ->
    callback null, true
  .fail (err) -> # ignore already exists error
    return callback null, true if typeof err == "object" && err.message.match /^Destination path already exists/
    callback err

module.exports = model;
