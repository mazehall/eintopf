config = require 'config'
jetpack = require 'fs-jetpack'

utilsModel = require '../util/index.coffee'

process.env.DOCKER_HOST = 'tcp://127.0.0.1:2375'

mergeConfigsAndReturnIt = (userConfig) ->
  customConfig = {}
  config.util.extendDeep customConfig, config, userConfig
  config.util.attachProtoDeep customConfig
  config.util.runStrictnessChecks customConfig
  config.util.makeImmutable customConfig

  return customConfig

getCustomConfig = () ->
  utilsModel.loadUserConfig (err, userConfig) ->
    if err || ! userConfig
      console.log "Error: Failed using user config with:", err if err
      utilsModel.setConfig config
      return config

    mergedConfig = mergeConfigsAndReturnIt userConfig
    utilsModel.setConfig mergedConfig
    return mergedConfig

module.exports = getCustomConfig()