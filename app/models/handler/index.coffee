utilModel = require "../util/index.coffee"
fs = require "fs"

handler = module.exports
handler.projectResource = (req, res, next) ->
  file = "#{utilModel.getConfigModulePath()}/configs/#{req.params.project}/#{req.params.resource}"

  return res.status(404).send({"message": "file not found"}) unless fs.existsSync file
  return res.sendfile file