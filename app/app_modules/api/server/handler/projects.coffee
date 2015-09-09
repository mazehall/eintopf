model = require '../models/projects.coffee'
provider = require '../provider/projects.coffee'
utilModel = require "../../../../models/util/"
fs = require "fs"

handler = module.exports

handler.offeredProjects = (req, res, next) ->
  offeredProjects = req.app.offeredProjects || []
  return res.send({}) if (Object.prototype.toString.call(offeredProjects) != '[object Array]')
  res.send(offeredProjects)

handler.installProject = (req, res, next) ->
  projectKey = req.body.projectKey
  return res.status(500).send({"message": "project not given"}) if typeof projectKey is "undefined"

  offeredProjects = req.app.offeredProjects || []
  return res.status(500).send({"message": "project not found"}) if not offeredProjects?[projectKey]?

  model.installProject offeredProjects[projectKey], (err, result) ->
    return res.status(500).send({"message": "Install failed"}) if err
    res.status(200).send()

handler.projects = (req, res, next) ->
  provider.getProjects (err, result) ->
    return res.status(500).send({"message": "Failed to get projects list"}) if err
    return res.send result

handler.startProject = (req, res, next) ->
  projectKey = req.body.projectKey
  return res.status(500).send({"message": "project not given"}) if typeof projectKey is "undefined"

  provider.getProjects (err, result) ->
    return res.status(500).send({"message": "start Failed"}) if err || typeof result[projectKey] is "undefined"
    model.startProject result[projectKey], (err, result) ->
      return res.status(500).send({"message": "start Failed"}) if err
      return res.send()

handler.stopProject = (req, res, next) ->
  projectKey = req.body.projectKey
  return res.status(500).send({"message": "project not given"}) if typeof projectKey is "undefined"

  provider.getProjects (err, result) ->
    return res.status(500).send({"message": "start Failed"}) if err || typeof result[projectKey] is "undefined"
    model.stopProject result[projectKey], (err, result) ->
      return res.status(500).send({"message": "start Failed"}) if err
      return res.send()

handler.projectAction = (req, res, next) ->
  projectKey = req.body.projectKey
  return res.status(500).send({"message": "invalid post"}) if typeof projectKey is "undefined" || typeof req.body.script is "undefined"

  provider.getProjects (err, result) ->
    return res.status(500).send({"message": "project not found"}) if err || typeof result[projectKey] is "undefined"
    model.projectAction result[projectKey], req.body.script, (err, result) ->
      return res.status(500).send({"message": "action failed"}) if err
      return res.send()


handler.projectResource = (req, res, next) ->
  file = "#{utilModel.getConfigModulePath()}/configs/#{req.params.project}/#{req.params.resource}"

  return res.status(404).send({"message": "file not found"}) unless fs.existsSync file
  return res.sendfile file