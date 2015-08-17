'use strict';

angular.module('eintopf')
    .controller('setupCtrl',
    [ '$scope', 'setupLiveResponse', 'setupRestart', '$state',
        function($scope, setupLiveResponse, setupRestart, $state) {
            setupLiveResponse.$assignProperty($scope, 'states');

            $scope.$fromWatch('states')
            .filter(function (val) {
                if (val.newValue && val.newValue.state == 'cooking') return true;
                return null;
            })
            .onValue(function() {
                $state.go('cooking');
            });

            $scope.setupRestart = function() {
                setupRestart.emit();
            }
        }
    ])
    .controller('cookingCtrl',
    [ '$scope', 'reqProjectList', 'resProjectsList',
        function($scope, reqProjectsList ,resProjectsList) {
            resProjectsList.$assignProperty($scope, 'projects');
        }
    ])
    .controller('appsCtrl',
    [ '$scope', 'resAppsList',
        function($scope, resAppsList) {
            resAppsList.$assignProperty($scope, 'apps');
        }
    ])
    .controller('recipeCtrl',
    [ '$scope', '$stateParams', 'reqProjectDetail', 'resProjectDetail', 'reqProjectStart', 'resProjectStart', 'reqProjectStop', 'resProjectStop',
        function($scope, $stateParams, reqProjectDetail, resProjectDetail, reqProjectStart, resProjectStart, reqProjectStop, resProjectStop) {
            $scope.project = {
                id: $stateParams.id
            };
            $scope.loading = false;

            resProjectStart.$assignProperty($scope, 'result');
            resProjectStop.$assignProperty($scope, 'result');
            resProjectDetail.$assignProperty($scope, 'project');
            reqProjectDetail.emit($stateParams.id);

            $scope.$fromWatch('result')
            .filter(function(val) {
                if (val.newValue && val.newValue.output) return true;
            })
            .onValue(function() {
                $scope.loading = false;
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
        }
    ])
    .controller('createProjectCtrl',
    [ '$scope', 'reqProjectsInstall', 'resProjectsInstall',
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
                if(!val) return false;
                $scope.result = {};
                $scope.loading = true;
                reqProjectsInstall.emit(val);
            }
        }
    ]);
