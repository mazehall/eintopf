require('coffee-script/register');
var app = require('app');
var shell = require('shell');
var BrowserWindow = require('browser-window');
var windowStateKeeper = require('./utils/window_state');
var windowMenu = require('./utils/window_menu');

// set path env
process.env.ELECTRON_APP_DIR = app.getAppPath();
process.env.NODE_CONFIG_DIR = process.env.ELECTRON_APP_DIR + '/config';

var application = require('./app.coffee');
var mainWindow, webContents, instance;
// Preserver of the window size and position between app launches.
var mainWindowState = windowStateKeeper('main', {
  width: 1000,
  height: 600
});

instance = app.makeSingleInstance(function() {
  if (mainWindow.isMinimized()){
    mainWindow.restore()
  }

  mainWindow.focus();

  return true;
});

app.on('ready', function () {
  windowMenu.init();

  mainWindow = new BrowserWindow({
    minWidth: 768,
    minHeight: 500,
    x: mainWindowState.x,
    y: mainWindowState.y,
    width: mainWindowState.width,
    height: mainWindowState.height
  });
  webContents = mainWindow.webContents;

  if (mainWindowState.isMaximized) {
    mainWindow.maximize();
  }

  if (process.env.NODE_ENV === 'development') {
    mainWindow.openDevTools();
  }

  mainWindow.on('close', function () {
    mainWindowState.saveState(mainWindow);
  });

  // behavior for normal a hrefs
  webContents.on("will-navigate", function (event, url) {
    event.preventDefault();
    if (url.match(/^http/)) shell.openExternal(url);
  });

  // behavior for '_blank' a hrefs
  webContents.on('new-window', function(event, url){
    event.preventDefault();
    if (url.match(/^http/)) shell.openExternal(url);
  });

  process.on('uncaughtException', function(e) {
    console.log('uncaught Exception:', e);
  });

  mainWindow.loadURL('file://' + __dirname + '/public/index.html');

  // start Eintopf
  application(webContents);
});

app.on('window-all-closed', function () {
  require('./models/util/terminal.coffee').killPty(); // terminate lose pty instance
  app.quit();
});

if (instance){
  return app.quit();
}