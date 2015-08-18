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
    .state('first', {
      url: "/first",
      templateUrl: "partials/first.html",
      controller: "firstCtrl"
    })
    .state('setup', {
      url: "/setup",
      templateUrl: "partials/setup.html",
      controller: "setupCtrl"
    })

    .state('cooking', {
      abstract: true,
      url: "/cooking",
      templateUrl: 'partials/cooking.html',
    })
    .state('cooking.projects', {
      url: "/projects",
      templateUrl: "partials/cooking.projects.html",
      controller: 'cookingCtrl'
    })
    .state('cooking.projects.recipe', {
      url: "/recipe/{id}",
      controller: "recipeCtrl",
      templateUrl: "partials/cooking.projects.recipe.html"
    })
    .state('cooking.projects.create', {
      url: "/create",
      controller: "createProjectCtrl",
      templateUrl: "partials/cooking.projects.create.html"
    })
    .state('cooking.apps', {
      url: "/apps",
      controller: "appsCtrl",
      templateUrl: "partials/apps.html"
    });

});
