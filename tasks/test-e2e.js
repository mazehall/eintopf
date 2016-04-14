'use strict';

var spawn = require("child_process").spawn;
var fs = require("fs");
var path = require('path');

try {
    fs.statSync("./node_modules/nightwatch");
    fs.statSync("./node_modules/chromedriver");
    fs.statSync("./node_modules/selenium-server-standalone-jar");
} catch(e) {
    var options = ["install", "chromedriver@2.20.0", "nightwatch@^0.8", "selenium-server-standalone-jar@2.47.1"];
    var install = spawn(process.platform === "win32" ? "npm.cmd" : "npm", options, {
        env: process.env,
        stdio: "inherit"
    });
}

var nightWatchConfigPath = "tests/e2e/nightwatch.json";
if (process.platform === "darwin") {
    console.log("*** Selenium need Java v1.7! Install JDK 1.7 and set the Environment variable: JAVA_HOME=\"`/usr/libexec/java_home -v '1.7*'`\" ***");
}

// windows - write custom nightwatch_win.json
if (process.platform === "win32") {
    var nightWatchConfigPath = "tests/e2e/nightwatch_win.json";
    var config = require("../tests/e2e/nightwatch.json");

    config["selenium"]["cli_args"]["webdriver.chrome.driver"] = "./node_modules/chromedriver/lib/chromedriver/chromedriver.exe";
    config["test_settings"]["default"]["desiredCapabilities"]["chromeOptions"]["binary"] = path.join(process.cwd(), 'tests/e2e/launcher_eintopf.cmd');
    config["test_settings"]["default"]["disable_colors"] = true;

    fs.writeFileSync(path.join(process.cwd(), nightWatchConfigPath), JSON.stringify(config));
}

spawn("node", ["node_modules/nightwatch/bin/nightwatch", "--config", nightWatchConfigPath], {
    env: process.env,
    stdio: "inherit"
});