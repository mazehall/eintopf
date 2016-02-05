var eintopf = angular.module('eintopf', [
  'ui.router',
  'angular-kefir',
  'vtortola.ng-terminal',
  'luegg.directives',
  'hc.marked',
  'eintopf.services.socket.states',
  'eintopf.services.storage'
]);

eintopf.factory('currentProject', [function () {
  var projectId = null;
  return {
    getProjectId: function() {
      return projectId;
    },
    setProjectId: function(value) {
      if(typeof value == "undefined") value = null;
      projectId = value;
    }
  };
}]);

eintopf.config(['terminalConfigurationProvider', function (terminalConfigurationProvider) {
  terminalConfigurationProvider.inputOnlyMode = true;
  terminalConfigurationProvider.promptConfiguration = { end: '', user: '', separator: '', path: '' };
}]);

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

    .state('error', {
      url: "/error?{code}{message}",
      templateUrl: "partials/error.html",
      controller: "errorCtrl"
    })

    .state('cooking', {
      abstract: true,
      url: "/cooking",
      templateUrl: 'partials/cooking.html'
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
    .state('cooking.containers', {
      url: "/containers",
      controller: "containersCtrl",
      templateUrl: "partials/cooking.containers.html"
    })
    .state('cooking.settings', {
      url: "/settings",
      controller: "settingsCtrl",
      templateUrl: "partials/cooking.settings.html"
    })
    .state('cooking.apps', {
      url: "/apps",
      controller: "appsCtrl",
      templateUrl: "partials/cooking.apps.html"
    });

});

// set current project state when changing projects state
eintopf.run(function($rootScope, $state, currentProject) {
  $rootScope.$on('$stateChangeStart',
    function(event, toState, toParams, fromState, fromParams){
      if(typeof toState != "object" || toState.name != "cooking.projects") return false;
      event.preventDefault();
      if (! currentProject.getProjectId()) return $state.go("cooking.projects.create");
      $state.go("cooking.projects.recipe", {id: currentProject.getProjectId()});
    });
});