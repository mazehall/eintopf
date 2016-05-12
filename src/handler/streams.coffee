dockerStream = require './streams/docker.coffee'
eintopfStream = require './streams/eintopf.coffee'
storageStream = require './streams/storage.coffee'
vmStream = require './streams/vm.coffee'

model = {}

model.enableStorage = storageStream.enable
model.enableEintopf = eintopfStream.enable
model.enableDocker = dockerStream.enable
model.enableVm = vmStream.enable

model.disableEintopf = eintopfStream.disable
model.disableStorage = storageStream.disable
model.disableDocker = dockerStream.disable
model.disableVm = vmStream.disable

model.init = ->
  model.enableStorage()
  model.enableEintopf()
  model.enableDocker()

  #@todo only when vm configured
  model.enableVm()


module.exports = model