(function (ng) {

  var factoryModule = ng.module('eintopf-factories', []);

  factoryModule.factory('currentProject', [function () {
    var projectId = null;
    return {
      getProjectId: function() {
        return projectId;
      },
      setProjectId: function(value) {
        if(typeof value == "undefined") value = null;
        projectId = value;
      }
    };
  }]);

  factoryModule.factory('locksFactory', ['ipc', 'locksService', function(ipc, locksService) {
    var model = {};

    model.stream = locksService.stream;
    model.emit = locksService.emit;

    model.fromProject = function(projectId) {
      return model.stream.map(function(locks) {
        for (var key in locks) {
          if (locks.hasOwnProperty(key) && key == 'projects:' + projectId) return locks[key];
        }
        return null;
      })
      .filter();
    };

    // initial emit
    model.emit();

    return model;
  }]);

  factoryModule.factory('projectFactory', ['ipc', 'resProjectsList', 'reqProjectStart', 'reqProjectStop',
    function(ipc, resProjectsList, reqProjectStart, reqProjectStop) {
      var model = {};

      model.stream = resProjectsList;
      model.startProject = reqProjectStart.emit;
      model.stopProject = reqProjectStop.emit;

      return model;
    }
  ]);

  /**
   * original by:
   *
   * ngElectron service for AngularJS
   * (c)2015 C. Byerley @develephant
   * http://develephant.github.io/ngElectron
   * See also: https://develephant.gitgub.io/amy
   * Version 0.4.0
   *
   * customization:
   *
   * - removed diskdb
   * - removed ipc abstraction
   * - commented out unused requires
   */
  factoryModule.factory("electron", [function() {
    var o = new Object();

    //remote require
    o.require         = require('remote').require;

    //Electron api
    //o.app             = o.require('app');
    //o.browserWindow   = o.require('browser-window');
    //o.clipboard       = o.require('clipboard');
    o.dialog          = o.require('dialog');
    //o.menu            = o.require('menu');
    //o.menuItem        = o.require('menu-item');
    //o.nativeImage     = o.require('native-image');
    //o.powerMonitor    = o.require('power-monitor');
    //o.protocol        = o.require('protocol');
    //o.screen          = o.require('screen');
    //o.shell           = o.require('shell');
    //o.tray            = o.require('tray');

    //Node 11 (abridged) api
    //o.buffer          = o.require('buffer');
    //o.childProcess    = o.require('child_process');
    //o.crypto          = o.require('crypto');
    //o.dns             = o.require('dns');
    //o.emitter         = o.require('events').EventEmitter;
    //o.fs              = o.require('fs');
    //o.http            = o.require('http');
    //o.https           = o.require('https');
    //o.net             = o.require('net');
    //o.os              = o.require('os');
    //o.path            = o.require('path');
    //o.querystring     = o.require('querystring');
    //o.url             = o.require('url');
    //o.zlib            = o.require('zlib');

    return o;
  }]);

})(angular);