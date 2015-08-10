var mazehall = require('mazehall');
var express = require('express');
require('coffee-script/register');

var app, server;
app = express();

server = require('http').Server(app);
var io = require('socket.io')(server, { serveClient: false });
app.set('io', io);

mazehall.moduleStream.log('module loader');
mazehall.initPlugins(app);
mazehall.initExpress(app);
module.exports = server;
