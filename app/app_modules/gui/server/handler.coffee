fs = require "fs"

utilModel = require "../../../models/util/index.coffee"
projectsModel = require "../../../models/projects/list.coffee"

handler = module.exports
handler.projectResource = (req, res, next) ->
  notFound = () -> res.status(404).send({"message": "File not found"})

  project = projectsModel.getProject req.params.project
  return notFound() if ! project || ! project.path

  file = "#{project.path}/#{req.params.resource}"
  return notFound() if ! req.params.resource || ! fs.existsSync file
  return res.sendfile file