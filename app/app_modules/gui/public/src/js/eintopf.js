var eintopfApp = angular.module('eintopfApp', [
  'ui.router'
]);

eintopfApp.config(function($stateProvider, $urlRouterProvider) {
  //
  // For any unmatched url, redirect to /state1
  $urlRouterProvider.otherwise("/setup");
  //
  // Now set up the states
  $stateProvider
    .state('setup', {
      url: "/setup",
      templateUrl: "partials/setup.html"
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
