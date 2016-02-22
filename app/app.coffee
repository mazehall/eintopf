eventHandler = require './src/handler/events.coffee'
setupModel = require './src/models/setup/setup.coffee'
projectsModel = require './src/models/projects/list.coffee'
registryModel = require './src/models/stores/registry.coffee'
proxyModel = require './src/models/docker/proxy.coffee'
dockerEvents = require './src/models/docker/events.coffee'
dockerList = require './src/models/docker/list.coffee'

model = (webContents) ->

  setupModel.run()
  projectsModel.loadProjects()
  registryModel.loadRegistryWithInterval()

  #  init events
  eventHandler(webContents)

module.exports = model;
