var app = require('app');
var shell = require('shell');
var BrowserWindow = require('browser-window');
var menuEntries = require('./app_modules/gui/public/src/js/services/app-menu');
var windowStateKeeper = require('./vendor/electron_boilerplate/window_state');

var fs = require("fs");
var asar = require("asar");
var config = require("config");

// Change the current working directory
process.chdir(app.getAppPath() + (app.getAppPath().indexOf(".asar") > 0 ? ".unpacked/" : ""));

var server = require('./server.js');
var mainWindow, webContents;
var env = process.env.NODE_ENV = process.env.NODE_ENV || "development";
var port = process.env.PORT = process.env.PORT || 31313;
// Preserver of the window size and position between app launches.
var mainWindowState = windowStateKeeper('main', {
  width: 1000,
  height: 600
});

app.on('ready', function () {

  mainWindow = new BrowserWindow({
    x: mainWindowState.x,
    y: mainWindowState.y,
    width: mainWindowState.width,
    height: mainWindowState.height
  });
  webContents = mainWindow.webContents;

  if (mainWindowState.isMaximized) {
    mainWindow.maximize();
  }

  process.on('app:serverstarted', function() {
    var appUrl = "http://localhost:" + port;
    mainWindow.loadUrl(appUrl, {userAgent: "electron"});
    webContents.on("will-navigate", function(event, targetUrl){
        if (targetUrl.indexOf(appUrl) === -1){
            shell.openExternal(targetUrl);
            event.preventDefault();
        }
    });
  });
  process.emit('app:startserver', port);

  //menuEntries.setMenu();

  mainWindow.on('close', function () {
    mainWindowState.saveState(mainWindow);
  });


});

app.on('window-all-closed', function () {
  app.quit();
});

var getEintopfConfigPath = function(){
    var home = process.env.HOME;

    if (process.env.EINTOPF_HOME){
        home = process.env.EINTOPF_HOME;
    } else if (process.platform == 'win32'){
        home = process.env.USERPROFILE;
    }

    return(home + "/.eintopf").replace(/^(~|~\/)/, home);
};

var checkBackup = function(){
    var eintopfConfig = getEintopfConfigPath();
    var vagrantFolder = eintopfConfig + "/"+ config.get("app.defaultNamespace") +"/.vagrant";
    var vagrantBackup = vagrantFolder + ".asar.bk";

    fs.readdir(vagrantFolder +"/machines/eintopf/virtualbox/", function(vagrantError, files){
        fs.access(vagrantBackup, function(backupError){
            if (vagrantError && backupError === null){
                console.log("unused vagrant backup was deleted");
                return fs.unlink(vagrantBackup, function(){});
            } else if(backupError && files.length && files.indexOf("id") !== -1){
                asar.createPackage(vagrantFolder, vagrantBackup, function(){
                    console.log("vagrant backup created at:", vagrantBackup);
                });
            } else if (backupError === null && files.indexOf("id") === -1){
                console.log("vagrant directory '", vagrantFolder, "' is corrupt");
                var packageList = asar.listPackage(vagrantBackup);
                if (packageList.indexOf("/machines/eintopf/virtualbox/id") === -1){
                    console.log("corrupt backup was deleted");
                    fs.unlink(vagrantBackup, function(){});
                    return;
                }
                asar.extractAll(vagrantBackup, vagrantFolder);
                console.log("vagrant directory restored!");
            }
        });
    });
};

checkBackup();