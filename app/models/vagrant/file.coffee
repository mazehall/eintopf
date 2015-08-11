config = require 'config'
_r = require 'kefir'

fsModel = require './fs.coffee'

model = {}
model.install = (cb) ->
  error = null;
  _r
  .fromNodeCallback (cb) ->
    setTimeout () ->
      fsModel.copyVagrantFile cb
    , 1
  .onValue (val) ->
    console.log 'on val', val
  .onError (err) ->
    console.log 'on err', err
    error = new Error err
  .onEnd (err) ->
    console.log 'on end', err
    cb error, true

module.exports = model;