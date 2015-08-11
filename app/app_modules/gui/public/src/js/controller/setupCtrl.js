'use strict';

angular.module('eintopf')
    .controller('setupCtrl',
    [ '$scope', 'setupLiveResponse', 'setupRestart',
        function($scope, setupLiveResponse, setupRestart) {
            console.log('in controller');

            setupLiveResponse.onValue(function(val) {
                $scope.states = val;
                $scope.$apply();
            });

            $scope.setupRestart = function() {
                setupRestart.emit();
            }
        }
    ]);