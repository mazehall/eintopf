'use strict';

const ipcRenderer = require('electron').ipcRenderer;

angular.module('eintopf.services.ipc', [])
.factory('ipc', [function () {
  var ipc = {};

  ipc.toKefir = function(eventName) {
    return Kefir.fromEvent(ipcRenderer, eventName, function(event, value) {
      return value;
    })
  };
  ipc.emit = function(eventName, value) {
    if (!eventName) return false;
    ipcRenderer.send(eventName, value);
  };

  return ipc;
}])

.service('setupLiveResponse', ['ipc', function (ipc) {
  return ipc.toKefir('states:live').toProperty();
}])

.service('resProjectsList', ['ipc', function (ipc) {
  return ipc.toKefir('res:projects:list').toProperty();
}])

.service('resProjectsInstall', ['ipc', function (ipc) {
  return ipc.toKefir('res:projects:install');
}])

.service("backendErrors", ["ipc", function(ipc) {
  return ipc.toKefir('res:backend:errors').toProperty();
}])

.service('resContainersLog', ['ipc', function (ipc) {
  return ipc.toKefir('res:containers:log');
}])

.service('resProjectDelete', ['ipc', function (ipc){
  return {
    fromProject: function (project){
      return ipc.toKefir('res:project:delete:' + project);
    }
  }
}])

.service('resSettingsList', ['ipc', 'reqSettingsList', function (ipc, reqSettingsList) {
  reqSettingsList.emit();
  return ipc.toKefir('res:settings:list').toProperty();
}])

.service('resRecommendationsList', ['ipc', 'reqRecommendationsList', function (ipc, reqRecommendationsList) {
  reqRecommendationsList.emit();
  return ipc.toKefir('res:recommendations:list').toProperty();
}])

.service('setupRestart', ['ipc', function (ipc) {
  return {
    emit: function (data) {
      ipc.emit('states:restart', data);
    }
  }
}])

.service('reqProjectList', ['ipc', function (ipc) {
  return {
    emit: function () {
      ipc.emit('projects:list');
    }
  }
}])

.service('reqProjectsInstall', ['ipc', function (ipc) {
  return {
    emit: function (data) {
      ipc.emit('projects:install', data);
    }
  }
}])

.service('reqProjectDetail', ['ipc', function (ipc) {
  return {
    emit: function (data) {
      ipc.emit('project:detail', data);
    }
  }
}])

.service('reqProjectStart', ['ipc', function (ipc) {
  return {
    emit: function (data) {
      ipc.emit('project:start', data);
    }
  }
}])

.service('reqProjectStop', ['ipc', function (ipc) {
  return {
    emit: function (data) {
      ipc.emit('project:stop', data);
    }
  }
}])

.service('reqProjectDelete', ['ipc', function (ipc){
  return {
    emit: function (data) {
      ipc.emit('project:delete', data);
    }
  }
}])

.service('reqProjectUpdate', ['ipc', function (ipc){
  return {
    emit: function (data) {
      ipc.emit('project:update', data);
    }
  }
}])

.service('reqProjectAction', ['ipc', function (ipc){
  return {
    emit: function (data){
      ipc.emit('project:action:script', data);
    }
  }
}])

.service('reqContainersList', ['ipc', function (ipc) {
  return {
    emit: function (data) {
      ipc.emit('containers:list', data);
    }
  }
}])

.service('reqContainersInspect', ['ipc', function (ipc) {
  return {
    emit: function () {
      ipc.emit('containers:inspect');
    }
  }
}])

.service('reqRecommendationsList', ['ipc', function (ipc) {
  return {
    emit: function (data) {
      ipc.emit('recommendations:list', data);
    }
  }
}])

.factory('reqSettingsList', ['ipc', function (ipc) {
  return {
    emit: function (data) {
      ipc.emit('settings:list', data);
    }
  }
}])

.service('reqAppsList', ['ipc', function (ipc) {
  return {
    emit: function (data) {
      ipc.emit('apps:list', data);
    }
  }
}])

.service('resContainersList', ['ipc', 'reqContainersList', function (ipc, reqContainersList) {
  var containerList_ = ipc.toKefir('res:containers:list').toProperty();
  reqContainersList.emit();
  containerList_.onValue(function() {});
  return containerList_;
}])

.service('resContainersInspect', ['ipc', 'reqContainersInspect', function (ipc, reqContainersInspect) {
  var containersInspect = ipc.toKefir('res:containers:inspect').toProperty();
  reqContainersInspect.emit();
  containersInspect.onValue(function() {});
  return containersInspect;
}])

