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
    ]);
