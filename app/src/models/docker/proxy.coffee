_r = require 'kefir'

config = require '../stores/config.coffee'
dockerModel = require '.'

proxyConfig = config.get 'proxy'

runningProxyDeployment = false
messageProxyAlreadyInstalling = "proxy deployment is running"


model = {}

model.getProxyContainer = () ->
  dockerModel.getContainer proxyConfig.name

model.getProxyImage = () ->
  dockerModel.getImage proxyConfig.Image

model.monitorProxy = (callback) ->
  container = null
  inspect = null

  _r.fromNodeCallback (cb) ->
    if runningProxyDeployment
      console.log 'test'
      return setTimeout ->
        cb new Error messageProxyAlreadyInstalling
        , 1

    container = model.getProxyContainer()
    container.inspect (err, val) ->
      inspect = val
      cb err, val
  .flatMap (inspect) ->
    _r.fromNodeCallback (cb) ->
      return cb null, true if proxyConfig.Image == inspect.Config.Image
      return cb new Error 'Proxy image mismatch'
  .flatMapErrors (err) ->
    return _r.constantError err if err.message == messageProxyAlreadyInstalling

    _r.fromNodeCallback (cb) ->
      inspect = null
      model.deployProxy cb
  .flatMap () ->
    return _r.constant true if inspect?.State?.Running == true

    _r.fromNodeCallback (cb) ->
      container.start cb
  .onError callback
  .onValue (val) ->
    callback null, val

model.deployProxy = (callback) ->
  runningProxyDeployment = true;
  container = null;

  _r.fromNodeCallback (cb) ->
    container = model.getProxyContainer()
    container.inspect (err) -> # remove proxy container
      if err
        return cb err if err.statusCode != 404
        return cb null, true
      container.remove {force:true}, cb
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      model.getProxyImage().inspect (err) ->
        if err
          return cb err if err.statusCode != 404
          return dockerModel.pull proxyConfig.Image, null, cb
        return cb null, true
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      dockerModel.createContainer proxyConfig, cb
  .onError callback
  .onValue (val) ->
    callback null, val
  .onEnd () ->
    runningProxyDeployment = false;

module.exports = model
