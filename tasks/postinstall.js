'use strict';

if(process.platform == 'win32') {
  return true;
}

var childProcess = require('child_process');
var jetpack = require('fs-jetpack');

if (jetpack.exists('node_modules/pty.js')) return false;

var installCommand = null;
if (process.platform === 'win32') {
  installCommand = 'npm.cmd'
} else {
  installCommand = 'npm'
}

var params = ['install', 'pty.js'];

var install = childProcess.spawn(installCommand, params, {
    cwd: process.cwd(),
    env: process.env,
    stdio: 'inherit'
});
