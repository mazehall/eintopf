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

  factoryModule.factory('lockFactory', ['ipc', 'lockService', function(ipc, lockService) {
    var model = {};

    model.stream = lockService.stream;
    model.emit = lockService.emit;

    model.assignFromProject = function(projectId, scope, property) {
      ipc.toKefirDestroyable(scope, model.stream)
      .map(function(locks) {
        for (var key in locks) {
          if (locks.hasOwnProperty(key) && key == 'projects:' + projectId) return locks[key];
        }
        return false;
      })
      .$assignProperty(scope, property);
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

  factoryModule.factory('containerFactory',
    ['ipc', 'resContainersList', 'reqContainersList', 'reqContainerStart', 'reqContainerStop', 'reqContainerRemove', 'resContainersLog',
      function(ipc, resContainersList, reqContainersList,reqContainerStart, reqContainerStop, reqContainerRemove, resContainersLog) {
        var model = {};

        model.stream = resContainersList;
        model.logStream = resContainersLog;
        model.emit = reqContainersList.emit;
        model.startContainer = reqContainerStart.emit;
        model.stopContainer = reqContainerStop.emit;
        model.removeContainer = reqContainerRemove.emit;

        model.assignFromProject = function(projectId, scope, property) {
          ipc.toKefirDestroyable(scope, model.stream)
          .map(function(containers) {
            var result = [];

            for (var key in containers) {
              if (containers.hasOwnProperty(key) && (containers[key].project === projectId)) result.push(containers[key]);
            }

            return result;
          })
          .$assignProperty(scope, property);
        };

        model.pushFromLogs = function(scope, property) {
          scope[property] = [];

          ipc.toKefirDestroyable(scope, resContainersLog)
          .filter(function (x) {
            if (x.message) return true;
          })
          .onValue(function (val) {
            val.read = false;
            scope[property].push(val);
          });
        };

        return model;
      }
    ]
  );

  // @todo reevaluate
  factoryModule.factory('resProjectDetail',
    ['ipc', 'resContainersList', 'resContainersLog', 'resAppsList', 'resContainersInspect',
      function (ipc, resContainersList, resContainersLog, resAppsList, resContainersInspect) {
        return {
          fromProject: function (project) {
            return ipc.toKefir('res:project:detail:' + project);
          },
          listContainers: function (project) {
            return resContainersList
            .filter(function(containers) {
              for (var key in containers) {
                if (containers.hasOwnProperty(key) && (containers[key].project != project)) delete containers[key];
              }

              return containers;
            }).log();

            return Kefir.combine([resContainersList, resContainersInspect])
            .throttle(2000)
            .map(function (value) {
              var mappedContainers = {};
              var containers = value[1];

              for (var key in containers) {
                if (containers[key] && containers[key].project && containers[key].project == project) {
                  mappedContainers[containers[key].Id] = containers[key];
                }
              }

              value[1] = mappedContainers;
              return value;
            })
            .map(function (value) {
              var mappedContainers = {};
              var containers = value[0];

              for (var key in containers) {
                if (value[1][containers[key].Id]) mappedContainers[containers[key].name] = containers[key];
              }

              return mappedContainers;
            }).log();
          },
          listApps: function (project) {
            return resAppsList.map(function (apps) {
              var mappedApps = [];

              for (var key in apps) {
                if (apps[key]['running'] && apps[key]['project'] == project) mappedApps.push(apps[key]);
              }

              return mappedApps
            });
          }
        }
      }
    ]
  );

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