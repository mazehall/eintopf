_r = require 'kefir'

modelSetup = require '../../../models/setup/setup.coffee'
modelProjects = require '../../../models/projects/list.coffee'

modelSetup.run()

states = (connections_, rawSocket) ->
  _r.fromPoll 1000 * 5, () ->
    modelSetup.getState()
  .onValue (res) ->
    rawSocket.emit 'states:live', res

  connections_.onValue (socket) ->
    socket.emit 'states:live', modelSetup.getState()

    _r.fromEvents socket, 'states:restart'
    .onValue () ->
      modelSetup.restart()
      rawSocket.emit 'states:live', modelSetup.getState()

    _r.fromEvents socket, 'projects:list'
    .onValue () ->
      socket.emit 'res:projects:list', modelProjects.getList()

    _r.fromEvents socket, 'projects:install'
    .filter()
    .onValue (val) ->
      modelProjects.installProjectList val, (err, result) ->
        res = {}
        res.errorMessage = err.message if err? && typeof err == 'object'
        res.status = if err then 'error' else 'success'

        socket.emit 'res:projects:install', res


module.exports = states
