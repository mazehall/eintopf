var app = require('app');
var shell = require('shell');
var BrowserWindow = require('browser-window');
var menuEntries = require('./app_modules/gui/public/src/js/services/app-menu');
var windowStateKeeper = require('./vendor/electron_boilerplate/window_state');
var Menu = require('menu');

process.cwd = app.getAppPath;

var server = require('./server.js');
var mainWindow, webContents;
var env = process.env.NODE_ENV = process.env.NODE_ENV || "development";
var port = process.env.PORT = process.env.PORT || 31313;
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

  process.on('app:serverstarted', function () {
    var appUrl = "http://localhost:" + port;
    mainWindow.loadUrl(appUrl, {userAgent: "electron"});
    webContents.on("will-navigate", function (event, targetUrl) {
      if (targetUrl.indexOf(appUrl) === -1) {
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