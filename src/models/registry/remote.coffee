_r = require 'kefir'
https = require "https"
http = require "http"
url = require 'url'
ks = require 'kefir-storage'

utilsModel = require '../util/index'


model = {}

model.loadUrl = (registryUrl, callback) ->
  opts = url.parse registryUrl
  opts["headers"] = "accept": "application/json"
  server = if opts.protocol == "https:" then https else http

  req = server.request opts, (res) ->
    res.chunk = ""
    res.on 'data', (chunk) -> this.chunk += chunk;
    res.on 'end', () ->
      return callback new Error 'response set error code: ' + res.statusCode if res.statusCode.toString().substring(0, 1) != "2"
      try return callback null, JSON.parse res.chunk
      catch err
        return callback new Error 'failed to parse registry json'
  req.on "error", (err) -> return callback err
  req.on 'socket', (socket) ->
    socket.setTimeout 5000
    socket.on 'timeout', () ->
      return req.abort()
  req.end()

model.loadFromUrls = (urls, callback) ->
  urls = [urls] if typeof urls == "string"
  entries = []

  _r.later 0, urls
  .flatten()
  .skipDuplicates()
  .flatMap (url) ->
    _r.fromNodeCallback (cb) ->
      model.loadUrl url, cb
    .flatten()
    .skipDuplicates (a, b) -> # keep urls unique to avoid id issues (see id format in index -> map)
      a.url == b.url
    .map (entry) ->
      entry.registryUrl = url
      entry
  .onValue (entry) ->
    entries.push entry
  .onEnd ->
    callback null, entries

module.exports = model;