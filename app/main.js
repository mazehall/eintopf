var app = require('app');
var BrowserWindow = require('browser-window');
var devHelper = require('./vendor/electron_boilerplate/dev_helper');
var windowStateKeeper = require('./vendor/electron_boilerplate/window_state');

var mainWindow;
var env = process.env.NODE_ENV = process.env.NODE_ENV || "development";
var port = process.env.PORT = process.env.PORT || 31313;
// Preserver of the window size and position between app launches.
var mainWindowState = windowStateKeeper('main', {
  width: 1000,
  height: 600
});

var child = require('child_process').fork('server.js', {cwd: './app'});

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

  child.on('message', function(m) {
    mainWindow.loadUrl('http://localhost:' + port);
    console.log(m);
  });
  child.send('app:startserver');

  if (env === 'development') {
    devHelper.setDevMenu();
    mainWindow.openDevTools();
  }

  mainWindow.on('close', function () {
    child.kill('SIGKILL');
    mainWindowState.saveState(mainWindow);
  });


});


app.on('window-all-closed', function () {
  app.quit();
});
