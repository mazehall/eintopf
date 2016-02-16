// This script allows you to install native modules (those which have
// to be compiled) for your Electron app.
// The problem is that 'npm install' compiles them against node.js you have
// installed on your computer, NOT against node.js used in Electron
// runtime we've downloaded to this project.

'use strict';

var childProcess = require('child_process');
var jetpack = require('fs-jetpack');
var utils = require('./utils');

var electronVersion = utils.getElectronVersion();

var nodeModulesDir = jetpack.cwd(__dirname + '/../node_modules');
var dependenciesCompiledAgainst = nodeModulesDir.read('electron_version');

// When you raised version of Electron used in your project, the safest
// thing to do is remove all installed dependencies and install them
// once again (so they compile against new version if you use any
// native package).
if (electronVersion !== dependenciesCompiledAgainst) {
    nodeModulesDir.dir('.', { empty: true });
    nodeModulesDir.write('electron_version', electronVersion);
}

// Tell the 'npm install' which is about to start that we want for it
// to compile for Electron.
process.env.npm_config_disturl = "https://atom.io/download/atom-shell";
process.env.npm_config_target = electronVersion;

var params = ['install'];
// Maybe there was name of package user wants to install passed as a parameter.
if (process.argv.length > 2) {
    params.push(process.argv[2]);
    params.push('--save');
}


var installCommand = null;

if (process.platform === 'win32') {
  installCommand = 'npm.cmd'
} else {
  installCommand = 'npm'
}

var install = childProcess.spawn(installCommand, params, {
    cwd: __dirname + '/..',
    env: process.env,
    stdio: 'inherit'
});
