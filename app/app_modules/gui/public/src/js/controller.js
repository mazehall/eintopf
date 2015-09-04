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
  ['$scope', 'reqProjectList', 'resProjectsList', '$state',
    function($scope, reqProjectsList, resProjectsList, $state) {
      resProjectsList.$assignProperty($scope, 'projects');
      if ($scope.$root.lastProjectId) {
        $state.go("cooking.projects.recipe", {id: $scope.$root.lastProjectId});
      }
    }
  ])
  .controller('containersCtrl',
  ['$scope', 'resContainersList',
    function($scope, resContainersList) {
      resContainersList.$assignProperty($scope, 'containers');
    }
  ])
  .controller('appsCtrl',
  ['$scope', 'resAppsList',
    function($scope, resAppsList) {
      if (navigator.userAgent && navigator.userAgent.match(/^electron/)) {
        $scope.renderLinks = false
      } else {
        $scope.renderLinks = true
      }
      resAppsList.$assignProperty($scope, 'apps');
    }
  ])
  .controller('recipeCtrl',
  ['$scope', '$stateParams', '$state', 'storage', 'reqProjectDetail', 'resProjectDetail', 'reqProjectStart', 'resProjectStart', 'reqProjectStop', 'resProjectStop', 'reqProjectDelete', 'resProjectDelete', 'reqProjectUpdate', 'resProjectUpdate', 'reqProjectList', 'reqProjectListRefresh',
    function($scope, $stateParams, $state, storage, reqProjectDetail, resProjectDetail, reqProjectStart, resProjectStart, reqProjectStop, resProjectStop, reqProjectDelete, resProjectDelete, reqProjectUpdate, resProjectUpdate, reqProjectList, reqProjectListRefresh) {
      $scope.project = {
        id: $stateParams.id
      };
      $scope.loading = false;

      resProjectStart.fromProject($stateParams.id).$assignProperty($scope, 'logs.Start');
      resProjectStop.fromProject($stateParams.id).$assignProperty($scope, 'logs.Stop');
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
          reqProjectListRefresh.emit();
          $scope.$root.lastProjectId = null;
          $state.go("cooking.projects");
        });
      };

      $scope.$root.lastProjectId = $stateParams.id;

      $scope.updateProject = function(project){
        reqProjectUpdate.emit(project);
        resProjectUpdate.fromProject($stateParams.id).$assignProperty($scope, 'logs.Update');
      };

      /**
       * Log section
       */

      $scope.tabs = ["protocol"];
      $scope.currentTab = "protocol";
      $scope.tabContent = {};
      $scope.onClickTab = function(tab){
          $scope.currentTab = tab;
      };

      storage.stream("project.log.complete."+ $scope.project.id).map(function(value){
          return value.join("");
      }).$assignProperty($scope, "tabContent.protocol");
    }
  ])
  .controller('createProjectCtrl',
  ['$scope', 'reqProjectsInstall', 'resProjectsInstall',
    function($scope, reqProjectsInstall, resProjectsInstall) {
      resProjectsInstall.$assignProperty($scope, 'result');
      $scope.$fromWatch('result')
        .filter(function(val) {
          if (typeof val.newValue == "object" && val.newValue.status) return true;
        })
        .onValue(function() {
          $scope.loading = false;
        });

      $scope.install = function(val) {
        if (!val) return false;
        $scope.result = {};
        $scope.loading = true;
        reqProjectsInstall.emit(val);
      }
    }
  ]);
