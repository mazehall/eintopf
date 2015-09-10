_r = require 'kefir'

utils = require '../../../models/util/index.coffee'

setupModel = require '../../../models/setup/setup.coffee'
projectsModel = require '../../../models/projects/list.coffee'
dockerModel = require '../../../models/docker/list.coffee'
watcherModel = require '../../../models/stores/watcher.coffee'
recommendationsModel = require '../../../models/stores/recommendations.coffee'

setupModel.run()
projectsModel.loadProjects()
recommendationsModel.loadRecommendationsWithInterval()

typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

states = (connections_, rawSocket) ->
  # emit changes in project list
  watcherModel.propertyToKefir 'projects:list'
  .onValue (val) ->
    rawSocket.emit 'res:projects:list', val.newValue

  # emit changes in live states
  watcherModel.propertyToKefir 'states:live'
  .onValue (val) ->
    rawSocket.emit 'states:live', val.newValue

  # emit changes in docker container list
  watcherModel.propertyToKefir 'containers:list'
  .onValue (val) ->
    rawSocket.emit 'res:containers:list', val.newValue

  #@todo emit project detail changes ????
#  watcherModel.propertyToKefir 'projects:list'
#  .onValue (val) ->
#    console.log val

  watcherModel.propertyToKefir 'res:projects:install'
  .onValue (val) ->
    rawSocket.emit 'res:projects:install', val.newValue

  watcherModel.toKefir()
  .filter (x) ->
    x.name.match /^res:project:start:/
  .onValue (val) ->
    rawSocket.emit val.name, val.newValue[val.newValue.length-1]

  watcherModel.toKefir()
  .filter (x) ->
    x.name.match /^res:project:stop:/
  .onValue (val) ->
    rawSocket.emit val.name, val.newValue[val.newValue.length-1]

  watcherModel.toKefir()
  .filter (x) ->
    x.name.match /^res:project:delete:/
  .onValue (val) ->
    rawSocket.emit val.name, val.newValue

  watcherModel.toKefir()
  .filter (x) ->
    x.name.match /^res:project:update:/
  .onValue (val) ->
    rawSocket.emit val.name, val.newValue[val.newValue.length-1]

  # emit apps changes
  watcherModel.propertyToKefir 'apps:list'
  .onValue (val) ->
    rawSocket.emit 'res:apps:list', val.newValue

  # emit settings changes
  watcherModel.propertyToKefir 'settings:list'
  .onValue (val) ->
    rawSocket.emit 'res:settings:list', val.newValue

  # emit recommendations changes
  watcherModel.propertyToKefir 'recommendations:list'
  .onValue (val) ->
    rawSocket.emit 'res:recommendations:list', val.newValue

  connections_.onValue (socket) ->
    socket.emit 'states:live', watcherModel.get 'states:live'

    _r.fromEvents socket, 'projects:list'
      .onValue () ->
        socket.emit 'res:projects:list', watcherModel.get 'projects:list'

    _r.fromEvents socket, 'projects:list:refresh'
    .onValue () ->
      projectsModel.loadProjects()

    _r.fromEvents socket, 'states:restart'
    .onValue () ->
      setupModel.restart()

    _r.fromEvents socket, 'containers:list'
    .onValue () ->
      dockerModel.loadContainers()
      socket.emit 'res:containers:list', watcherModel.get 'containers:list'

    _r.fromEvents socket, 'apps:list'
    .onValue () ->
      dockerModel.loadContainers()
      socket.emit 'res:apps:list', watcherModel.get 'apps:list'

    _r.fromEvents socket, 'projects:install'
    .filter()
    .onValue (val) ->
      watcherModel.set 'res:projects:install', null
      projectsModel.installProject val

    _r.fromEvents socket, 'project:detail'
    .filter()
    .onValue (id) ->
      projects = watcherModel.get 'projects:list'
      project = {}
      if typeIsArray projects
        for x,i in projects
          project = x if x.id == id
      socket.emit 'res:project:detail', project

    _r.fromEvents socket, 'project:start'
    .filter (x) ->
      x if x.id?
    .onValue (project) ->
      projectsModel.startProject project

    _r.fromEvents socket, 'project:stop'
    .filter (x) ->
      x if x.id?
    .onValue (project) ->
      projectsModel.stopProject project

    _r.fromEvents socket, 'project:delete'
    .filter (x) ->
      x if x.id?
    .onValue (project) ->
      projectsModel.deleteProject project

    _r.fromEvents socket, 'project:update'
    .filter (x) ->
      x if x.id?
    .onValue (project) ->
      projectsModel.updateProject project

    _r.fromEvents socket, 'settings:list'
    .onValue () ->
      socket.emit 'res:settings:list', watcherModel.get 'settings:list'

    _r.fromEvents socket, 'openExternalUrl'
    .filter()
    .onValue (url) ->
      utils.openExternalUrl url

    _r.fromEvents socket, 'recommendations:list'
    .onValue (url) ->
      socket.emit 'res:recommendations:list', watcherModel.get 'recommendations:list'

    _r.fromEvents socket, 'container:start'
    .filter (x) ->
      x if typeof x == "string"
    .onValue (containerId) ->
      dockerModel.startContainer containerId, (err, result) ->
        return false if ! err
        ret =
          id: containerId
          message: err.reason || err.json
        socket.emit 'res:containers:log', ret

    _r.fromEvents socket, 'container:stop'
    .filter (x) ->
      x if typeof x == "string"
    .onValue (containerId) ->
      dockerModel.stopContainer containerId, (err, result) ->
        return false if ! err
        ret =
          id: containerId
          message: err.reason || err.json
        socket.emit 'res:containers:log', ret

    _r.fromEvents socket, 'container:remove'
    .filter (x) ->
      x if typeof x == "string"
    .onValue (containerId) ->
      dockerModel.removeContainer containerId, (err, result) ->
        return false if ! err
        ret =
          id: containerId
          message: err.reason || err.json
        socket.emit 'res:containers:log', ret

module.exports = states
