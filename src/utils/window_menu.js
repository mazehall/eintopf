var app  = require('app');
var Menu = require('menu');


var template = [
  {
    label: app.getName(),
    submenu: [
      {
        label: "About", click: function () {
          shell.openExternal('https://github.com/mazehall/eintopf');
      }},
      {type: "separator"},
      {
        label: "Reload", accelerator: "CmdOrCtrl+R", click: function (item, focusedWindow) {
          if (focusedWindow) focusedWindow.reload();
      }},
      {type: "separator"},
      {
        label: "Quit", accelerator: "CmdOrCtrl+Q", click: function () {
          app.quit();
      }},
      {type: "separator"},
      {
        label: app.getName()+ " v" +app.getVersion(),
        enabled: false
      }
    ]
  }
];

var devMenu = {
  label: 'Development',
  submenu: [
    {
      label: 'Toggle Developer Tools',
      accelerator: (function() {
        if (process.platform == 'darwin')
          return 'Alt+Command+I';
        else
          return 'Ctrl+Shift+I';
      })(),
      click: function(item, focusedWindow) {
        if (focusedWindow) focusedWindow.toggleDevTools();
    }}
  ]
};

var macMenu = {
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
};

var model = {};

model.init = function () {
  if (process.platform == 'darwin') template.push(macMenu);
  if (process.env.NODE_ENV === 'development') template.push(devMenu);

  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
};

module.exports = model;