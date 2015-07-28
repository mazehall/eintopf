_r = require 'kefir'

mazehall = require 'mazehall/lib/modules'

modules = []

provider = module.exports

loadProjects = (callback) ->
  modules = []

  directoryStream = _r.stream mazehall.dirEmitter('node_modules')
  packagesStream = directoryStream
  .flatMap mazehall.readPackageJson
  .filter (x) ->
    x.pkg.mazehall && x.pkg.eintopf && typeof x.pkg.eintopf is "object"

  .onValue (val) ->
    val.pkg.eintopf['path'] = val.path
    val.pkg.eintopf['scripts'] = val.pkg.scripts
    modules.push val.pkg.eintopf
  .onEnd () ->
    return callback null, modules

  directoryStream.onError (err) ->
    return callback 'failed to scan module folder'

provider.getProjects = (callback) ->
  loadProjects (err) ->
    callback err if err
    callback null, modules
