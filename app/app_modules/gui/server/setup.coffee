_r = require 'kefir'

modelSetup = require '../../../models/setup/setup.coffee'

modelSetup.run()

setup = (connections_, rawSocket) ->
  _r.fromPoll 1000 * 5, () ->
    modelSetup.getState()
  .onValue (res) ->
    rawSocket.emit 'setup:live', res

  connections_.onValue (socket) ->
    socket.emit 'setup:live', modelSetup.getState()

    _r.fromEvents socket, 'setup:restart'
    .onValue () ->
      modelSetup.restart()
      rawSocket.emit 'setup:live', modelSetup.getState()


module.exports = setup
