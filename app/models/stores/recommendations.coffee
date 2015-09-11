_r = require 'kefir'
watcherModel = require './watcher.coffee'

loadingTimeout = 3600000
recommendations = [
  {
    "name": "Example Wordpress",
    "description": "Here is a little description",
    "img": "fa-wordpress",
    "url": "https://github.com/mazehall/eintopf-wordpress"
  },
  {
    "name": "Example Drupal",
    "description": "Here is a little description",
    "img": "fa-drupal",
    "url": "https://github.com/mazehall/eintopf-drupal"
  }
]

model = {}

#@todo implement loading from http backend
model.loadRecommendations = (callback) ->
  callback null, recommendations

model.loadRecommendationsWithInterval = () ->
  _r.withInterval loadingTimeout, (emitter) ->
    model.loadRecommendations (err, result) ->
      return emitter.error err if err
      emitter.emit result
  .onValue (val) ->
    return watcherModel.set 'recommendations:list', [] if ! val
    watcherModel.set 'recommendations:list', recommendations
  .onError (err) ->
    if ! watcherModel.get 'recommendations:list'
      watcherModel.set 'recommendations:list', []

# initial recommendation load
model.loadRecommendations (err, result) ->
  watcherModel.set 'recommendations:list', result

module.exports = model;