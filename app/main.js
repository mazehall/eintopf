var app = require('app');
var shell = require('shell');
var BrowserWindow = require('browser-window');
var menuEntries = require('./app_modules/gui/public/src/js/services/app-menu');
var windowStateKeeper = require('./vendor/electron_boilerplate/window_state');

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