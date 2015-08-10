_r = require 'kefir'

mockResponse = {
  message: "setup..."
}

setup = (connections_, rawSocket) ->
  _r.fromPoll 1000 * 5, () ->
    mockResponse.datetime = new Date()
    mockResponse
  .onValue (res) ->
    rawSocket.emit 'setup:live', res

module.exports = setup
