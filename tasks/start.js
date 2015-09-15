var Q = require('q');
var fs = require("fs");
var asar = require("asar");
var electron = require('electron-prebuilt');
var pathUtil = require('path');
var childProcess = require('child_process');
var kill = require('tree-kill');
var utils = require('./utils');
var watch;

var gulpPath = pathUtil.resolve('./node_modules/.bin/gulp');
if (process.platform === 'win32') {
  gulpPath += '.cmd';
}

var getEintopfConfigPath = function(){
  var home = process.env.HOME;

  if (process.env.EINTOPF_HOME){
    home = process.env.EINTOPF_HOME;
  }else if (process.platform == 'win32'){
    home = process.env.USERPROFILE;
  }

  return(home + "/.eintopf").replace(/^(~|~\/)/, home);
};

var checkBackup = function(){
  var deferred = Q.defer();
  var eintopfConfig = getEintopfConfigPath();
  var vagrantFolder = eintopfConfig + "/default/.vagrant";
  var vagrantBackup = vagrantFolder + ".bk.asar";

  fs.readdir(vagrantFolder +"/machines/eintopf/virtualbox/", function(vagrantError, files){
    fs.access(vagrantBackup, function(backupError){
      if(vagrantError && backupError === null){
        return fs.unlink(vagrantBackup, function(){
          return deferred.resolve();
        });
      } else if(backupError && files.length && files.indexOf("id") !== -1){
        asar.createPackage(vagrantFolder, vagrantBackup, function(){
          return deferred.resolve();
        })
      } else if (backupError === null && files.indexOf("id") === -1){
        var packageList = asar.listPackage(vagrantBackup);
        if (packageList.indexOf("/machines/eintopf/virtualbox/id") === -1){
          return deferred.resolve();
        }
        asar.extractAll(vagrantBackup, vagrantFolder);
        return deferred.resolve();
      } else {
        return deferred.resolve();
      }
    });
  });

  return deferred.promise;
};

var runApp = function () {
  var deferred = Q.defer();

  var app = childProcess.spawn(electron, ['.'], {
    stdio: 'inherit',
    cwd: 'app'
  });

  app.on('close', function (code) {
    deferred.resolve();
  });
  return deferred.promise;
};

checkBackup().then(runApp);
