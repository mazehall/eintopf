var mazehall = require('mazehall');
var server = require('./app.js');

var guiLoaded = false;
var serverStarted = false;

mazehall.moduleStream.onValue(function(val) {
  if(val.module != 'gui') return false;

  guiLoaded = true;
  if(serverStarted) process.emit('app:serverstarted'); //emit server start when server already listens
});

process.on('app:startserver', function(port) {
  server.listen(port, function() {
    console.log('server listen on port: ' + port);

    serverStarted = true;
    if(guiLoaded) process.emit('app:serverstarted'); //emit server start when gui module was already loaded
  });
});