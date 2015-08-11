'use strict';

angular.module('eintopf.services.socket.setup', [])
  .factory('socket', [function () {
    return io.connect('/setup');
  }])

  .factory('setupLiveResponse', ['socket', function (socket) {
    return Kefir.fromEvent(socket, 'setup:live').toProperty();
  }])

  .factory('setupRestart', ['socket', function (socket) {
    return {
      emit: function (data) {
        socket.emit('setup:restart', data);
      }
    }
  }])

