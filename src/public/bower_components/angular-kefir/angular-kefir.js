(function(ng, Kefir) {
  var kefirModule = ng.module('angular-kefir', []);

  kefirModule.factory('Kefir', ['$window', '$parse', function($window, $parse) {
    var kefir = $window.Kefir;

    kefir.Observable.prototype.$assignProperty = function(scope, property) {
      var self = this;
      var setter = $parse(property).assign;
      var unSubscribe = function(value) {
        return !scope.$$phase ? scope.$apply(function () {
          setter(scope, value);
        }) : setter(scope, value);
      };

      self.onValue(unSubscribe);

      scope.$on('$destroy', function() {
        self.offValue(unSubscribe)
      });

      return self;
    };


    kefir.Observable.prototype.$assignProperties = function(scope, properties) {
      var self = this;
      properties.forEach(function(property) {
        self.$assignProperty(scope, property);
      });

      return self;
    };

    return kefir;
  }]);

  kefirModule.config(['$provide', function($provide) {
    $provide.decorator('$rootScope', ['$delegate', 'Kefir', function($delegate, Kefir) {

      Object.defineProperties($delegate.constructor.prototype, {
        '$fromBinder': {
          value: function(functionName) {
            var scope = this;

            return Kefir.fromBinder(function(emitter) {
              scope[functionName] = function() {
                emitter.emit(arguments);
              };

              return function() {
                delete scope[functionName];
              };
            });
          },
          enumerable: false
        },
        '$fromEvent': {
          value: function(eventName) {
            var scope = this;

            return Kefir.fromBinder(function(emitter) {
              var unSubscribe = scope.$on(eventName, function(ev, data) {
                emitter.emit(data);
              });

              scope.$on('$destroy', unSubscribe);

              return unSubscribe;
            });
          },
          enumerable: false
        },
        '$fromWatch': {
          value: function(watchExpression, objectEquality) {
            var scope = this;

            return Kefir.fromBinder(function(emitter) {
              function listener(newValue, oldValue) {
                emitter.emit({ oldValue:oldValue, newValue:newValue });
              }

              var unSubscribe = scope.$watch(watchExpression, listener, objectEquality);

              return unSubscribe;
            });
          },
          enumerable: false
        }
      });

      return $delegate;
    }]);
  }]);

} (angular, Kefir));
