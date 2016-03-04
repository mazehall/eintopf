(function(ng) {

  var directiveModule = ng.module('eintopf-directives', []);

  directiveModule.directive('panelOverlay',[function()  {
    return {
      restrict: 'A',
      link: function($scope, element) {
        element.on('click', function(e) {
          if (! angular.element(e.target).hasClass('ng-pageslide-body-open')) return false;
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