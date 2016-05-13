_r = require 'kefir'
ks = require 'kefir-storage'

DockerModel = require '.'
utilModel = require '../util/index.coffee'

# keep mapping for swift reuse with container list
projectToContainerMapping = {}

model = {}

# maps container data
model.mapInspectData = (container) ->
  projectToContainerMapping[container.id] = null

  if (labels = container.inspect.Config.Labels) and labels["com.docker.compose.project"]
    projectToContainerMapping[container.id] = container.project = labels["com.docker.compose.project"]
    (container.projectId = project.id if project.composeId == container.project) for project in (ks.get("projects:list") || [])

  if (utilModel.typeIsArray container.inspect.Config.Env)
    for env in (container.inspect.Config.Env || [])
      container.virtualHost = match[1] if (match = env.match /^VIRTUAL_HOST=(.*)/)?
      container.certName = match[1] if (match = env.match /^CERT_NAME=(.*)/)?
  return container

# loads container inspect data and adds that plus somme additional mapped data
model.loadContainer = (container, callback) ->
  return callback new Error 'invalid container' if !container || !container.Id

  DockerModel.docker.getContainer(container.Id).inspect (err, result) ->
    return callback err if err

    container.inspect = result
    return callback null, model.mapInspectData container

model.getCerts = (host, certName) ->
  certs = ks.get 'proxy:certs'
  return certs[certName] if certName && certs?[certName]
  return certs[host] if certs?[host]

  resolveWildcard = host
  while (n = resolveWildcard.indexOf ".") && n > 0
    resolveWildcard = resolveWildcard.substr n + 1
    return certs[resolveWildcard] if certs?[resolveWildcard]
  return null;

model.initApps = (container) ->
  return false if ! container?.virtualHost

  virtualHosts = container.virtualHost.split(",")
  virtualHosts.forEach (virtualHost) ->
    return false if virtualHost.match /^\*/ # ignore wildcards

    certs = model.getCerts virtualHost, container.certName
    app =
      running: container.running
      name: container.name
      host: virtualHost
      certs: certs if certs
      https: true if certs
      project: container.project

    ks.setChildProperty 'apps:list', container.project  + '_' + virtualHost, app

model.inspectContainers = (containers) ->
  return false if ! utilModel.typeIsArray containers

  stream = _r.pool()
  stream.flatten()
  .filter (container) ->
    !(ks.getChildProperty 'containers:inspect', container.Id)
  .flatMap (container) ->
    _r.fromNodeCallback (cb) ->
      model.loadContainer container, cb
  .onValue (container) ->
    ks.setChildProperty 'containers:inspect', container.Id, container
    model.initApps container

  stream.plug _r.constant containers

model.loadContainers = ->
  _r.fromNodeCallback (cb) ->
    DockerModel.docker.listContainers {"all": true}, cb
  .map (containers) ->
    for container in (containers || [])
      container.id = container.Id
      container.status = container.Status
      container.name = container.Names[0].replace(/\//g, '') if container.Names?[0]? # strip docker-compose slashes
      container.running = if container.status.match(/^Up/) then true else false
      container.project = projectToContainerMapping[container.id] if projectToContainerMapping[container.id]?
    containers
  .map (containers) ->
    containers.sort (a, b) ->
      return -1 if a.name < b.name
      return 1 if a.name > b.name
      return 0;
  .onError -> # reset on connection error
    ks.set 'containers:list', []
    ks.set 'containers:inspect', {}
    ks.set 'apps:list', {}
  .onValue (containers) ->
    ks.set 'containers:list', containers
    model.inspectContainers containers

module.exports = model;
