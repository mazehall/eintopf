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


module.exports = states
