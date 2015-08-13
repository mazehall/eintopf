var eintopf = angular.module('eintopf', [
  'ui.router',
  'angular-kefir',
  'eintopf.services.socket.states'
]);

eintopf.config(function($stateProvider, $urlRouterProvider) {
  //
  //// For any unmatched url, redirect to /state1
  //$urlRouterProvider.otherwise("/setup");
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
    });
});

eintopf.run(function($state, statesLiveResponse) {
  statesLiveResponse.onValue(function (states) {
    if(states.state) {
      $state.go(states.state);
    }
  });
});