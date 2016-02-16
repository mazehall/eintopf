var Q = require('q');
var electron = require('electron-prebuilt');
var pathUtil = require('path');
var childProcess = require('child_process');

var gulpPath = pathUtil.resolve('./node_modules/.bin/gulp');
if (process.platform === 'win32') {
  gulpPath += '.cmd';
}

var runApp = function () {
  var deferred = Q.defer();

  var app = childProcess.spawn(electron, ['.'], {
    stdio: 'inherit'
  });

  app.on('close', function (code) {
    deferred.resolve();
  });
  return deferred.promise;
};

runApp();
