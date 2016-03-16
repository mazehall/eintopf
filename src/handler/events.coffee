_r = require 'kefir'
ks = require 'kefir-storage'
ipcMain = require('electron').ipcMain;

setupModel = require '../models/setup/setup.coffee'
projectsModel = require '../models/projects/list.coffee'
dockerModel = require '../models/docker'
terminalModel = require '../models/util/terminal.coffee'
registry = require '../models/registry'

ipcToKefir = (eventName) ->
  _r.fromEvents ipcMain, eventName, (event, value) ->
    return {event: event, value: value}

handleEvents = (webContents) ->

  # initial emits on page load
  webContents.on 'dom-ready', ->
    webContents.send 'states', ks.get 'states:live'

  ###############
  # watcher
  ###############

  ks.fromProperty 'projects:list'
  .onValue (val) ->
    webContents.send 'res:projects:list', val.value

  ks.fromRegex /^project:detail:/
  .onValue (prop) ->
    project = prop.value
    webContents.send "res:project:detail:#{project.id}", project

  # emit changes in live states
  ks.fromProperty 'states:live'
  .onValue (val) ->
    webContents.send 'states', val.value

  # emit changes in docker container list
  ks.fromProperty 'containers:list'
  .onValue (val) ->
    webContents.send 'res:containers:list', val.value

  ks.fromProperty 'containers:inspect'
  .onValue (val) ->
    webContents.send 'res:containers:inspect', val.value

  ks.fromRegex /^res:project:start:/
  .onValue (val) ->
    webContents.send val.name, val.value[val.value.length-1]

  ks.fromRegex /^res:project:stop:/
  .onValue (val) ->
    webContents.send val.name, val.value[val.value.length-1]

  ks.fromRegex /^res:project:delete:/
  .onValue (val) ->
    webContents.send val.name, val.value

  ks.fromRegex /^res:project:update:/
  .onValue (val) ->
    webContents.send val.name, val.value[val.value.length-1]

  ks.fromRegex /^res:project:action:script:/
  .onValue (val) ->
    webContents.send val.name, val.value[val.value.length-1]

  # emit apps changes
  ks.fromProperty 'apps:list'
  .onValue (val) ->
    webContents.send 'res:apps:list', val.value

  # emit settings changes
  ks.fromProperty 'settings:list'
  .onValue (val) ->
    webContents.send 'res:settings:list', val.value

  # emit terminal output
  ks.fromProperty 'terminal:output'
  .filter (val) ->
    return true if val.value?.length > 0
  .map (val) ->
    return val.value.pop()
  .onValue (val) ->
    webContents.send 'terminal:output', val

  ks.fromProperty 'locks'
  .onValue (val) ->
    webContents.send 'locks', val.value

  ks.fromProperty 'registry:public'
  .onValue (val) ->
    webContents.send 'registry:public', val.value

  ks.fromProperty 'registry:privateCombined'
  .onValue (val) ->
    webContents.send 'registry:private', val.value

  ###############
  # listener
  ###############

  ipcToKefir 'req:locks'
  .onValue (val) ->
    webContents.send 'locks', ks.get 'locks'

  ipcToKefir 'req:states'
  .onValue (val) ->
    val.event.sender.send 'states', ks.get 'states:live'

  ipcToKefir 'projects:list'
  .onValue (val) ->
    val.event.sender.send 'res:projects:list', ks.get 'projects:list'

  ipcToKefir 'states:restart'
  .onValue () ->
    setupModel.run()

  ipcToKefir 'containers:list'
  .onValue (val) ->
    val.event.sender.send 'res:containers:list', ks.get 'containers:list'

  ipcToKefir 'containers:inspect'
  .onValue (val) ->
    val.event.sender.send 'res:containers:inspect', ks.get 'containers:inspect'

  ipcToKefir 'apps:list'
  .onValue (val) ->
    val.event.sender.send 'res:apps:list', ks.get 'apps:list'

  ipcToKefir 'settings:list'
  .onValue (val) ->
    val.event.sender.send 'res:settings:list', ks.get 'settings:list'

  ipcToKefir 'registry:public'
  .onValue (val) ->
    val.event.sender.send 'registry:public', ks.get 'registry:public'

  ipcToKefir 'registry:private'
  .onValue (val) ->
    val.event.sender.send 'registry:private', ks.get 'registry:privateCombined'

  ipcToKefir 'terminal:input'
  .filter (x) -> x.value?
  .onValue (x) ->
    terminalModel.writeIntoPTY x.value

  ipcToKefir 'req:pattern'
  .filter (val) -> val.value?
  .onValue (val) ->
    recipe = registry.getRecipe val.value
    val.event.sender.send 'pattern:' + val.value, recipe || {}

  ipcToKefir 'projects:install'
  .filter (val) -> val.value?
  .onValue (val) ->
    projectsModel.installProject val.value, (err, result) ->
      val.event.sender.send 'project:install:' + val.value.id, {err: err?.message || null, result: result}

  ipcToKefir 'project:detail'
  .filter (x) -> x.value?
  .onValue (x) ->
    x.event.sender.send "res:project:detail:#{x.value}", ks.get 'project:detail:' + x.value

  ipcToKefir 'project:start'
  .filter (x) -> x if x.value?.id?
  .onValue (x) ->
    projectsModel.startProject x.value.id

  ipcToKefir 'project:stop'
  .filter (x) -> x if x.value?.id?
  .onValue (x) ->
    projectsModel.stopProject x.value.id

  ipcToKefir 'project:delete'
  .filter (x) -> x if x.value?.id?
  .onValue (x) ->
    projectsModel.deleteProject x.value, () ->

  ipcToKefir 'project:update'
  .filter (x) -> x if x.value?.id?
  .onValue (x) ->
    projectsModel.updateProject x.value, () ->

  ipcToKefir 'project:action:script'
  .filter (x) -> x if x.value?.id? && x.value.action?.script
  .onValue (x) ->
    projectsModel.callAction x.value.id, x.value.action.script

  ipcToKefir 'container:start'
  .filter (x) -> typeof x.value == "string"
  .onValue (x) ->
    dockerModel.startContainer x.value, (err, result) ->
      return false if ! err
      ret =
        id: x.value
        message: err.reason || err.json
      x.event.sender.send 'res:containers:log', ret

  ipcToKefir 'container:stop'
  .filter (x) -> typeof x.value == "string"
  .onValue (x) ->
    dockerModel.stopContainer x.value, (err, result) ->
      return false if ! err
      ret =
        id: x.value
        message: err.reason || err.json
      x.event.sender.send 'res:containers:log', ret

  ipcToKefir 'container:remove'
  .filter (x) -> typeof x.value == "string"
  .onValue (x) ->
    dockerModel.removeContainer x.value, (err, result) ->
      return false if ! err
      ret =
        id: x.value
        message: err.reason || err.json
      x.event.sender.send 'res:containers:log', ret

module.exports = handleEvents
