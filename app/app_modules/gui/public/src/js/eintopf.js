var eintopf = angular.module('eintopf', [
  'ui.router',
  'angular-kefir',
  'eintopf.services.socket.states'
]);

eintopf.config(function($stateProvider, $urlRouterProvider) {
  //
  //// For any unmatched url, redirect to /state1
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
      templateUrl: 'partials/cooking.html',
      controller: 'cookingCtrl'
    })
    .state('cooking.recipe', {
      url: "/cooking/recipe/{id}",
      controller: "recipeCtrl",
      templateUrl: "partials/cooking.recipe.html"
    })
    .state('cooking.createProject', {
      url: "/cooking/createProject",
      controller: "createProjectCtrl",
      templateUrl: "partials/cooking.createProject.html"
    })
    .state('apps', {
      url: "/apps",
      controller: "appsCtrl",
      templateUrl: "partials/apps.html"
    });

});