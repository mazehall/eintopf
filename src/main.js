require('coffee-script/register');
var app = require('app');
var shell = require('shell');
var BrowserWindow = require('browser-window');
var windowStateKeeper = require('./utils/window_state');
var Menu = require('menu');

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

initMenu = function () {
  //if (Menu.getApplicationMenu()) return; // ignore if menu is present

  var template = [
    {
      label: app.getName(),
      submenu: [
        {
          label: "About", click: function () {
          shell.openExternal('https://github.com/mazehall/eintopf');
        }
        },
        {type: "separator"},
        {
          label: "Reload", accelerator: "CmdOrCtrl+R", click: function (item, focusedWindow) {
          if (focusedWindow) focusedWindow.reload();
        }
        },
        {type: "separator"},
        {
          label: "Quit", accelerator: "CmdOrCtrl+Q", click: function () {
          app.quit();
        }
        },
        {type: "separator"},
        {
          label: app.getName()+ " v" +app.getVersion(),
          enabled: false
        }
      ]
    }
  ];

  if (process.platform == 'darwin') { // set edit actions for OS X
    template.push({
      label: "Edit",
      submenu: [
        {label: "Undo", accelerator: "CmdOrCtrl+Z", selector: "undo:"},
        {label: "Redo", accelerator: "Shift+CmdOrCtrl+Z", selector: "redo:"},
        {type: "separator"},
        {label: "Cut", accelerator: "CmdOrCtrl+X", selector: "cut:"},
        {label: "Copy", accelerator: "CmdOrCtrl+C", selector: "copy:"},
        {label: "Paste", accelerator: "CmdOrCtrl+V", selector: "paste:"},
        {label: "Select All", accelerator: "CmdOrCtrl+A", selector: "selectAll:"}
      ]
    });
  }

  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
};

instance = app.makeSingleInstance(function() {
  if (mainWindow.isMinimized()){
    mainWindow.restore()
  }

  mainWindow.focus();

  return true;
});

app.on('ready', function () {
  initMenu();

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
  app.quit();
});

if (instance){
  return app.quit();
}