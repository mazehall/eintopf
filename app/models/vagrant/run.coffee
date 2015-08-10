config = require 'config'

model = {}

model.run = (cb) ->
  setTimeout () ->
    console.log('finished vagrant run')
    cb null, true
  , 10000

module.exports = model;