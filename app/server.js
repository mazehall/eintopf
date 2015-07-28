var server = require('./app.js');

var port = process.env.PORT;


process.on('message', function(m) {
  if (m === 'app:startserver') {
    server.listen(port, function() {
      process.send({ port: port });
      console.log('server listen on port: ' + port);
    });
  }
});
