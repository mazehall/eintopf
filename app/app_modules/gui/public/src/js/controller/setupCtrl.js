'use strict';

angular.module('eintopf')
    .controller('setupCtrl',
    [ '$scope', 'setupLiveResponse', 'setupRestart', '$state',
        function($scope, setupLiveResponse, setupRestart, $state) {
            console.log('in controller');

            setupLiveResponse.$assignProperty($scope, 'states');
            setupLiveResponse.onValue(function(val) {
                if(val.state == "cooking") {
                    $state.go('cooking');
                }
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

            setTimeout(function() {
                reqProjectsList.emit();
            }, 100);
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
