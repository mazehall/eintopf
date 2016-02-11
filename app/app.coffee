eventHandler = require './src/handler/events.coffee'
setupModel = require './src/models/setup/setup.coffee'
projectsModel = require './src/models/projects/list.coffee'
registryModel = require './src/models/stores/registry.coffee'

model = (webContents) ->

  # @todo implementation???
  # app.get("/projects/:project/:resource", handlerModel.projectResource);

  setupModel.run()
  projectsModel.loadProjects()
  registryModel.loadRegistryWithInterval()

  #  init events
  eventHandler(webContents)

module.exports = model;
