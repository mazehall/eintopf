var path = require("path");
var serveStatic = require("serve-static");

var env = process.env.NODE_ENV || "development";

module.exports = function(app) {
    app.use(serveStatic(path.join(__dirname, env === "development" ? "public/src" : "public/dist")));
};