var app = require('app');
var BrowserWindow = require('browser-window');
var menuEntries = require('./app_modules/gui/public/src/js/services/app-menu');
var windowStateKeeper = require('./vendor/electron_boilerplate/window_state');
var server = require('./server.js');

var mainWindow;
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

  if (mainWindowState.isMaximized) {
    mainWindow.maximize();
  }

  process.on('app:serverstarted', function() {
    mainWindow.loadUrl('http://localhost:' + port, {userAgent: "electron"});
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
