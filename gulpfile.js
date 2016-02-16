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

gulp.task("copy", function() {
  var buildDir = jetpack.cwd("./build").dir(".", {empty: true});

  return jetpack.copyAsync("./src", buildDir.path('src'), {overwrite: true})
  .then(function() {
    jetpack.copy("./config", buildDir.path('config'), {overwrite: true});
  })
  .then(function() {
    jetpack.copy("./package.json", buildDir.path('package.json'), {overwrite: true});
  })
  .then(function() {
    jetpack.copy("./tasks", buildDir.path('tasks'), {overwrite: true});
  });
});

gulp.task("cleanup dependencies", ["copy"], function(cb) {
  var buildDir = jetpack.cwd("./build").dir(".");

  // install all packages against the electron nodejs
  exec("npm run app-install --production", {cwd: buildDir.path()}, cb);
});

gulp.task('release', ['cleanup dependencies'], function () {
  return releaseForOs[utils.os()]();
});
