'use strict';

angular.module('eintopf')
    .controller('setupCtrl',
    [ '$scope', 'setupLiveResponse', 'setupRestart', '$state',
        function($scope, setupLiveResponse, setupRestart, $state) {
            console.log('in controller');

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
            console.log('in controller cooking');

            resProjectsList.$assignProperty($scope, 'projects');
        }
    ])
    .controller('recipeCtrl',
    [ '$scope', '$stateParams',
        function($scope, $stateParams) {
            console.log('in controller recipe');
            $scope.id = $stateParams.id;
        }
    ])
    .controller('createProjectCtrl',
    [ '$scope', 'setupLiveResponse', 'setupRestart',
        function($scope, setupLiveResponse, setupRestart) {
            $scope.newProject = '';
            console.log('in controller create Project');

            $scope.install = function(val) {
                if(!val) return false;

                console.log('install', val);
            }
        }
    ]);
