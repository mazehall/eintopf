path = require "path"
child = require 'child_process'

process.env.EINTOPF_DIR = require('path').dirname(require.main.filename)
process.env.DOCKER_HOST = 'tcp://127.0.0.1:2375'

model = module.exports

npmInstall = (project, callback) ->
  return callback('invalid project config') if !project.project || !project.source
  console.log 'installing project ' + project.project

  child.exec 'npm install ' + project.source, (err) ->
    return callback err if err
    return callback null, 1

model.installProject = (project, callback) ->
  return callback('invalid project config') if !project.project || !project.source
  npmInstall project, callback

model.startProject = (project, callback) ->
  return callback 'invalid project' if typeof project is "undefined" || !project.path

  console.log 'cd ' + project.path + ' && npm start'

  child.exec 'cd ' + project.path + ' && npm start', (err, stdout, stderr) ->
    console.log err, stdout, stderr
    return callback err if err
    return callback()

model.stopProject = (project, callback) ->
  return callback 'invalid project' if typeof project is "undefined" || !project.path

  console.log 'cd ' + project.path + ' && npm stop'

  child.exec 'cd ' + project.path + ' && npm stop', (err, stdout, stderr) ->
    console.log err, stdout, stderr
    return callback err if err
    return callback()

model.projectAction = (project, script, callback) ->
  return callback 'invalid project' if typeof project is "undefined" || !project.path
  return callback 'action not found' if not project['scripts']?[script]?

  console.log 'cd ' + project.path + ' && npm run ' + script

  child.exec 'cd ' + project.path + ' && npm run ' + script, (err, stdout, stderr) ->
    console.log err, stdout, stderr
    return callback err if err
    return callback()