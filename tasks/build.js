var Q = require('q');
var pathUtil = require('path');
var childProcess = require('child_process');
var utils = require('./utils');

var gulpPath = pathUtil.resolve('./node_modules/.bin/gulp');
if (process.platform === 'win32') {
  gulpPath += '.cmd';
}

var buildGui = function () {
  var deferred = Q.defer();
  var build = childProcess.spawn(gulpPath, [
    'build',
    '--env=' + utils.getEnvName(),
    '--color'
  ], {
    cwd: './app/app_modules/gui',
    stdio: 'inherit'
  });
  build.on('close', function (code) {
    deferred.resolve();
  });

  return deferred.promise;
};

module.exports = function () {
  return Q.all([
    buildGui()
  ]);
};
