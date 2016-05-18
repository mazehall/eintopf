_r = require 'kefir'
jetpack = require 'fs-jetpack'
config = require 'config'

utilModel = require '../util/'

appConfig = config.get 'app'

model = {}

model.copyVagrantFile = (callback) ->
  configModulePath = utilModel.getConfigModulePath()
  pathDefaultVagrantFile = appConfig.pathDefaultVagrantFile
  return cb new Error 'copy failed due to misconfiguration' if ! configModulePath? || ! pathDefaultVagrantFile?

  src = jetpack.cwd(process.env.ELECTRON_APP_DIR).path(appConfig.pathDefaultVagrantFile)

  jetpack.dirAsync configModulePath
  .then (dir) ->
    jetpack.copyAsync src, dir.path("Vagrantfile"), {overwrite: false}
  .then () ->
    callback null, true
  .fail (err) -> # ignore already exists error
    return callback null, true if typeof err == "object" && err.message.match /^Destination path already exists/
    callback err

model.loadVagrantFile = (callback) ->
  return callback new Error 'failed to fetch config dir' if ! (configPath = utilModel.getConfigModulePath())?
  vagrantFile = jetpack.cwd configPath, 'Vagrantfile'

  jetpack.readAsync vagrantFile.path()
  .fail callback
  .then (content) ->
    callback null, content

model.getSSHConfig = (callback) ->
  _r.fromNodeCallback model.loadVagrantFile
  .map (config) ->
    result =
      user: 'vagrant'
      port: 22

    result.user = user[1] if (user = config.match /ssh.username(?:.*)["|'](.*)["|']/ ) && user[1]
    result.port = port[1] if (port = config.match /ssh.guest_port(?:.*)["|'](.*)["|']/ ) && port[1]
    result
  .onError callback
  .onValue (value) ->
    callback null, value


module.exports = model;
