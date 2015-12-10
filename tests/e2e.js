'use strict';

var spawn = require("child_process").spawn;
var fs = require("fs");
try {
    fs.statSync("./node_modules/nightwatch");
    fs.statSync("./node_modules/chromedriver");
    fs.statSync("./node_modules/selenium-server-standalone-jar");
} catch(e) {
    var options = ["install", "chromedriver@2.20.0", "nightwatch@^0.8.8", "selenium-server-standalone-jar@2.47.1"];
    var install = spawn(process.platform === "win32" ? "npm.cmd" : "npm", options, {
        env: process.env,
        stdio: "inherit"
    });
}

var options = [];

if (process.platform === "darwin") {
    console.log("*** Selenium need Java v1.7! Install JDK 1.7 and set the Environment variable: JAVA_HOME=\"`/usr/libexec/java_home -v '1.7*'`\" ***");
}

if (process.platform === "win32") {
    options.push("--skiptags \"docker,proxy\"")
}

spawn("node", ["node_modules/nightwatch/bin/nightwatch", "--config", "tests/e2e/nightwatch.json", options.join("\",\"")], {
    env: process.env,
    stdio: "inherit"
});