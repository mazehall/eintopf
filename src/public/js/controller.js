'use strict';

angular.module('eintopf')
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
  ['$scope', 'setupLiveResponse',
    function($scope, setupLiveResponse) {
      setupLiveResponse.$assignProperty($scope, 'states');
    }
  ])
  .controller('cookingProjectsCtrl',
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
      };
    }
  ])
  .controller('panelCtrl',
  ['$scope', '$state', '$rootScope', '$previousState', 'resContainersList', 'resAppsList',
    function($scope, $state, $rootScope, $previousState, resContainersList, resAppsList) {
      var panelLabels = {'panel.containers': 'Containers', 'panel.apps': 'Running apps', 'panel.settings': 'Manage vagrant'};

      resContainersList
      .map(function(x) {
        return x.length || 0;
      })
      .$assignProperty($scope, 'containerCount');

      resAppsList
      .map(function(x) {
        var count = 0;

        for(var y in x) {
          if (x[y].running === true) count ++;
        };
        return count;
      })
      .$assignProperty($scope, 'appCount');

      $rootScope.$on('$stateChangeStart', function(event, toState){
          setPanelLabelFromState(toState.name);
      });

      var setPanelLabelFromState = function(state) {
        if (! panelLabels[state]) return delete $scope.panelPageLabel;
        $scope.panelPageLabel = panelLabels[state];
      };
      setPanelLabelFromState($state.current.name);

      $scope.closePanel = function() {
        $scope.$root.pageSlide = false;
        $previousState.go("panel"); // go to state prior to panel
      }
    }
  ])
  .controller('panelMainCtrl',
  ['$scope',
    function($scope) {
    }
  ])
  .controller('panelAppsCtrl',
  ['$scope', 'resAppsList',
    function($scope, resAppsList) {
      resAppsList.$assignProperty($scope, 'apps');
    }
  ])
  .controller('panelContainersCtrl',
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
  .controller('panelSettingsCtrl',
  ['$scope', 'resSettingsList',
    function($scope, resSettingsList) {
      resSettingsList.$assignProperty($scope, 'settings');
    }
  ])
  .controller('recipeCtrl',
  ['$scope', '$stateParams', '$state', 'storage', 'reqProjectDetail', 'resProjectDetail', 'reqProjectStart', 'resProjectStart', 'reqProjectStop', 'resProjectStop', 'reqProjectDelete', 'resProjectDelete', 'reqProjectUpdate', 'resProjectUpdate', 'currentProject', 'resProjectAction', 'reqProjectAction', 'reqContainerActions', 'reqContainersList', 'resContainersLog',
    function ($scope, $stateParams, $state, storage, reqProjectDetail, resProjectDetail, reqProjectStart, resProjectStart, reqProjectStop, resProjectStop, reqProjectDelete, resProjectDelete, reqProjectUpdate, resProjectUpdate, currentProject, resProjectAction, reqProjectAction, reqContainerActions, reqContainersList, resContainersLog) {
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

      storage.stream("frontend.tabs"+ $stateParams.id+ ".lastActive").onValue(function(tab) {
        $scope.currentTab = tab;
      });

      $scope.currentTab = storage.get("frontend.tabs"+ $stateParams.id+ ".lastActive") || "readme";
      $scope.onClickTab = function(tab){
          storage.set("frontend.tabs"+ $stateParams.id+ ".lastActive", tab);
      };

      storage.stream("project.log.complete."+ $stateParams.id).map(function(value){
          return value && value.join("").replace(/\n/ig, "<br>");
      }).$assignProperty($scope, "protocol");
      storage.notify("project.log.complete."+ $stateParams.id);

      $scope.$fromWatch("project.readme").skip(1).onValue(function(value){
        if (value.newValue.length === 0 || storage.get("project.log.complete."+ $stateParams.id)){
            return $scope.currentTab = "protocol";
        }
      });

      $scope.doAction = function(project, action){
        project.action = action;
        reqProjectAction.emit(project);
        resProjectAction.fromProject($stateParams.id);
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
  .controller('cookingProjectsCloneCtrl',
  ['$scope', '$state', '$stateParams', 'clonePatternFactory',
    function($scope, $state, $stateParams, clonePatternFactory) {
      $scope.recipeImage = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyhpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNi1jMDY3IDc5LjE1Nzc0NywgMjAxNS8wMy8zMC0yMzo0MDo0MiAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTUgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MzI4MUI1Mjg1MzNCMTFFNThFNkVERDhGMEIzQ0ZBQjUiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6MzI4MUI1Mjk1MzNCMTFFNThFNkVERDhGMEIzQ0ZBQjUiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDozMjgxQjUyNjUzM0IxMUU1OEU2RUREOEYwQjNDRkFCNSIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDozMjgxQjUyNzUzM0IxMUU1OEU2RUREOEYwQjNDRkFCNSIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PnetuO8AAAUcSURBVHja3JlZjBRVFIZvVS9DTzOTYTKKK2FENG5Bo0ZRR6Iiog9CfFAjGsBookSiibuiRoxRh7gFl8T4ZARxw4UIbsGARolb9EFjQkDBlRHbpnvsHnu6q/3/6b+w7FR3T4/AVM1NvlSvVee/59xzz73X6u3tNfuqdXZ2juRv+4Mo+KXej2wT/DYOzAYtgRFSLBbrfZ0ArT72nQDuAd2BEZLNZut9PRXcXfXZHLBcAtvCElqLwdF6TcMfAC+BQ8Em8F3QhZwO1oNJYAmYCz4AtzIawQvgajq03k2ioyyChl8J7gIfgQfBhfLIn+B68CrINbrRaAlhvN8IzgKXMDOD98Dh4AewGiwDO7x/KpfLZmBgYPSF0JB8Pm8SiQSNnAguAovATUqvj4OnwVaF1VDLZDK7/18qlfaKkIjuQSNiIqKxx6vl1UEgpGRZVsZxnPdjsdg8sBSf96GnF8oTZnBwcIhm2kiF2OpR5vbJSp0HgoNAB2gHSRDXMxz1cB7053K5TCQSOTYej/dgbklD3HIY/q1CLjsSg6LD/A0NOgScDaaDU8Bh8oCj3navLsZzdZvrIcu27ShapL+/34EIeuU+kAZfgY/BRvA5hdNJuv+IhEwA54BZ4ERwlG72E/gRfAH+UA200+1twNFYkAccjxjLE3otEHIBrteAXv2mS3UVPbsA3K7B7gpbJ2FNCTkVPK/JiA9fAx5RitzpMbJU5YFht2Qy2YfLpQixN3D9TEIjrlBNjueC+epMClul+eX3RhMi318O1oIp4DVwnEqFFWAb+Av87XF30yJUBbN3n0MGW4j3MYRZCV4qyLNpeeFecIxs6pOnVmkc1hXCwfaEwortHfDNnk7D6XTafXknsyt7v7293UCI388p7G2Fs6VxOreRkKwU5/X+MfAkmKHs1CbX/6+G1GtSqRTJI+0+xCyHTOatjhla+8kb8xUhZ8j721XC1B0jDJUbwHgwT2mUE9YV4FcNPhZvW8D3Gug7VE5kFG7lJlJ4Aqk3WSgUoKE4W5lxssbHJA38iZ7OK6ljtzUSQtedDM7zCTlyBOipnrDlQWawXaqLchpLRX1viVb19njNMxMwW3dCRKSJ6YLh+IkST7mWkBka4B1NRIprYKuy3N5ujJI3NU42+I2RNmWJDhP8RhuXehdbXiHX+oRNkFuPbP6PkG4ptEIkxJLN3a4QWyuwFhO+RpuvogZbi5ozTXgbbe+ikJkqR8LaaPssV0hXiIXQ9pm2Bks0xEJYnU+xNcuGvcVtleRhb0VbhZ8TYhEsJH+ztR2ZCbEQ2r7J1lp4e4iFsKRfY2tt8WmIhXDJvNnWmmGFYi2M42PIdrdo/BC8EkIhL8v23dUvlV2nBX5YGm1d7EaSdz2SAveHJBU7sjXlt7Dil8+Ch0MgZJlsdWptB9FNt4CnAjz4XwS3VdtX6+htS4C9cYDfh7WE8AAmElAhPHM8cjhCuLt3UoA9wiXHkkZCuKC/ucH6vbwPjG2UOS8GB1erq15tzalx460qMHnlfhLPN6aaPXfEzWdsBm+xmjWVg6RppnI2E/fxynTvJF4tZJr5d9OrrMzwNXgUvG4q26Buu0ML/8vA+drEsM3wt5TcU66UCteVpnJKVX1sSyHcj+bOYqvuz+dwX2u16z2/vd9d+pJV5TOmcmDvd67HB74ruOHM7f7TwPGmshlt1RHwM/jSVPZw1zeovnkytsBUduMXqfPGaUFou0IsHvmOhWabMdLGjJB/BBgAGIdumYVenrQAAAAASUVORK5CYII="
      ;
      $scope.cloning = false;

      clonePatternFactory.getPatternStream($stateParams.id).$assignProperty($scope, 'project');
      clonePatternFactory.getCloneStream($stateParams.id)
      .onValue(function(result) {
        if(result.status == 'success') $state.go("cooking.projects.recipe", {id: result.project.id});
        $scope.cloning = false;
      })
      .$assignProperty($scope, 'result');

      $scope.clone = function() {
        $scope.result = {};
        $scope.cloning = true;
        clonePatternFactory.emitClone($scope.project)
      };

    }
  ])
;
