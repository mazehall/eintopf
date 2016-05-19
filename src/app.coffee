utilsModel = require './models/util'
utilsModel.initConfig()

eventHandler = require './handler/events.coffee'
setupModel = require './models/setup/setup.coffee'
projectsModel = require './models/projects/list.coffee'
registryModel = require './models/registry/index.coffee'
runTimeStreams = require './handler/runtimeStreams.coffee'

model = (webContents) ->

  setupModel.run()
  projectsModel.loadProjects()
  registryModel.init()

  #  init events
  eventHandler(webContents)

module.exports = model;
