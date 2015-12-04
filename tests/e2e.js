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

var chromebinarylocation;
switch (process.platform) {
    case 'darwin':
        chromebinarylocation = "/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome";
        break;
    case 'linux':
        chromebinarylocation = "/usr/bin/google-chrome";
        break;
    case 'win32':
        chromebinarylocation = "C:\\Users\\%USERNAME%\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe".replace("%USERNAME%", process.env.username);
        break;
}

try {
    fs.statSync(chromebinarylocation);
} catch(e) {
    console.log("ChromeDriver requires the default Chrome install location and can not be changed:");
    console.log("  ->", chromebinarylocation, "\n");
    console.log("Install Chrome or Eintopf at this location or link the binary");
    process.exit(0);
}

if (process.platform === "darwin") {
    console.log("*** Selenium need Java v1.7! Install JDK 1.7 and set the Environment variable: JAVA_HOME=\"`/usr/libexec/java_home -v '1.7*'`\" ***");
}

spawn("node", ["node_modules/nightwatch/bin/nightwatch", "--config", "tests/e2e/nightwatch.json"], {
    env: process.env,
    stdio: "inherit"
});