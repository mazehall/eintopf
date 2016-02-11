'use strict';

angular.module('eintopf')
  .controller("rootCtrl",
  ["$scope", "backendErrors", 'panels',
    function($scope, backendErrors, panels) {
      $scope.openPanel = function() {
        panels.open('panelcontent');
      };

      backendErrors.$assignProperty($scope, "backendErrors");
    }
  ])
  .controller('errorCtrl',
  ['$scope', '$stateParams',
    function($scope, $stateParams) {
      $scope.error = $stateParams;
    }
  ])
  .controller('setupCtrl',
  ['$scope', 'setupLiveResponse', 'setupRestart', '$state',
    function($scope, setupLiveResponse, setupRestart, $state) {
      setupLiveResponse.$assignProperty($scope, 'states');

      $scope.$fromWatch('states')
        .filter(function(val) {
          if (val.newValue && val.newValue.state == 'cooking') return true;
        })
        .onValue(function() {
          $state.go('cooking.projects');
        });

      $scope.$fromWatch('states')
        .filter(function(val) {
          if (val.newValue && val.newValue.state == 'first') return true;
        })
        .onValue(function() {
          $state.go('first');
        });

      $scope.setupRestart = function() {
        setupRestart.emit();
      }
    }
  ])
  .controller('terminalCtrl',
  ['$scope', 'terminalStream',
    function($scope, terminalStream) {
      $scope.showTerminal = false;

      terminalStream.getStream()
      .onValue(function(val) {
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
        if(!consoleInput[0] || !consoleInput[0].command) return false;
        terminalStream.emit(consoleInput[0].command);
      });

    }
  ])
  .controller('cookingCtrl',
  ['$scope', '$state', 'storage', 'reqProjectList', 'resProjectsList', 'reqProjectStart', 'reqProjectStop',
    function($scope, $state, storage, reqProjectsList, resProjectsList, reqProjectStart, reqProjectStop) {
      resProjectsList.$assignProperty($scope, 'projects');
      reqProjectsList.emit();
      $scope.startProject = function(project) {
        emitStartStop(reqProjectStart, project);
      };
      $scope.stopProject = function(project) {
        emitStartStop(reqProjectStop, project);
      };

      var emitStartStop = function(reqProject, project){
        if (!(reqProject.emit && project.id)){
          return false;
        }

        storage.set("frontend.tabs"+ project.id+ ".lastActive", "protocol");
        reqProject.emit(project);

        if ($state.is("cooking.projects.recipe", {id: project.id})){
          $state.reload($state.current);
        }
      };
    }
  ])
  .controller('panelCtrl',
  ['$scope', '$previousState',
    function($scope, $previousState) {
      $scope.previousState = $previousState;
    }
  ])
  .controller('panelMainCtrl',
  ['$scope',
    function($scope) {
    }
  ])
  .controller('panelAppsCtrl',
    ['$scope',
      function($scope) {
      }
    ])
  .controller('panelContainersCtrl',
    ['$scope',
      function($scope) {
      }
    ])
  .controller('panelSettingsCtrl',
    ['$scope',
      function($scope) {
      }
    ])
  .controller('containersCtrl',
  ['$scope', 'resContainersList', 'reqContainerActions', 'resContainersLog',
    function($scope, resContainersList, reqContainerActions, resContainersLog) {
      resContainersList.$assignProperty($scope, 'containers');

      $scope.logs = [];
      resContainersLog
      .filter(function(x) {
        if(x.message) return x;
      })
      .onValue(function(val) {
        val.read = false;
        $scope.logs.push(val);
      });

      $scope.startContainer = function(container) {
        if(typeof container.id != "string") return false;
        reqContainerActions.start(container.id);
      };
      $scope.stopContainer = function(container) {
        if(typeof container.id != "string") return false;
        reqContainerActions.stop(container.id);
      };
      $scope.removeContainer = function(container) {
        if(typeof container.id != "string") return false;
        reqContainerActions.remove(container.id);
      };
    }
  ])
  .controller('appsCtrl',
  ['$scope', 'resAppsList',
    function($scope, resAppsList) {
      $scope.isElectron = false;
      if (navigator.userAgent && navigator.userAgent.match(/^electron/)) {
        $scope.isElectron = true;
      }
      resAppsList.$assignProperty($scope, 'apps');
    }
  ])
  .controller('recipeCtrl',
  ['$scope', '$stateParams', '$state', 'storage', 'reqProjectDetail', 'resProjectDetail', 'reqProjectStart', 'resProjectStart', 'reqProjectStop', 'resProjectStop', 'reqProjectDelete', 'resProjectDelete', 'reqProjectUpdate', 'resProjectUpdate', 'currentProject', 'resProjectStartAction', 'reqProjectStartAction', 'reqContainerActions', 'reqContainersList', 'resContainersLog',
    function ($scope, $stateParams, $state, storage, reqProjectDetail, resProjectDetail, reqProjectStart, resProjectStart, reqProjectStop, resProjectStop, reqProjectDelete, resProjectDelete, reqProjectUpdate, resProjectUpdate, currentProject, resProjectStartAction, reqProjectStartAction, reqContainerActions, reqContainersList, resContainersLog) {
      $scope.project = {
        id: $stateParams.id
      };
      $scope.loading = false;
      $scope.logs = [];

      resProjectStart.fromProject($stateParams.id);
      resProjectStop.fromProject($stateParams.id);
      resProjectDetail.fromProject($stateParams.id).$assignProperty($scope, 'project');
      reqProjectDetail.emit($stateParams.id);
      resProjectDetail.listApps($scope.project.id).$assignProperty($scope, "apps");
      resProjectDetail.listContainers($scope.project.id).onValue(function(containers){
        $scope.containerLength = Object.keys(containers).length;
      }).$assignProperty($scope, "containers");
      reqContainersList.emit();
      resContainersLog.filter(function (x) {
        if (x.message) return x;
      }).onValue(function (val) {
        val.read = false;
        $scope.logs.push(val);
      });

      $scope.startProject = function(project) {
        $scope.loading = true;
        $scope.result = {};
        reqProjectStart.emit(project);
      };
      $scope.stopProject = function(project) {
        $scope.loading = true;
        $scope.result = {};
        reqProjectStop.emit(project);
      };
      $scope.deleteProject = function(project){
        reqProjectDelete.emit(project);
        resProjectDelete.fromProject($stateParams.id).onValue(function(){
          currentProject.setProjectId();
          $state.go("cooking.projects");
        });
      };

      $scope.updateProject = function(project){
        reqProjectUpdate.emit(project);
        resProjectUpdate.fromProject($stateParams.id);
      };
      currentProject.setProjectId($stateParams.id);

      /**
       * Tab section
       */

      $scope.currentTab = storage.get("frontend.tabs"+ $stateParams.id+ ".lastActive") || "readme";
      $scope.onClickTab = function(tab){
          $scope.currentTab = tab;
          storage.set("frontend.tabs"+ $stateParams.id+ ".lastActive", tab);
      };

      storage.stream("project.log.complete."+ $stateParams.id).map(function(value){
          return value && value.join("").replace(/\n/ig, "<br>");
      }).$assignProperty($scope, "protocol");
      storage.notify("project.log.complete."+ $stateParams.id);

      $scope.$fromWatch("project.markdowns").skip(1).onValue(function(value){
          if (value.newValue.length === 0 || storage.get("project.log.complete."+ $stateParams.id)){
              return $scope.currentTab = "protocol";
          }
      });

      $scope.doAction = function(project, action){
        project.action = action;
        reqProjectStartAction.emit(project);
        resProjectStartAction.fromProject($stateParams.id);
        $scope.currentTab = "protocol"
      };

      $scope.startContainer = function (container) {
        if (typeof container.id != "string") return false;
        reqContainerActions.start(container.id);
      };

      $scope.stopContainer = function (container) {
        if (typeof container.id != "string") return false;
        reqContainerActions.stop(container.id);
      };

      $scope.removeContainer = function (container) {
        if (typeof container.id != "string") return false;
        reqContainerActions.remove(container.id);
      };

      $scope.isElectron = navigator.userAgent && navigator.userAgent.match(/^electron/);
    }
  ])
  .controller('createProjectCtrl',
  ['$scope', '$state', 'reqProjectsInstall', 'resProjectsInstall', 'resRecommendationsList',
    function($scope, $state, reqProjectsInstall, resProjectsInstall, resRecommendationsList) {
      resRecommendationsList.$assignProperty($scope, 'recommendations');
      resProjectsInstall.$assignProperty($scope, 'result');

      $scope.$fromWatch('result')
        .filter(function(val) {
          if (val.newValue && typeof val.newValue == "object" && val.newValue.status) return true;
        })
        .onValue(function(val) {
          $scope.loading = false;
          if(val.newValue.status == "success" && typeof val.newValue.project == "object") {
            $state.go("cooking.projects.recipe", {id: val.newValue.project.id});
          }
        });

      $scope.install = function(val) {
        val = val || $scope.newProject;
        if (!val) return false;
        $scope.result = {};
        $scope.loading = true;
        reqProjectsInstall.emit(val);
      };

      $scope.installRecommendation = function(project) {
        if (!project || typeof project != "object" || !project.url) return false;
        $scope.newProject = project.url;
        $scope.install(project.url);
      };
    }
  ])
  .controller('settingsCtrl',
  ['$scope', 'resSettingsList',
    function($scope, resSettingsList) {
        resSettingsList.$assignProperty($scope, 'settings');
    }
  ])
;
