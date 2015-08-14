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
    .controller('recipeCtrl',
    [ '$scope', '$stateParams',
        function($scope, $stateParams) {
            $scope.id = $stateParams.id;
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
            .onValue(function(test) {
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
