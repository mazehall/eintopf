(function (ng) {

  var eintopf = ng.module('eintopf', [
    'eintopf-directives',
    'eintopf-factories',
    'eintopf-controller',
    'ui.router',
    'angular-kefir',
    'vtortola.ng-terminal',
    'luegg.directives',
    'hc.marked',
    'eintopf.services.ipc',
    'eintopf.services.storage',
    "pageslide-directive",
    'nsPopover',
    'ct.ui.router.extras.core',
    'ct.ui.router.extras.sticky',
    'ct.ui.router.extras.previous',
    'color.picker',
    'images-resizer'
  ]);

  eintopf.config(['terminalConfigurationProvider', function (terminalConfigurationProvider) {
    terminalConfigurationProvider.inputOnlyMode = true;
    terminalConfigurationProvider.promptConfiguration = {end: '', user: '', separator: '', path: ''};
  }]);

  eintopf.config(function ($stateProvider, $urlRouterProvider) {
    //// For any unmatched url, redirect to /state1
    $urlRouterProvider.otherwise("/setup");

    // Now set up the states
    $stateProvider
    .state('setup', {
      url: "/setup",
      templateUrl: "partials/setup.html",
      controller: "setupCtrl"
    })

    .state('cooking', {
      abstract: true,
      sticky: true,
      url: "/cooking",
      templateUrl: 'partials/cooking.html',
      controller: 'cookingCtrl'
    })

    .state('panel', {
      abstract: true,
      url: "/panel",
      views: {
        'panel': {
          templateUrl: 'partials/panel.content.html',
          controller: 'panelCtrl'
        }
      },
      onEnter: function ($rootScope, $previousState) {
        $previousState.memo("panel"); // remember the previous state with memoName "panel"
        $rootScope.pageSlide = true;
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
          templateUrl: 'partials/panel.containers.html'
        }
      }
    })
    .state('panel.apps', {
      url: "/apps",
      views: {
        'panelContent': {
          controller: 'panelAppsCtrl',
          templateUrl: 'partials/panel.apps.html'
        }
      }
    })
    .state('panel.settings', {
      url: "/settings",
      views: {
        'panelContent': {
          controller: 'panelSettingsCtrl',
          templateUrl: 'partials/panel.settings.html'
        }
      }
    })

    .state('cooking.projects', {
      url: "/projects",
      templateUrl: "partials/cooking.projects.html",
      controller: 'cookingProjectsCtrl'
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
    .state('cooking.projects.clone', {
      url: "/clone/{type}/{id}",
      controller: "cookingProjectsCloneCtrl",
      templateUrl: "partials/cooking.projects.clone.html"
    })
    .state('cooking.projects.edit', {
      url: "/edit/:id",
      controller: "cookingProjectsEditCtrl",
      templateUrl: "partials/cooking.projects.edit.html"
    });

  });

  // set current project state when changing projects state
  eintopf.run(function ($rootScope, $state, currentProject) {
    $rootScope.$on('$stateChangeStart',
      function (event, toState, toParams, fromState, fromParams) {
        //// Is initial transition and is going to panel.*?
        if (fromState.name === '' && /panel.*/.exec(toState.name)) {
          event.preventDefault(); // cancel initial transition

          // go to top.people.managerlist, then go to modal1.whatever
          $state.go("cooking.projects.create", null, {location: false}).then(function () {
              $state.go(toState, toParams);
            }
          );
        }

        if (typeof toState != "object" || toState.name != "cooking.projects") return false;
        event.preventDefault();
        if (!currentProject.getProjectId()) return $state.go("cooking.projects.create");
        $state.go("cooking.projects.recipe", {id: currentProject.getProjectId()});
      });
  });

})(angular);