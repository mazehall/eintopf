'use strict';

function initElectronContextMenu() {
  var remote = require("remote");
  var Menu = remote.require("menu");
  var MenuItem = remote.require("menu-item");
  var clipboard = require("clipboard");
  var contextMenu = new Menu();

  var cut = new MenuItem({
    label: "Cut",
    click: function(){
      document.execCommand("cut");
    }
  });

  var copy = new MenuItem({
    label: "Copy",
    click: function(){
      document.execCommand("copy");
    }
  });

  var paste = new MenuItem({
    label: "Paste",
    click: function(){
      document.execCommand("paste");
    }
  });
  var copyLink = new MenuItem({
    label: "Copy Link Location"
  });

  contextMenu.append(cut);
  contextMenu.append(copy);
  contextMenu.append(paste);
  contextMenu.append(copyLink);

  document.addEventListener("contextmenu", function(event){
    cut.visible = paste.visible = copy.visible = copyLink.visible = false;

    if (event.target.nodeName === "TEXTAREA" || event.target.nodeName === "INPUT"){
      cut.visible = paste.visible = copy.visible = true;
    }

    if (event.target.nodeName === "A" && event.target.href){
      copyLink.visible = true;
      copyLink.click = clipboard.writeText(event.target.href);
    }

    if (window.getSelection().toString()){
      copy.visible = true;
    }

    if (paste.visible || copy.visible || copyLink.visible) {
      contextMenu.popup(remote.getCurrentWindow());
    }

    return event.preventDefault();
  }, false);
}

if(navigator && navigator.userAgent == "electron") initElectronContextMenu();
