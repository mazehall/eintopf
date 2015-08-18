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

  .factory('resProjectStart', ['socket', function (socket) {
    return {
      fromProject: function (project) {
        return Kefir.fromEvent(socket, 'res:project:start:' + project ).toProperty();
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

  .factory('resProjectStop', ['socket', function (socket) {
    return {
      fromProject: function (project) {
        return Kefir.fromEvent(socket, 'res:project:stop:' + project ).toProperty();
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

  .factory('reqAppsList', ['socket', function (socket) {
    return {
      emit: function (data) {
        socket.emit('apps:list', data);
      }
    }
  }])

  .factory('resAppsList', ['socket', 'reqAppsList', function (socket, reqAppsList) {
    reqAppsList.emit();
    return Kefir.fromEvent(socket, 'res:apps:list').toProperty();
  }])


;
