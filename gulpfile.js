'use strict';
var gulp = require('gulp');
var utils = require('./tasks/utils');

var releaseForOs = {
  osx: require('./tasks/release_osx'),
  linux: require('./tasks/release_linux'),
  windows: require('./tasks/release_windows'),
};

gulp.task('build', function() {
  return require('./tasks/build.js')
});

gulp.task('release', ['build'], function () {
  return releaseForOs[utils.os()]();
});
