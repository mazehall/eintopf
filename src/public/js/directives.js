(function(ng) {

  var directiveModule = ng.module('eintopf-directives', []);

  directiveModule.directive('panelOverlay',[function()  {
    return {
      restrict: 'A',
      link: function($scope, element) {
        element.on('click', function(e) {
          if (! angular.element(e.target).hasClass('ng-pageslide-body-open')) return true;
          $scope.closePanel();
        });
      },
      controller: function($scope, $previousState) {
        $scope.closePanel = function() {
          $scope.pageSlide = false;
          $previousState.go('panel');
        }
      }
    };
  }]);

  // inspired by angularjs-scroll-glue: https://github.com/Luegg/angularjs-scroll-glue
  directiveModule.directive('scrollOnEvent', ['$window', '$timeout', function($window, $timeout) {
    return {
      restrict: 'A',
      scope: {
        scrollOnEvent: '@'
      },
      link: function(scope, $el, attrs) {
        var eventName = scope.scrollOnEvent || 'scroll';
        var activated = true;
        var el = $el[0];

        var scrollIfGlued = function () {
          if (activated && !isAttached(el)) scroll(el);
        };

        var isAttached = function(el){
          // + 1 catches off by one errors in chrome
          return el.scrollTop + el.clientHeight + 1 >= el.scrollHeight;
        };
        var scroll = function(el){
          el.scrollTop = el.scrollHeight;
        };

        scope.$on(eventName, scrollIfGlued);

        $timeout(scrollIfGlued, 0, false);
        $window.addEventListener('resize', scrollIfGlued, false);

        $el.bind('scroll', function(){
          activated = isAttached(el);
        });
      }
    }
  }]);

  directiveModule.directive('fileDialog', ['electron', 'resizeService', function(electron, resizeService) {
    return {
      restrict: 'A',
      scope: {
        fileDialog: '=',
        fileWidth: '@'
      },
      link: function($scope, element) {
        element.on('click', $scope.toggleFileDialog);
      },
      controller: function($scope) {
        var allowedExtensions = ['jpg', 'jpeg', 'gif', 'png'];
        $scope.dialogOpened = false;

        $scope.openErrorDialog = function (errorMessage) {
          electron.dialog.showErrorBox('Error', errorMessage);
        };

        $scope.toggleFileDialog = function() {
          if ($scope.dialogOpened) return false;
          $scope.dialogOpened = true;
          $scope.openFileDialog();
        };

        $scope.openFileDialog = function () {
          var options = { filters: [{ name: 'Images', extensions: allowedExtensions }]};

          electron.dialog.showOpenDialog(options, function(fileNames) {
            $scope.dialogOpened = false;
            if (fileNames === undefined) return false;

            resizeService.resizeImage(fileNames[0], {width: $scope.fileWidth, outputFormat: 'png'}, function(err, image){
              if (err) $scope.openErrorDialog(err);
              $scope.fileDialog = image;
            });
          });
        };
      }
    }
  }]);

})(angular);