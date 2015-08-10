config = require 'config'
jetpack = require 'fs-jetpack'
_r = require 'kefir'


appConfig = config.get 'app'

copyAndReturnPromise = () ->
  source = jetpack.cwd 'config/Vagrantfile.default'
  destination = jetpack.cwd appConfig.configPath + "/" + appConfig.defaultName + "/Vagrantfile"

  return jetpack.copyAsync(source.path(), destination.path(), { overwrite: true });

model = {}
model.install = (cb) ->
  error = null;
  _r.fromPromise copyAndReturnPromise()
  .onValue (val) ->
    console.log 'on val', val
  .onError (err) ->
    console.log 'on err', err
    error = new Error err
  .onEnd (err) ->
    console.log 'on end', err
    cb error, true

module.exports = model;