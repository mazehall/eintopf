var mazehall = require('mazehall');
var express = require('express');


var app, server;
app = express();
server = require('http').Server(app);
mazehall.moduleStream.log('module loader');
mazehall.initPlugins(app);
mazehall.initExpress(app);
module.exports = server;