.service('resAppsList', ['ipc', 'reqAppsList', function (ipc, reqAppsList) {
  var appList_ = ipc.toKefir('res:apps:list').toProperty();
  reqAppsList.emit();
  appList_.onValue(function() {});
  return appList_;
}])

.service('reqContainerActions', ['ipc', function (ipc) {
  return {
    start: function (containerId) {
      ipc.emit('container:start', containerId);
    },
    stop: function (containerId) {
      ipc.emit('container:stop', containerId);
    },
    remove: function (containerId) {
      ipc.emit('container:remove', containerId);
    }
  }
}])

.factory('resProjectStart', ['ipc', 'storage', function (ipc, storage) {
  var streams = {};
  return {
    fromProject: function (project) {
      if (streams[project]){
        return streams[project];
      }

      streams[project] = ipc.toKefir('res:project:start:' + project ).onValue(function(value){
        storage.add("project.log.start."+ project, value);
        storage.add("project.log.complete."+ project, new Date().toLocaleTimeString() +" - [start] > "+ value);
      }).toProperty();

      return streams[project];
    }
  }
}])

.factory('resProjectStop', ['ipc', 'storage', function (ipc, storage) {
  var streams = {};
  return {
    fromProject: function (project) {
      if (streams[project]){
        return streams[project];
      }

      streams[project] = ipc.toKefir('res:project:stop:' + project).onValue(function(value){
        storage.add("project.log.stop."+ project, value);
        storage.add("project.log.complete."+ project, new Date().toLocaleTimeString() +" - [stop] > "+ value);
      }).toProperty();

      return streams[project];
    }
  }
}])

.factory('resProjectUpdate', ['ipc', 'storage', function (ipc, storage) {
  var streams = {};
  return {
    fromProject: function (project){
      if (streams[project]){
        return streams[project];
      }

      streams[project] = ipc.toKefir('res:project:update:' + project).onValue(function(value){
        storage.add("project.log.update."+ project, value);
        storage.add("project.log.complete."+ project, new Date().toLocaleTimeString() +" - [update] > "+ value);
      }).toProperty();

      return streams[project];
    }
  }
}])

.factory('resProjectAction', ['ipc', 'storage', function (ipc, storage) {
  var streams = {};
  return {
    fromProject: function (project){
      if (streams[project]){
        return streams[project];
      }

      streams[project] = ipc.toKefir('res:project:action:script:' + project).onValue(function(value){
        storage.add("project.log.action."+ project, value);
        storage.add("project.log.complete."+ project, new Date().toLocaleTimeString() +" - [action] > "+ value);
      }).toProperty();

      return streams[project];
    }
  }
}])

.factory('terminalStream', ['ipc', 'storage', function (ipc, storage) {
  var stream = null;

  var emit = function(cmd) {
    ipc.emit('terminal:input', cmd);
  };

  var getStream = function() {
    if(stream) return stream;
    stream = ipc.toKefir('terminal:output')
      //.onValue(function(value) {
      //  //value = value.replace(/\n/ig, "<br>");
      //  storage.add("vagrant.log", new Date().toLocaleTimeString() + " > " + value);
      //})
      .filter(function(val) {
        if(val && val.text) return true;
      })
      .toProperty();
    return stream;
  };

  return {
    emit: emit,
    getStream: getStream
  }
}])

.factory('resProjectDetail', ['ipc', 'resContainersList', 'resContainersLog', 'resAppsList', 'resContainersInspect', function (ipc, resContainersList, resContainersLog, resAppsList, resContainersInspect) {
  return {
    fromProject: function (project) {
      return ipc.toKefir('res:project:detail:' + project);
    },
    listContainers: function (project) {
      return Kefir.combine([resContainersList, resContainersInspect])
        .throttle(2000)
        .map(function (value) {
          var mappedContainers = {};
          var containers = value[1];

          for (var key in containers) {
            if(containers[key] && containers[key].project && containers[key].project == project) {
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
            if(value[1][containers[key].Id]) mappedContainers[containers[key].name] = containers[key];
          }

          return mappedContainers;
        });
    },
    listApps: function(project){
      return resAppsList.map(function(apps){
        var mappedApps = [];

        for (var key in apps) {
          if(apps[key]['running'] && apps[key]['project'] == project) mappedApps.push(apps[key]);
        }

        return mappedApps
      });
    }
  }
}])

;
