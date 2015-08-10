var bodyParser = require("body-parser");

require('coffee-script/register');
var projectsHandler = require('./server/handler/projects');

var env = process.env.NODE_ENV || "development";

module.exports = function(app) {
    app.use("/api", bodyParser.urlencoded({extended: false}));
    app.use("/api", bodyParser.json());

    app.get("/api/projects", projectsHandler.projects);
    app.get("/api/offeredProjects", projectsHandler.offeredProjects);

    app.post("/api/install", projectsHandler.installProject);
    app.post("/api/start", projectsHandler.startProject);
    app.post("/api/stop", projectsHandler.stopProject);

    app.post("/api/action", projectsHandler.projectAction);
};
