eventHandler = require './handler/events.coffee'
setupModel = require './models/setup/setup.coffee'
projectsModel = require './models/projects/list.coffee'
registryModel = require './models/stores/registry.coffee'

model = (webContents) ->

  setupModel.run()
  projectsModel.loadProjects()
  registryModel.loadRegistryWithInterval()

  #  init events
  eventHandler(webContents)

module.exports = model;
