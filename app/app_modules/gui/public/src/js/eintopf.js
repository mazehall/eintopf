var eintopf = angular.module('eintopf', [
  'ui.router',
  'angular-kefir',
  'vtortola.ng-terminal',
  'luegg.directives',
  'hc.marked',
  'eintopf.services.socket.states',
  'eintopf.services.storage',
  'angular.panels',
  'nsPopover',
  'ct.ui.router.extras.core',
  'ct.ui.router.extras.sticky',
  'ct.ui.router.extras.previous'
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


eintopf.config(['panelsProvider', function (panelsProvider) {
  panelsProvider
      .add({
        id: 'panelcontent',
        position: 'right',
        size: '60%',
        templateUrl: 'partials/panel.renderer.html',
        controller: 'panelCtrl',
        closeCallbackFunction: function($scope) {
          if($scope.previousState.get('panel').state != null) $scope.previousState.go('panel'); // previousState must be set in controller scope due to loss of injector
        }
      });
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
      sticky: true,
      url: "/cooking",
      templateUrl: 'partials/cooking.html'
    })

    .state('panel', {
      abstract: true,
      url: "/panel",
      views: {
        'panel': {
          templateUrl: 'partials/panelcontent.html'
        }
      },
      onEnter: function (panels, $previousState) {
        $previousState.memo("panel"); // remember the previous state with memoName "panel"
        panels.open('panelcontent');
      }
    })
    .state('panel.main', {
      url: "/main",
      views: {
        'panelContent': {
          controller: 'panelMainCtrl',
          templateUrl: 'partials/panel.main.html'
        }
      }
    })
    .state('panel.containers', {
      url: "/containers",
      views: {
        'panelContent': {
          controller: 'panelContainersCtrl',
          templateUrl: 'partials/cooking.containers.html'
        }
      }
    })
    .state('panel.apps', {
      url: "/apps",
      views: {
        'panelContent': {
          controller: 'panelAppsCtrl',
          templateUrl: 'partials/cooking.apps.html'
        }
      }
    })
    .state('panel.settings', {
      url: "/settings",
      views: {
        'panelContent': {
          controller: 'panelSettingsCtrl',
          templateUrl: 'partials/cooking.settings.html'
        }
      }
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
      //// Is initial transition and is going to panel.*?
      if (fromState.name === '' && /panel.*/.exec(toState.name)) {
        event.preventDefault(); // cancel initial transition

        // go to top.people.managerlist, then go to modal1.whatever
        $state.go("cooking.projects.create", null, { location: false }).then(function() {
          $state.go(toState, toParams); }
        );
      }

      if(typeof toState != "object" || toState.name != "cooking.projects") return false;
      event.preventDefault();
      if (! currentProject.getProjectId()) return $state.go("cooking.projects.create");
      $state.go("cooking.projects.recipe", {id: currentProject.getProjectId()});
    });
});