'use strict';

angular.module('eintopf.services.socket.states', [])
  .factory('socket', [function () {
    return io.connect('/states');
  }])

  .factory('setupLiveResponse', ['socket', function (socket) {
    return Kefir.fromEvent(socket, 'states:live').toProperty();
  }])

  .factory('setupRestart', ['socket', function (socket) {
    return {
      emit: function (data) {
        socket.emit('states:restart', data);
      }
    }
  }])

  .factory('reqProjectList', ['socket', function (socket) {
    return {
      emit: function () {
        socket.emit('projects:list');
      }
    }
  }])

  .factory('resProjectsList', ['socket', function (socket) {
    return Kefir.fromEvent(socket, 'res:projects:list').toProperty();
  }])

  .factory('reqProjectsInstall', ['socket', function (socket) {
    return {
      emit: function (data) {
        socket.emit('projects:install', data);
      }
    }
  }])

  .factory('resProjectsInstall', ['socket', function (socket) {
    return Kefir.fromEvent(socket, 'res:projects:install');
  }])

  .factory("backendErrors", ["socket", function(socket) {
    return Kefir.fromEvent(socket, "res:backend:errors").toProperty();
  }])

  .factory('resProjectDetail', ['socket', 'resContainersList', 'resContainersLog', 'resAppsList', 'resContainersInspect', function (socket, resContainersList, resContainersLog, resAppsList, resContainersInspect) {
    return {
      fromProject: function (project) {
        return Kefir.fromEvent(socket, 'res:project:detail:' + project);
      },
      listContainers: function (project) {
        return Kefir.combine([resContainersList, resContainersInspect])
        .throttle(2000)
        //fix against flickering when resetting inspect -> might create problems when inspecting fails due to errors
        .filter(function(value) {
          for (var key in value[1]) {
            if(!value[1][key]) return false
          }
          return true;
        })
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
          var mappedApps = []

          for (var key in apps) {
            if(apps[key]['running'] && apps[key]['project'] == project) mappedApps.push(apps[key]);
          }

          return mappedApps
        });
      }
    }
  }])

  .factory('reqProjectDetail', ['socket', function (socket) {
    return {
      emit: function (data) {
        socket.emit('project:detail', data);
      }
    }
  }])

  .factory('resProjectStart', ['socket', 'storage', function (socket, storage) {
    var streams = {};
    return {
      fromProject: function (project) {
        if (streams[project]){
          return streams[project];
        }

        streams[project] = Kefir.fromEvent(socket, 'res:project:start:' + project ).onValue(function(value){
          storage.add("project.log.start."+ project, value);
          storage.add("project.log.complete."+ project, new Date().toLocaleTimeString() +" - [start] > "+ value);
        }).toProperty();

        return streams[project];
      }
    }
  }])

  .factory('reqProjectStart', ['socket', function (socket) {
    return {
      emit: function (data) {
        socket.emit('project:start', data);
      }
    }
  }])

  .factory('resProjectStop', ['socket', 'storage', function (socket, storage) {
    var streams = {};
    return {
      fromProject: function (project) {
        if (streams[project]){
          return streams[project];
        }

        streams[project] = Kefir.fromEvent(socket, 'res:project:stop:' + project).onValue(function(value){
          storage.add("project.log.stop."+ project, value);
          storage.add("project.log.complete."+ project, new Date().toLocaleTimeString() +" - [stop] > "+ value);
        }).toProperty();

        return streams[project];
      }
    }
  }])

  .factory('reqProjectStop', ['socket', function (socket) {
    return {
      emit: function (data) {
        socket.emit('project:stop', data);
      }
    }
  }])

  .factory('resProjectDelete', ['socket', function (socket){
    return {
      fromProject: function (project){
        return Kefir.fromEvent(socket, 'res:project:delete:' + project);
      }
    }
  }])

  .factory('reqProjectDelete', ['socket', function (socket){
    return {
      emit: function (data) {
        socket.emit('project:delete', data);
      }
    }
  }])

 .factory('resProjectUpdate', ['socket', 'storage', function (socket, storage) {
    var streams = {};
    return {
      fromProject: function (project){
        if (streams[project]){
          return streams[project];
        }

        streams[project] = Kefir.fromEvent(socket, 'res:project:update:' + project).onValue(function(value){
          storage.add("project.log.update."+ project, value);
          storage.add("project.log.complete."+ project, new Date().toLocaleTimeString() +" - [update] > "+ value);
        }).toProperty();

        return streams[project];
      }
    }
  }])

  .factory('reqProjectUpdate', ['socket', function (socket){
    return {
      emit: function (data) {
        socket.emit('project:update', data);
      }
    }
  }])

 .factory('resProjectStartAction', ['socket', 'storage', function (socket, storage) {
    var streams = {};
    return {
      fromProject: function (project){
        if (streams[project]){
          return streams[project];
        }

        streams[project] = Kefir.fromEvent(socket, 'res:project:action:script:' + project).onValue(function(value){
          storage.add("project.log.action."+ project, value);
          storage.add("project.log.complete."+ project, new Date().toLocaleTimeString() +" - [action] > "+ value);
        }).toProperty();

        return streams[project];
      }
    }
  }])

  .factory('reqProjectStartAction', ['socket', function (socket){
    return {
      emit: function (data){
        socket.emit('project:action:script', data);
      }
    }
  }])

  .factory('reqContainersList', ['socket', function (socket) {
    return {
      emit: function (data) {
        socket.emit('containers:list', data);
      }
    }
  }])

  .factory('reqContainersInspect', ['socket', function (socket) {
    return {
      emit: function () {
        socket.emit('containers:inspect');
      }
    }
  }])

  .factory('resContainersList', ['socket', 'reqContainersList', function (socket, reqContainersList) {
    var containerList_ = Kefir.fromEvent(socket, 'res:containers:list').toProperty();
    reqContainersList.emit();
    containerList_.onValue(function() {});
    return containerList_;
  }])

  .factory('resContainersInspect', ['socket', 'reqContainersInspect', function (socket, reqContainersInspect) {
    var containersInspect = Kefir.fromEvent(socket, 'res:containers:inspect').toProperty();
    reqContainersInspect.emit();
    containersInspect.onValue(function() {});
    return containersInspect;
  }])

  .factory('reqAppsList', ['socket', function (socket) {
    return {
      emit: function (data) {
        socket.emit('apps:list', data);
      }
    }
  }])

  .factory('resAppsList', ['socket', 'reqAppsList', function (socket, reqAppsList) {
    var appList_ = Kefir.fromEvent(socket, 'res:apps:list').toProperty();
    reqAppsList.emit();
    appList_.onValue(function() {});
    return appList_;
  }])

  .factory('reqSettingsList', ['socket', function (socket) {
    return {
        emit: function (data) {
            socket.emit('settings:list', data);
        }
    }
  }])

  .factory('resSettingsList', ['socket', 'reqSettingsList', function (socket, reqSettingsList) {
    reqSettingsList.emit();
    return Kefir.fromEvent(socket, 'res:settings:list').toProperty();
  }])

  .factory('reqContainerActions', ['socket', function (socket) {
    return {
      start: function (containerId) {
        socket.emit('container:start', containerId);
      },
      stop: function (containerId) {
        socket.emit('container:stop', containerId);
      },
      remove: function (containerId) {
        socket.emit('container:remove', containerId);
      }
    }
  }])

  .factory('resContainersLog', ['socket', function (socket) {
    return Kefir.fromEvent(socket, 'res:containers:log');
  }])

  .factory('reqRecommendationsList', ['socket', function (socket) {
    return {
      emit: function (data) {
        socket.emit('recommendations:list', data);
      }
    }
  }])

  .factory('resRecommendationsList', ['socket', 'reqRecommendationsList', function (socket, reqRecommendationsList) {
    reqRecommendationsList.emit();
    return Kefir.fromEvent(socket, 'res:recommendations:list').toProperty();
  }])

  .factory('terminalStream', ['socket', 'storage', function (socket, storage) {
    var stream = null;

    var emit = function(cmd) {
      socket.emit('terminal:input', cmd);
    };

    var getStream = function() {
      if(stream) return stream;
      stream = Kefir.fromEvent(socket, 'terminal:output')
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

;
