'use strict';

angular.module('eintopf')
    .controller('setupCtrl',
    [ '$scope', 'setupLiveResponse', 'setupRestart',
        function($scope, setupLiveResponse, setupRestart) {
            console.log('in controller');

            setupLiveResponse.$assignProperty($scope, 'states');

            $scope.setupRestart = function() {
                setupRestart.emit();
            }
        }
    ]);
