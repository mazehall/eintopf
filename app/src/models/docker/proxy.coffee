_r = require 'kefir'
ks = require 'kefir-storage'

config = require '../stores/config.coffee'
dockerModel = require '.'

proxyConfig = config.get 'proxy'

runningProxyDeployment = false
messageProxyUpToDate = 'proxy is up to date'
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
      return new Error 'Proxy image mismatch'
  .flatMapErrors (err) ->
    return _r.constantError err if err.message == messageProxyAlreadyInstalling

    _r.fromNodeCallback (cb) ->
      inspect = null
      model.deployProxy cb
  .flatMap () ->
    return _r.constant true if inspect?.State?.Running == true

    _r.fromNodeCallback (cb) ->
      container.start cb
  # callback mapping
  .onError callback
  .onValue (val) ->
    callback null, val

model.deployProxy = (callback) ->
  runningProxyDeployment = true;
  container = null;

  _r.fromNodeCallback (cb) ->
    container = model.getProxyContainer()
    container.inspect (err, data) -> # remove proxy container
      if err
        return cb err if err.statusCode != 404
        return cb null, true
      container.remove {force:true}, cb
  .flatMap () ->
    _r.fromNodeCallback (cb) ->
      model.getProxyImage().inspect (err, result) ->
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

#######################
# runtime streams
#

# monitor proxy container
_r.interval 10000
.flatMap () ->
  _r.fromNodeCallback (cb) ->
    model.monitorProxy cb
.onError (err) ->
  connectCodes = ['ECONNREFUSED', 'ECONNRESET']

  ks.setChildProperty 'states:live', 'proxy', false

  if connectCodes.indexOf(err.code) >= 0
    ks.setChildProperty 'states:live', 'proxyError', 'Cannot connect to docker'
  else
    ks.setChildProperty 'states:live', 'proxyError', err.message

.onValue (val) ->
  ks.setChildProperty 'states:live', 'proxy', true
  ks.setChildProperty 'states:live', 'proxyError', null
