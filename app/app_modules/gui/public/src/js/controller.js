'use strict';

angular.module('eintopf')
  .controller('setupCtrl',
  ['$scope', 'setupLiveResponse', 'setupRestart', '$state',
    function($scope, setupLiveResponse, setupRestart, $state) {
      setupLiveResponse.$assignProperty($scope, 'states');

      $scope.$fromWatch('states')
        .filter(function(val) {
          if (val.newValue && val.newValue.state == 'cooking') return true;
          return null;
        })
        .onValue(function() {
          $state.go('cooking.projects');
        });

      $scope.$fromWatch('states')
        .filter(function(val) {
          if (val.newValue && val.newValue.state == 'first') return true;
          return null;
        })
        .onValue(function() {
          $state.go('first');
        });

      $scope.setupRestart = function() {
        setupRestart.emit();
      }
    }
  ])
  .controller('cookingCtrl',
  ['$scope', 'reqProjectList', 'resProjectsList',
    function($scope, reqProjectsList, resProjectsList) {
      resProjectsList.$assignProperty($scope, 'projects');
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
      resAppsList.$assignProperty($scope, 'apps');
    }
  ])
  .controller('recipeCtrl',
  ['$scope', '$stateParams', '$state', 'storage', 'reqProjectDetail', 'resProjectDetail', 'reqProjectStart', 'resProjectStart', 'reqProjectStop', 'resProjectStop', 'reqProjectDelete', 'resProjectDelete', 'reqProjectUpdate', 'resProjectUpdate', 'reqProjectList', 'currentProject',
    function($scope, $stateParams, $state, storage, reqProjectDetail, resProjectDetail, reqProjectStart, resProjectStart, reqProjectStop, resProjectStop, reqProjectDelete, resProjectDelete, reqProjectUpdate, resProjectUpdate, reqProjectList, currentProject) {
      $scope.project = {
        id: $stateParams.id
      };
      $scope.loading = false;

      resProjectStart.fromProject($stateParams.id);
      resProjectStop.fromProject($stateParams.id);
      resProjectDetail.$assignProperty($scope, 'project');
      reqProjectDetail.emit($stateParams.id);

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
       * Log section
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
    }
  ])
  .controller('createProjectCtrl',
  ['$scope', '$state', 'reqProjectsInstall', 'resProjectsInstall',
    function($scope, $state, reqProjectsInstall, resProjectsInstall) {
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
        if (!val) return false;
        $scope.result = {};
        $scope.loading = true;
        reqProjectsInstall.emit(val);
      }
    }
  ])
  .controller('settingsCtrl',
  ['$scope', 'resSettingsList',
    function($scope, resSettingsList) {
        resSettingsList.$assignProperty($scope, 'settings');
    }
  ])
;
