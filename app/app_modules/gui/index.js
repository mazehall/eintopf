var path = require("path");
var serveStatic = require("serve-static");
var _r = require("kefir");
var setupSocket = require("./server/setup.coffee");

var env = process.env.NODE_ENV || "development";

module.exports = function(app) {
  app.use(serveStatic(path.join(__dirname, env === "development" ? "public/src" : "public/dist")));

  var socketServer = app.get('io').of('/setup');
  var sockets_ = _r.fromEvents(
    socketServer,
    'connection'
  );
  setupSocket(sockets_, socketServer);
};
