'use strict';

angular.module('eintopf')
    .controller('setupCtrl',
    [ '$scope', 'setupLiveResponse',
        function($scope, setupLiveResponse) {
            console.log('in controller');

            setupLiveResponse.onValue(function(val) {
                $scope.states = val;
                $scope.$apply();
            });
        }
    ]);