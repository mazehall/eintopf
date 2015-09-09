var eintopf = angular.module('eintopf', [
  'ui.router',
  'angular-kefir',
  'luegg.directives',
  'eintopf.services.socket.states'
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

/**
 * directive that emits the elements href to the server to open it in a browser window
 * only triggers in electron window
 */
eintopf.directive('electronExternalLink', function(openBrowserWindow) {
  return {
    link: function(scope, element, attr) {
      element.on('click', function(e) {
        if (!attr.href || (navigator.userAgent && !navigator.userAgent.match(/^electron/))) return false;
        e.preventDefault();
        openBrowserWindow.emit(attr.href);
      });
    }
  };
});

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
      if(typeof toState != "object" || toState.name != "cooking.projects" || ! currentProject.getProjectId()) return false;
      event.preventDefault();
      $state.go("cooking.projects.recipe", {id: currentProject.getProjectId()});
    });
});