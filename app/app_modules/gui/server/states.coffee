_r = require 'kefir'
ks = require 'kefir-storage'

setupModel = require '../../../models/setup/setup.coffee'
projectsModel = require '../../../models/projects/list.coffee'
dockerModel = require '../../../models/docker/list.coffee'
registryModel = require '../../../models/stores/registry.coffee'
terminalModel = require '../../../models/util/terminal.coffee'

setupModel.run()
projectsModel.loadProjects()
registryModel.loadRegistryWithInterval()

typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

states = (connections_, rawSocket) ->
  # emit changes in project list
  ks.fromProperty 'projects:list'
  .onValue (val) ->
    rawSocket.emit 'res:projects:list', val.value

  ks.fromRegex /^project:detail:/
  .onValue (prop) ->
    project = prop.value
    rawSocket.emit "res:project:detail:#{project.id}", project

  # emit changes in live states
  ks.fromProperty 'states:live'
  .onValue (val) ->
    rawSocket.emit 'states:live', val.value

  # emit changes in docker container list
  ks.fromProperty 'containers:list'
  .onValue (val) ->
    rawSocket.emit 'res:containers:list', val.value

  ks.fromProperty 'containers:inspect'
  .onValue (val) ->
    rawSocket.emit 'res:containers:inspect', val.value

  ks.fromProperty 'res:projects:install'
  .onValue (val) ->
    rawSocket.emit 'res:projects:install', val.value

  ks.fromRegex /^res:project:start:/
  .onValue (val) ->
    rawSocket.emit val.name, val.value[val.value.length-1]

  ks.fromRegex /^res:project:stop:/
  .onValue (val) ->
    rawSocket.emit val.name, val.value[val.value.length-1]

  ks.fromRegex /^res:project:delete:/
  .onValue (val) ->
    rawSocket.emit val.name, val.value

  ks.fromRegex /^res:project:update:/
  .onValue (val) ->
    rawSocket.emit val.name, val.value[val.value.length-1]

  ks.fromRegex /^res:project:action:script:/
  .onValue (val) ->
    rawSocket.emit val.name, val.value[val.value.length-1]

  # emit apps changes
  ks.fromProperty 'apps:list'
  .onValue (val) ->
    rawSocket.emit 'res:apps:list', val.value

  # emit settings changes
  ks.fromProperty 'settings:list'
  .onValue (val) ->
    rawSocket.emit 'res:settings:list', val.value

  # emit recommendations changes
  ks.fromProperty 'recommendations:list'
  .onValue (val) ->
    rawSocket.emit 'res:recommendations:list', val.value

  # emit terminal output
  ks.fromProperty 'terminal:output'
  .filter (val) ->
    return true if val.value?.length > 0
  .map (val) ->
    return val.value.pop()
  .onValue (val) ->
    rawSocket.emit 'terminal:output', val

  ks.fromProperty "backend:errors"
  .onValue (val) ->
    rawSocket.emit "res:backend:errors", val.value

  connections_.onValue (socket) ->
    socket.emit 'states:live', ks.get 'states:live'

    _r.fromEvents socket, 'terminal:input'
    .filter()
    .onValue (val) ->
      terminalModel.writeIntoPTY val

    _r.fromEvents socket, 'projects:list'
    .onValue () ->
      socket.emit 'res:projects:list', ks.get 'projects:list'

    _r.fromEvents socket, 'states:restart'
    .onValue () ->
      setupModel.restart()

    _r.fromEvents socket, 'containers:list'
    .onValue () ->
      socket.emit 'res:containers:list', ks.get 'containers:list'

    _r.fromEvents socket, 'containers:inspect'
    .onValue () ->
      socket.emit 'res:containers:inspect', ks.get 'containers:inspect'

    _r.fromEvents socket, 'apps:list'
    .onValue () ->
      socket.emit 'res:apps:list', ks.get 'apps:list'

    _r.fromEvents socket, 'projects:install'
    .filter()
    .onValue (val) ->
      ks.set 'res:projects:install', null
      projectsModel.installProject val, (err, result) ->
        res = {}
        res.errorMessage = err.message if err? && typeof err == 'object'
        res.status = if err then 'error' else 'success'
        res.project = result if result?
        ks.set 'res:projects:install', res

    _r.fromEvents socket, 'project:detail'
    .filter()
    .onValue (id) ->
      socket.emit "res:project:detail:#{id}", ks.get 'project:detail:' + id

    _r.fromEvents socket, 'project:start'
    .filter (x) ->
      x if x.id?
    .onValue (project) ->
      projectsModel.startProject project

    _r.fromEvents socket, 'project:stop'
    .filter (x) ->
      x if x.id?
    .onValue (project) ->
      projectsModel.stopProject project

    _r.fromEvents socket, 'project:delete'
    .filter (x) ->
      x if x.id?
    .onValue (project) ->
      projectsModel.deleteProject project, () ->

    _r.fromEvents socket, 'project:update'
    .filter (x) ->
      x if x.id?
    .onValue (project) ->
      projectsModel.updateProject project, () ->

    _r.fromEvents socket, 'project:action:script'
    .filter (x) ->
      x if x.id? and x.action?
    .onValue (project) ->
      projectsModel.callAction project, project.action

    _r.fromEvents socket, 'settings:list'
    .onValue () ->
      socket.emit 'res:settings:list', ks.get 'settings:list'

    _r.fromEvents socket, 'recommendations:list'
    .onValue (url) ->
      socket.emit 'res:recommendations:list', ks.get 'recommendations:list'

    _r.fromEvents socket, 'container:start'
    .filter (x) ->
      x if typeof x == "string"
    .onValue (containerId) ->
      dockerModel.startContainer containerId, (err, result) ->
        return false if ! err
        ret =
          id: containerId
          message: err.reason || err.json
        socket.emit 'res:containers:log', ret

    _r.fromEvents socket, 'container:stop'
    .filter (x) ->
      x if typeof x == "string"
    .onValue (containerId) ->
      dockerModel.stopContainer containerId, (err, result) ->
        return false if ! err
        ret =
          id: containerId
          message: err.reason || err.json
        socket.emit 'res:containers:log', ret

    _r.fromEvents socket, 'container:remove'
    .filter (x) ->
      x if typeof x == "string"
    .onValue (containerId) ->
      dockerModel.removeContainer containerId, (err, result) ->
        return false if ! err
        ret =
          id: containerId
          message: err.reason || err.json
        socket.emit 'res:containers:log', ret

module.exports = states
