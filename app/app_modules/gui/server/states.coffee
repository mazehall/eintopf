_r = require 'kefir'

setupModel = require '../../../models/setup/setup.coffee'
projectsModel = require '../../../models/projects/list.coffee'
dockerModel = require '../../../models/docker/list.coffee'

setupModel.run()
projectsModel.loadProjects()
dockerModel.loadContainers()

states = (connections_, rawSocket) ->
  _r.fromPoll 1000 * 5, () ->
    setupModel.getState()
  .onValue (res) ->
    rawSocket.emit 'states:live', res

  connections_.onValue (socket) ->
    socket.emit 'states:live', setupModel.getState()

    _r.fromEvents socket, 'states:restart'
    .onValue () ->
      setupModel.restart()
      rawSocket.emit 'states:live', setupModel.getState()

    _r.fromEvents socket, 'projects:list'
    .onValue () ->
      socket.emit 'res:projects:list', projectsModel.getList()

    _r.fromEvents socket, 'projects:install'
    .filter()
    .onValue (val) ->
      projectsModel.installProjectList val, (err, result) ->
        res = {}
        res.errorMessage = err.message if err? && typeof err == 'object'
        res.status = if err then 'error' else 'success'

        socket.emit 'res:projects:install', res
        rawSocket.emit 'res:projects:list', projectsModel.getList() if result == true #emit updated project list

    _r.fromEvents socket, 'project:detail'
    .filter()
    .onValue (id) ->
      socket.emit 'res:project:detail', projectsModel.getProject id

    _r.fromEvents socket, 'project:start'
    .filter()
    .onValue (project) ->
      projectsModel.startProject project, (err, logStream) ->
        logStream
        .slidingWindow 300
        .throttle 300
        .onValue (val) ->
          console.log val
          socket.emit 'res:project:start:' + project.id, val

    _r.fromEvents socket, 'project:stop'
    .filter()
    .onValue (project) ->
      projectsModel.stopProject project, (err, logStream) ->
        logStream
        .slidingWindow 300
        .throttle 300
        .onValue (val) ->
          console.log val
          socket.emit 'res:project:stop:' + project.id, val

    _r.fromEvents socket, 'apps:list'
    .onValue () ->
      socket.emit 'res:apps:list', dockerModel.getContainerList()

module.exports = states
