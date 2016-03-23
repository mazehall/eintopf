(function (ng) {

  var controllerModule = angular.module('eintopf-controller', []);

  controllerModule.controller('setupCtrl', ['$scope', 'setupLiveResponse', 'setupRestart', '$state',
    function ($scope, setupLiveResponse, setupRestart, $state) {
      setupLiveResponse.$assignProperty($scope, 'states');

      $scope.$fromWatch('states')
      .filter(function (val) {
        if (val.newValue && val.newValue.state == 'cooking') return true;
      })
      .onValue(function () {
        $state.go('cooking.projects');
      });

      $scope.setupRestart = function () {
        setupRestart.emit();
      }
    }
  ]);

  controllerModule.controller('terminalCtrl', ['$scope', 'terminalStream', function ($scope, terminalStream) {
    $scope.showTerminal = false;

    terminalStream.getStream()
    .onValue(function (val) {
      if (!$scope.showTerminal) $scope.showTerminal = true;
      $scope.$emit('terminal-output', {
        output: false,
        text: [val.text],
        breakLine: true,
        input: val.input | false,
        secret: val.secret | false
      });
    });

    $scope.$on('terminal-input', function (e, consoleInput) {
      if (!consoleInput[0] || !consoleInput[0].command) return false;
      terminalStream.emit(consoleInput[0].command);
    });
  }]);


  controllerModule.controller('cookingCtrl', ['$scope', 'setupLiveResponse', function ($scope, setupLiveResponse) {
    setupLiveResponse.$assignProperty($scope, 'states');
  }]);

  controllerModule.controller('cookingProjectsCtrl',
    ['$scope', '$state', 'storage', 'projectFactory', 'lockFactory',
      function ($scope, $state, storage, projectFactory, lockFactory) {
        projectFactory.stream.$assignProperty($scope, 'projects');
        lockFactory.stream.$assignProperty($scope, 'locks');

        $scope.toggleStartStop = function (project) {
          if (!project.id) return false;
          project.state ? projectFactory.stopProject(project) : projectFactory.startProject(project);
          storage.set("frontend.tabs" + project.id + ".lastActive", "protocol");
        };
      }
    ]
  );

  controllerModule.controller('panelCtrl',
    ['$scope', '$state', '$rootScope', '$previousState', 'resContainersList', 'resAppsList',
      function ($scope, $state, $rootScope, $previousState, resContainersList, resAppsList) {
        var panelLabels = {
          'panel.containers': 'Containers',
          'panel.apps': 'Running apps',
          'panel.settings': 'Manage vagrant'
        };

        resContainersList
        .map(function (x) {
          return x.length || 0;
        })
        .$assignProperty($scope, 'containerCount');

        resAppsList
        .map(function (x) {
          var count = 0;

          for (var y in x) {
            if (x[y].running === true) count++;
          }
          return count;
        })
        .$assignProperty($scope, 'appCount');

        $rootScope.$on('$stateChangeStart', function (event, toState) {
          setPanelLabelFromState(toState.name);
        });

        var setPanelLabelFromState = function (state) {
          if (!panelLabels[state]) return delete $scope.panelPageLabel;
          $scope.panelPageLabel = panelLabels[state];
        };
        setPanelLabelFromState($state.current.name);

        $scope.closePanel = function () {
          $scope.$root.pageSlide = false;
          $previousState.go("panel"); // go to state prior to panel
        }
      }
    ]
  );

  controllerModule.controller('panelMainCtrl', ['$scope', function ($scope) {
  }]);

  controllerModule.controller('panelAppsCtrl', ['$scope', 'resAppsList', function ($scope, resAppsList) {
    resAppsList.$assignProperty($scope, 'apps');
  }]);

  controllerModule.controller('panelContainersCtrl',
    ['$scope', 'resContainersList', 'resContainersLog', 'lockFactory', 'containerFactory',
      function ($scope, resContainersList, resContainersLog, lockFactory, containerFactory) {
        $scope.logs = [];

        containerFactory.stream.$assignProperty($scope, 'containers');
        lockFactory.stream.$assignProperty($scope, 'locks');
        containerFactory.pushFromLogs($scope, 'logs');

        $scope.removeContainer = function(container) {
          if (typeof container.id != "string") return false;
          containerFactory.removeContainer(container.id);
        };
        $scope.toggleStartStop = function (container) {
          if (typeof container.id != "string") return false;
          container.running ? containerFactory.stopContainer(container.id) : containerFactory.startContainer(container.id);
        };
      }
    ]
  );

  controllerModule.controller('panelSettingsCtrl', ['$scope', 'resSettingsList', function ($scope, resSettingsList) {
    resSettingsList.$assignProperty($scope, 'settings');
  }]);

  //@todo seperate tabs into states
  controllerModule.controller('recipeCtrl',
    ['$scope', '$stateParams', '$state', 'storage', 'resProjectStart','resProjectStop', 'reqProjectDelete', 'resProjectDelete', 'reqProjectUpdate', 'resProjectUpdate', 'currentProject', 'resProjectAction', 'reqProjectAction', 'containerFactory', 'lockFactory', 'appFactory', 'projectFactory',
      function ($scope, $stateParams, $state, storage, resProjectStart, resProjectStop, reqProjectDelete, resProjectDelete, reqProjectUpdate, resProjectUpdate, currentProject, resProjectAction, reqProjectAction, containerFactory, lockFactory, appFactory, projectFactory) {
        projectFactory.streamLog($stateParams.id).$assignProperty($scope, 'protocol')
        .onValue(function() {
          $scope.$broadcast('scrollLog');
        });
        projectFactory.assignFromProject($stateParams.id, $scope, 'project');
        lockFactory.assignFromProject($stateParams.id, $scope, 'locked');
        currentProject.setProjectId($stateParams.id);

        resProjectStart.fromProject($stateParams.id);
        resProjectStop.fromProject($stateParams.id);

        $scope.updateProject = projectFactory.updateProject;

        $scope.deleteProject = function (project) {
          reqProjectDelete.emit(project);
          resProjectDelete.fromProject($stateParams.id).onValue(function () {
            currentProject.setProjectId();
            $state.go("cooking.projects");
          });
        };

        $scope.doAction = function (project, action) {
          project.action = action;
          reqProjectAction.emit(project);
          resProjectAction.fromProject($stateParams.id);
          $scope.currentTab = "protocol"
        };

        /**
         * Apps section
         */
        appFactory.assignFromProject($stateParams.id, $scope, "apps");

        /**
         * Container section
         */
        containerFactory.assignFromProject($stateParams.id, $scope, 'containers');
        containerFactory.pushFromLogs($scope, 'logs');

        $scope.removeContainer = function(container) {
          if (typeof container.id != "string") return false;
          containerFactory.removeContainer(container.id);
        };
        $scope.toggleStartStop = function (container) {
          if (typeof container.id != "string") return false;
          container.running ? containerFactory.stopContainer(container.id) : containerFactory.startContainer(container.id);
        };

        /**
         * Tab section
         */
        $scope.currentTab = storage.get("frontend.tabs" + $stateParams.id + ".lastActive") || "readme";
        storage.stream("frontend.tabs" + $stateParams.id + ".lastActive").onValue(function (tab) {
          $scope.currentTab = tab;
        });

        $scope.onClickTab = function (tab) {
          storage.set("frontend.tabs" + $stateParams.id + ".lastActive", tab);
        };

        storage.notify("project.log.complete." + $stateParams.id);
        $scope.$fromWatch("project.readme").skip(1).onValue(function (value) {
          if (value.newValue.length === 0 || storage.get("project.log.complete." + $stateParams.id)) {
            return $scope.currentTab = "protocol";
          }
        });

      }
    ]
  );

  controllerModule.controller('createProjectCtrl',
    ['$scope', '$state', 'registryFactory','projectFactory', 'lockFactory',
      function ($scope, $state, registryFactory, projectFactory, lockFactory) {
        lockFactory.stream.$assignProperty($scope, 'locks');
        registryFactory.assignPublicRegistry($scope, 'public');
        registryFactory.assignPrivateRegistry($scope, 'private');

        $scope.registerProject = function (url) {
          if (typeof url != 'string') return false;

          //val = val || $scope.newProject;
          //if (!val) return false;
          //$scope.result = {};
          //$scope.loading = true;

          return false;
          projectFactory.registerProject(url);
        };

        $scope.installProject = function(project) {
          if (typeof project != 'object') return false;
          $scope.errorMessage = null;

          projectFactory.installProject(project, function(err, result) {
            if (result && result.id) return $state.go("cooking.projects.recipe", {id: result.id});
            if (err && err) $scope.errorMessage = err;

            $scope.$apply();
          });
        };
      }
    ]
  );

  controllerModule.controller('cookingProjectsCloneCtrl',
    ['$scope', '$state', '$stateParams', 'registryFactory', 'projectFactory',
      function ($scope, $state, $stateParams, registryFactory, projectFactory) {
        registryFactory.fromPattern($stateParams.id).$assignProperty($scope, 'project');

        $scope.resetError = function() {
          $scope.errorMessage = null;
        };

        $scope.clone = function () {
          if (! $scope.project.id || ! $scope.project.name) return false;

          $scope.errorMessage = null;
          $scope.loading = true;

          projectFactory.installProject($scope.project, function(err, result) {
            $scope.loading = false;
            if (result && result.id) return $state.go("cooking.projects.recipe", {id: result.id});
            if (err && err) $scope.errorMessage = err;

            $scope.$apply();
          });
        };
      }
    ]
  );

  controllerModule.controller('cookingProjectsEditCtrl', ['$scope', '$state', '$stateParams', 'projectFactory',
    function($scope, $state, $stateParams, projectFactory) {
      projectFactory.assignFromProject($stateParams.id, $scope, 'project');

      $scope.resetError = function() {
        $scope.errorMessage = null;
      };

      $scope.goBack = function () {
        $state.go("cooking.projects.recipe", {id: $stateParams.id});
      };

      $scope.updateCustomization = function() {
        $scope.errorMessage = null;
        $scope.loading = true;

        projectFactory.customizeProject($scope.project, function(err, result) {
          $scope.loading = false;
          console.log(err, result);
          if (err && err) $scope.errorMessage = err;
          $scope.$apply();
        });

      };
    }
  ]);

})(angular);