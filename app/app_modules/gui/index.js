var path = require("path");
var serveStatic = require("serve-static");
var _r = require("kefir");
var statesSocket = require("./server/states.coffee");

var env = process.env.NODE_ENV || "development";

module.exports = function(app) {
  app.use(serveStatic(path.join(__dirname, env === "development" ? "public/src" : "public/dist")));

  var socketServer = app.get('io').of('/states');
  var sockets_ = _r.fromEvents(
    socketServer,
    'connection'
  );
  statesSocket(sockets_, socketServer);
};
