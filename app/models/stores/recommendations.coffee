_r = require 'kefir'
watcherModel = require './watcher.coffee'

loadingTimeout = 3600000
recommendations = [
  {
    "name": "Wordpress",
    "description": "WordPress is a free and open source blogging tool and a content management system (CMS) based on PHP and MySQL",
    "img": "fa-wordpress",
    "url": "https://github.com/mazehall/eintopf-wordpress"
  },
  {
    "name": "Drupal",
    "description": "Drupal is a free and open-source content-management framework written in PHP. It’s built, used, and supported by an active and diverse community of people around the world.",
    "img": "fa-drupal",
    "url": "https://github.com/mazehall/eintopf-drupal"
  },
  {
    "name": "Owncloud",
    "description": "OwnCloud is a file sharing server that puts the control and security of your own data back into your hands.",
    "img": "",
    "url": "https://github.com/mazehall/eintopf-owncloud"
  },
  {
    "name": "Ghost",
    "description": "Ghost is a simple, powerful publishing platform that allows you to share your stories with the world.",
    "img": "",
    "url": "https://github.com/mazehall/eintopf-ghost"
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