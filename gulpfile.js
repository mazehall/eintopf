'use strict';
var gulp = require('gulp');
var utils = require('./tasks/utils');
var jetpack = require('fs-jetpack');

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

/**
 * @todo build release app without dev dependencies
 */
gulp.task('release', ['build', 'copy'], function () {
  return releaseForOs[utils.os()]();
});
