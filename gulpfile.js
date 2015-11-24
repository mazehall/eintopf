'use strict';
var gulp = require('gulp');
var utils = require('./tasks/utils');
var jetpack = require('fs-jetpack');
var exec = require("child_process").exec;

var releaseForOs = {
  osx: require('./tasks/release_osx'),
  linux: require('./tasks/release_linux'),
  windows: require('./tasks/release_windows')
};

gulp.task('build', function() {
  return require('./tasks/build.js')();
});

gulp.task("copy", function() {
  var buildDir = jetpack.cwd("./build").dir(".", {empty: true});

  return jetpack.copy("./app", buildDir.path(), {
    overwrite: true
  });
});

gulp.task("cleanup dependencies", ["copy"], function() {

  /**
   * remove all packages specified in the 'devDependencies' section
   *
   * runs postinstall again to fix missing optional dependencies
   */

  var buildDir = jetpack.cwd("./build").dir(".");
  var process = exec("npm prune --production && npm run postinstall", {cwd: buildDir.path()});

  return process.stdout;
});

gulp.task('release', ['cleanup dependencies'], function () {
  return releaseForOs[utils.os()]();
});
