var eintopf = angular.module('eintopf', [
  'ui.router',
  'eintopf.services.socket.setup'
]);

eintopf.config(function($stateProvider, $urlRouterProvider) {
  //
  // For any unmatched url, redirect to /state1
  $urlRouterProvider.otherwise("/setup");
  //
  // Now set up the states
  $stateProvider
    .state('setup', {
      url: "/setup",
      templateUrl: "partials/setup.html",
      controller: "setupCtrl"
    })
    .state('cooking', {
      url: "/cooking",
      templateUrl: "partials/cooking.html"
    })
    .state('cooking.projects', {
      url: "/projects",
      templateUrl: "partials/state2.list.html",
      controller: function($scope) {
        $scope.things = ["A", "Set", "Of", "Things"];
      }
    });
});
