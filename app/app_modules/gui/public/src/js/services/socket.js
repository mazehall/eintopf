'use strict';

angular.module('eintopf.services.socket.setup', [])
  .factory('socket', [function () {
    return io.connect('/setup');
  }])

  .factory('setupLiveResponse', ['socket', function (socket) {
    return Kefir.fromEvent(socket, 'setup:live').toProperty();
  }])

