var server = require('./app.js');

var port;
port = process.env.PORT || 3131;
server.listen(port, function() {
  console.log('server listen on port: ' + port);
});
