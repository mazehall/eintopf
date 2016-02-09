'use strict';

var app = angular.module('eintopf', ['angular.panels']);

app.config(['panelsProvider', function (panelsProvider) {

  panelsProvider
      .add({
        id: 'panelmenu',
        position: 'right',
        size: '700px',
        templateUrl: '../partials/panelmenu.html',
        controller: 'panelmenuCtrl'
      })
      .add({
        id: '' +
        'panelcontent',
        position: 'right',
        size: '80%',
        templateUrl: '../partials/panelcontent.html',
        controller: 'panelcontentCtrl',
        closeCallbackFunction: 'panelClose'
      });
}]);