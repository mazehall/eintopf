//@todo delete when not used
var myApp = angular.module('eintopfApp',[]);

myApp.controller('offeredProjectsController', ['$scope', '$http', function($scope, $http) {
    $scope.offeredProjects = [];

    $http
        .get('/api/offeredProjects')
        .success(function(result) {
            $scope.offeredProjects = result;
        })
        .error(function(err) {
            $scope.offeredProjects = [];
        });

    $scope.install = function(key) {
        var errorCb = function(err) {
            alert('install failed');
        };
        if(typeof $scope.offeredProjects[key].project == 'undefined') return errorCb;

        $http
            .post('/api/install', {"projectKey": key})
            .success(function(result) {
                alert('install successful');
            })
            .error(errorCb);
        return false;
    }

}])

.controller('projectsController', ['$scope', '$http', function($scope, $http) {
    $scope.projects = [];
    $scope.tab = 'projects';

    $http
        .get('/api/projects')
        .success(function(result) {
            $scope.projects = result;
        })
        .error(function(err) {
            $scope.projects = [];
        });

    $scope.start = function(key) {
        if(typeof $scope.projects[key] == 'undefined') return alert('start failed');

        $http.
            post('/api/start', {"projectKey": key})
            .success(function(result) {
                alert('start successful');
            })
            .error(function(err) {
                alert('start failed');
            });
    };

    $scope.stop = function(key) {
        if(typeof $scope.projects[key] == 'undefined') return alert('stop failed');

        $http.
            post('/api/stop', {"projectKey": key})
            .success(function(result) {
                alert('stop successful');
            })
            .error(function(err) {
                alert('stop failed');
            });
    };

    $scope.doAction = function(key, action) {
        if(typeof $scope.projects[key] == 'undefined' || !action.script) return alert('action failed');

        $http.
            post('/api/action', {"projectKey": key, "script": action.script})
            .success(function(result) {
                alert('action successful');
            })
            .error(function(err) {
                alert('action failed');
            });
    };

}])

.directive('ngConfirmClick', [
    function () {
        return {
            link: function (scope, element, attr) {
                var msg = attr.ngConfirmClick || "Are you sure?";
                var clickAction = attr.ngClick;

                element.bind('click', function (event) {
                    if (window.confirm(msg)) {
                        scope.$eval(clickAction)
                    }
                    event.preventDefault();
                    event.stopImmediatePropagation();
                });
            }
        };
    }
]);

