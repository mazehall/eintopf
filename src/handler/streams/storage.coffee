_r = require 'kefir'
ks = require 'kefir-storage'

utilModel = require '../../models/util'

beat = _r.interval 1000, 'tick'
stream = _r.pool()

model = {}

model.enable = ->
  stream.plug(beat) if stream._isEmpty()

model.disable = ->
  stream.unplug(beat) if ! stream._isEmpty()


###########
# monitor certificate changes and sync them accordingly
_r.merge [ks.fromProperty('projects:certs'), ks.fromProperty('proxy:certs')]
.throttle 5000
.onValue (val) ->
  return false if ! (proxyCertsPath = utilModel.getProxyCertsPath())?
  projectCerts = if val.name == 'projects:certs' then val.value else ks.get 'projects:certs'

  utilModel.syncCerts proxyCertsPath, projectCerts, ->


###########
# update apps running state on container inspect change
ks.fromProperty 'containers:inspect'
.throttle 2000
.map (containers) ->
  runningProjects = {}
  for id, container of (containers.value || [])
    runningProjects[container.project] = true if container?.running && container.project
  runningProjects
.onValue (runningProjects) ->
  projects = ks.get "projects:list"

  for project in (projects || [])
    project.state = if runningProjects[project.composeId] then 'running' else null

  ks.set "projects:list", projects


###########
# set registry:private which is combined from registry:private:remote and projects:list
_r.combine [ks.fromProperty('registry:private:remote'), ks.fromProperty('registry:private:local'), ks.fromProperty('projects:list')]
.map (combined) ->
  result = []
  creatable = []
  pattern = []
  installed = []
  ids = {}

  for privateEntry in (combined[0].value || [])
    ids[privateEntry.dirName] = true
    installed.push privateEntry if privateEntry.installed
    pattern.push privateEntry if privateEntry.pattern
    creatable.push privateEntry if ! privateEntry.installed && ! privateEntry.pattern

  for privateEntry in (combined[1].value || [])
    ids[privateEntry.dirName] = true
    installed.push privateEntry if privateEntry.installed
    pattern.push privateEntry if privateEntry.pattern
    creatable.push privateEntry if ! privateEntry.installed && ! privateEntry.pattern

  for installedEntry in (combined[2].value || [])
    installed.push installedEntry if ! ids[installedEntry.id] # add entry if it does not already exist

  for registry in [creatable, pattern, installed]
    registry.sort (a, b) ->
      nameA = a.name.toLowerCase()
      nameB = b.name.toLowerCase()

      return -1 if nameA < nameB
      return 1 if nameA > nameB
      return 0
    result = result.concat registry
  result
.onValue (val) ->
  ks.set 'registry:private', val


module.exports = model