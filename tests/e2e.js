'use strict';

var spawn = require("child_process").spawn;
var fs = require("fs");
try {
    fs.statSync("./node_modules/nightwatch");
    fs.statSync("./node_modules/chromedriver");
    fs.statSync("./node_modules/selenium-server-standalone-jar");
} catch(e) {
    var options = ["install", "chromedriver@2.20.0", "nightwatch@0.8.8", "selenium-server-standalone-jar@2.47.1"];
    var install = spawn(process.platform === "win32" ? "npm.cmd" : "npm", options, {
        env: process.env,
        stdio: "inherit"
    });
}

spawn("node", ["node_modules/nightwatch/bin/nightwatch", "--config", "tests/e2e/nightwatch.json"], {
    env: process.env,
    stdio: "inherit"
});