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

  .factory('resProjectsList', ['socket', function (socket) {
    return Kefir.fromEvent(socket, 'res:projects:list').toProperty();
  }]);



