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
      emit: function (data) {
        socket.emit('projects:list', data);
      }
    }
  }])

  .factory('resProjectsList', ['socket', 'reqProjectList', function (socket, reqProjectList) {
    reqProjectList.emit();
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
    return Kefir.fromEvent(socket, 'res:projects:install').toProperty();
  }])

  .factory('resProjectDetail', ['socket', function (socket) {
    return Kefir.fromEvent(socket, 'res:project:detail').toProperty();
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

  .factory('resContainersList', ['socket', 'reqContainersList', function (socket, reqContainersList) {
    var containerList_ = Kefir.fromEvent(socket, 'res:containers:list')
      .toProperty();
    reqContainersList.emit();
    Kefir.fromPoll(2000, reqContainersList.emit)
      .onValue(function() {});
    return containerList_;
  }])

  .factory('reqAppsList', ['socket', function (socket) {
    return {
      emit: function (data) {
        socket.emit('apps:list', data);
      }
    }
  }])

  .factory('resAppsList', ['socket', 'reqAppsList', function (socket, reqAppsList) {
    var appList_ = Kefir.fromEvent(socket, 'res:apps:list')
      .toProperty();
    reqAppsList.emit();
    Kefir.fromPoll(2000, reqAppsList.emit)
      .onValue(function() {});
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

;
