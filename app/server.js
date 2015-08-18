var server = require('./app.js');

process.on('app:startserver', function(port) {
  server.listen(port, function() {
    process.emit('app:serverstarted');
    console.log('server listen on port: ' + port);
  });
});