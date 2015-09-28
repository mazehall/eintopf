var _r = require('kefir');
var mazehall = require('mazehall');
var server = require('./app.js');

serverStream = _r.fromEvents(process, 'app:startserver').filter();
guiStream = mazehall.moduleStream.filter(function(val) { if(val.module == 'gui') return val; });

_r.zip([guiStream, serverStream])
.onValue(function(val) {
  var port = val[1];
  server.listen(port, function() {
    console.log('server listen on port: ' + port);
    process.emit('app:serverstarted');
  });
});