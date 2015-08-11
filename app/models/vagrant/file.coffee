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
  .onError (err) ->
    error = new Error err
  .onEnd (err) ->
    cb error, true

module.exports = model;