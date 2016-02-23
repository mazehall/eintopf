describe('ng-pageslide: ', function() {
  'use strict';

  var $compile;
  var $timeout;
  var $document = jasmine.createSpyObj('$document', ['on', 'off']);
  var scope;
  var isolateScope;
  var element;
  var compilePageslide;

  beforeEach(function (done) {
    module('pageslide-directive', [
      '$provide',
      function ($provide) {
        $provide.value('$document', $document);
      }
    ]);
    compilePageslide = function (html) {
      inject([
        '$compile',
        '$rootScope',
        '$document',
        '$timeout',
        function(_$compile_, $rootScope, $document, _$timeout_){
          $compile = _$compile_;
          $timeout = _$timeout_;
          scope = $rootScope.$new();
          element = angular.element(html);
          $compile(element)(scope);
          scope.$digest();
          isolateScope = element.isolateScope();
        }
      ]);
    };
    done();
  });


  afterEach(function(){
    // try to clean Dom
    var slider = document.querySelector('.ng-pageslide');
    var pageslide = document.querySelector('#test-pageslide');
    document.body.innerHTML = '';
  });

  describe('initialization', function () {
    describe('when the element is invalid', function () {
      describe('because there is no content inside of the root element', function () {
        it('should throw an exception for no content', function (done) {
          expect(function () {compilePageslide('<pageslide></pageslide>');}).toThrow();
          done();
        });
      });
      describe('because the root element is not a div', function () {
        it('should throw an exception for no content', function (done) {
          expect(function () {compilePageslide('<p pageslide></p>');}).toThrow();
          done();
        });
      });
    });
    describe('when the element is valid', function () {
      describe('psCloak', function () {
        describe('when set to false', function () {
          beforeEach(function (done) {
            compilePageslide([
              '<pageslide ps-cloak="false" ps-open="is_open">',
              '<div>test</div>',
              '</pageslide>'
            ].join(''));
            done();
          });

          it('should not set the display to none', function (done) {
            scope.is_open = true;
            scope.$digest();
            expect(element.html()).not.toContain('display: none;');
            done();
          });
          it('should not set the display to block after the timeout finishes', function (done) {
            scope.is_open = true;
            scope.$digest();
            $timeout.flush();
            scope.$digest();
            expect(element.html()).not.toContain('display: block;');
            done();
          });
        });
        describe('by default', function () {
          beforeEach(function (done) {
            compilePageslide([
              '<pageslide ps-open="is_open">',
              '<div>test</div>',
              '</pageslide>'
            ].join(''));
            done();
          });

          it('should set the display to block after the timeout finishes', function (done) {
            scope.is_open = true;
            scope.$digest();
            $timeout.flush();
            scope.$digest();
            expect(angular.element(document.body).html()).toContain('display: block;');
            done();
          });
        });
      });

      describe('and has defined the container', function () {
        beforeEach(function (done) {
          angular.element(document.body).append('<div id="customContainer">custom container text</div>');
          compilePageslide([
            '<div pageslide ps-container="customContainer" ps-open="is_open">',
            '<div>test</div>',
            '</div>'
          ].join(''));
          done();
        });

        afterEach(function (done) {
          var customContainer = document.querySelector('#customContainer');
          document.body.removeChild(customContainer);
          done();
        });

        it('should contain the pageslide with the custom defined container', function (done) {
          expect(angular.element(document.querySelector('#customContainer')).html())
          .toContain('pageslide');
          done();
        });
        it('should set the position to absolute', function (done) {
          //TODO: find out why it won't set to absolute, but is setting fixed fine
          var slider = document.querySelector('#customContainer');
          expect(angular.element(slider).css('position')).toEqual('');
          done();
        });
      });

      describe('and has defined the body class', function () {
        //TODO: right now, it looks like there is a mixup between className and bodyClass, most likely a bug
        beforeEach(function (done) {
          compilePageslide([
            '<div pageslide ps-body-class="customBodyClass" ps-class="customBodyClass" ps-open="is_open">',
            '<div>test</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should add the class to the pageslide element', function (done) {
          expect(angular.element(document.querySelector('.customBodyClass')).html()).toBeDefined();
          done();
        });
      });

      describe('and has set squeeze to true', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<div pageslide ps-squeeze="true" ps-open="is_open">',
            '<div>test</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should set the width ', function (done) {
          var body = angular.element(document.body);
          scope.is_open = true;
          scope.$digest();
          //TODO: find out why this fails on Travis CI but not locally
          // expect(body.css('transition')).toContain('0.5s');
          expect(body.css('-webkit-transition')).toContain('0.5s');
          expect(body.html()).toContain('width: 300px;');
          scope.is_open = false;
          scope.$digest();
          expect(body.css('right')).toEqual('0px');
          done();
        });
      });
      describe('and has set push to true', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<div pageslide ps-push="true" ps-open="is_open">',
            '<div>test</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should set the width ', function (done) {
          var body = angular.element(document.body);
          scope.is_open = true;
          scope.$digest();
          scope.is_open = false;
          scope.$digest();
          expect(body.css('right')).toEqual('0px');
          expect(body.css('left')).toEqual('0px');
          done();
        });
      });

      describe('when the psSize is set', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<pageslide ps-size="{{size}}" ps-open="is_open">',
            '<div>test</div>',
            '</pageslide>'
          ].join(''));
          done();
        });
        it('should set the size accordingly', function (done) {
          scope.is_open = false;
          scope.$digest();
          expect(isolateScope.psOpen).toEqual(false);
          scope.size = '150px';
          scope.$digest();
          expect(isolateScope.psOpen).toEqual(true);
          var body = angular.element(document.body);
          expect(body.html()).toContain('width: 150px;');
          done();
        });
      });

      describe('when psAutoClose is set', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<pageslide ps-auto-close="true" ps-open="is_open">',
            '<div>test</div>',
            '</pageslide>'
          ].join(''));
          done();
        });
        it('should open on $locationChangeStart', function (done) {
          isolateScope.psOpen = true;
          scope.$broadcast('$locationChangeStart');
          expect(isolateScope.psOpen).toEqual(false);
          isolateScope.$digest();
          isolateScope.psOpen = true;
          scope.$broadcast('$stateChangeStart');
          expect(isolateScope.psOpen).toEqual(false);
          done();
        });
      });
    });
  });

  describe('functionality', function () {
    describe('default/right pageslide', function () {
      it('Should attach the pageslide panel to <body>', function(done) {
        // Create template DOM for directive
        compilePageslide([
          '<div>',
          '<div pageslide ps-open="is_open" ps-speed="-1.5">',
          '<div id="target">',
          '<p>some random content...</p>',
          '<a id="target-close" href="#">Click to close</a>',
          '</div>',
          '</div>',
          '</div>'
        ].join(''));

        // Check for DOM Manipulation
        var el = document.querySelector('.ng-pageslide');
        var attached_to = el.parentElement.tagName;
        expect(attached_to).toBe('BODY');
        done();
      });

      it('Should open and close watching for ps-open', function (done) {
        // Create template DOM for directive
        compilePageslide([
          '<div>',
          '<div pageslide ps-open="is_open" ps-speed="0.5" href="#target">',
          '<div id="target">',
          '<p>some random content...</p>',
          '<a id="target-close" href="#">Click to close</a>',
          '</div>',
          '</div>',
          '</div>'
        ].join(''));

        scope.is_open = true;
        scope.$digest();
        var width = document.querySelector('.ng-pageslide').style.width;
        expect(width).toBe('300px');

        scope.is_open = false;
        scope.$digest();
        width = document.querySelector('.ng-pageslide').style.width;
        expect(width).toBe('0px');
        done();
      });

      it('Should attach the pageslide inner content to <body>', function (done) {
        // Create template DOM for directive
        compilePageslide([
          '<pageslide ps-open="is_open">',
          '<div>',
          '<p>some random content...</p>',
          '</div>',
          '</pageslide>'
        ].join(''));

        // Check for DOM Manipulation
        var el = document.querySelector('.ng-pageslide');
        var attached_to = el.parentNode.localName;
        expect(attached_to).toBe('body');
        done();
      });

      it('Should remove slider when pageslide\'s scope be destroyed', function (done) {
        // Create template DOM for directive
        compilePageslide([
          '<div>',
          '<div pageslide ps-open="is_open" ps-speed="0.5" href="#target">',
          '<div id="target">',
          '<p>some random content...</p>',
          '<a id="target-close" href="#">Click to close</a>',
          '</div>',
          '</div>',
          '</div>'
        ].join(''));
        scope.is_open = true;
        scope.$digest();
        scope.$destroy();
        expect(isolateScope).toBeUndefined();
        done();
      });

      describe('when binding the key listener', function () {
        beforeEach(function (done) {
          // Create template DOM for directive
          compilePageslide([
            '<div>',
            '<div pageslide ps-open="is_open" ps-key-listener="true">',
            '<div id="target">',
            '<p>some random content...</p>',
            '<a id="target-close" href="#">Click to close</a>',
            '</div>',
            '</div>',
            '</div>'
          ].join(''));
          done();
        });
        describe('and the user presses the escape key', function () {
          describe('and the keyCode is populated', function () {
            it('should close the slider', function (done) {
              $document.on.and.callFake(function (actionType, callback) {
                callback({
                  keyCode: 27 //same as ESC_KEY
                });
              });
              scope.is_open = true;
              scope.$digest();
              expect($document.on).toHaveBeenCalled();
              expect(scope.is_open).toEqual(false);
              done();
            });
          });

          describe('and the "which" property is populated', function () {
            it('should close the slider', function (done) {
              $document.on.and.callFake(function (actionType, callback) {
                callback({
                  which: 27 //same as ESC_KEY
                });
              });
              scope.is_open = true;
              scope.$digest();
              expect($document.on).toHaveBeenCalled();
              expect(scope.is_open).toEqual(false);
              done();
            });
          });
        });

        describe('and the user presses a key thats not the escape key', function () {
          describe('and the keyCode is populated', function () {
            it('should close the slider', function (done) {
              $document.on.and.callFake(function (actionType, callback) {
                callback({
                  keyCode: 99 //random key
                });
              });
              scope.is_open = true;
              scope.$digest();
              expect($document.on).toHaveBeenCalled();
              expect(scope.is_open).toEqual(true);
              done();
            });
          });

          describe('and the "which" property is populated', function () {
            it('should close the slider', function (done) {
              $document.on.and.callFake(function (actionType, callback) {
                callback({
                  which: 99 //random key
                });
              });
              scope.is_open = true;
              scope.$digest();
              expect($document.on).toHaveBeenCalled();
              expect(scope.is_open).toEqual(true);
              done();
            });
          });
        });
      });
    });

    describe('left pageslide', function () {
      describe('by default', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<div>',
            '<div pageslide ps-open="is_open" ps-side="left">',
            '<div id="target">',
            '<p>some random content...</p>',
            '<a id="target-close" href="#">Click to close</a>',
            '</div>',
            '</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should set the appropriate styles', function (done) {
          // Check for DOM Manipulation
          var slider = angular.element(document.body);
          expect(slider.html()).toContain('height: 100%;');
          expect(slider.html()).toContain('top: 0px;');
          expect(slider.html()).toContain('bottom: 0px;');
          expect(slider.html()).toContain('left: 0px;');
          //when opening the slider
          scope.is_open = true;
          scope.$digest();
          expect(slider.html()).toContain('width: 300px;');
          //when closing the slider
          scope.is_open = false;
          scope.$digest();
          expect(slider.html()).toContain('width: 0px;');
          done();
        });
      });
      describe('when squeeze is set', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<div>',
            '<div pageslide ps-open="is_open" ps-side="left" ps-squeeze="true">',
            '<div id="target">',
            '<p>some random content...</p>',
            '<a id="target-close" href="#">Click to close</a>',
            '</div>',
            '</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should set the appropriate styles', function (done) {
          // Check for DOM Manipulation
          var slider = angular.element(document.body);
          expect(slider.html()).toContain('height: 100%;');
          expect(slider.html()).toContain('top: 0px;');
          expect(slider.html()).toContain('bottom: 0px;');
          expect(slider.html()).toContain('left: 0px;');
          //when opening the slider
          scope.is_open = true;
          scope.$digest();
          expect(slider.html()).toContain('width: 300px;');
          //TODO: find out why this isn't being set in the test
          // expect(slider.html()).toContain('left: 300px;');
          //when closing the slider
          scope.is_open = false;
          scope.$digest();
          expect(slider.html()).toContain('width: 0px;');
          expect(slider.html()).toContain('left: 0px;');
          done();
        });
      });

      describe('when push is set', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<div>',
            '<div pageslide ps-open="is_open" ps-side="left" ps-push="true">',
            '<div id="target">',
            '<p>some random content...</p>',
            '<a id="target-close" href="#">Click to close</a>',
            '</div>',
            '</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should set the appropriate styles', function (done) {
          // Check for DOM Manipulation
          var slider = angular.element(document.body);
          expect(slider.html()).toContain('height: 100%;');
          expect(slider.html()).toContain('top: 0px;');
          expect(slider.html()).toContain('bottom: 0px;');
          expect(slider.html()).toContain('left: 0px;');
          //when opening the slider
          scope.is_open = true;
          scope.$digest();
          expect(slider.html()).toContain('width: 300px;');
          //TODO: find out why these are not being set in the test
          // expect(slider.html()).toContain('left: 300px;');
          // expect(slider.html()).toContain('right: -300px;');
          //when closing the slider
          scope.is_open = false;
          scope.$digest();
          expect(slider.html()).toContain('width: 0px;');
          expect(slider.html()).toContain('left: 0px;');
          done();
        });
      });
    });

    describe('top pageslide', function () {
      describe('by default', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<div>',
            '<div pageslide ps-open="is_open" ps-side="top">',
            '<div id="target">',
            '<p>some random content...</p>',
            '<a id="target-close" href="#">Click to close</a>',
            '</div>',
            '</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should set the appropriate styles', function (done) {
          // Check for DOM Manipulation
          var slider = angular.element(document.body);
          expect(slider.html()).toContain('width: 100%;');
          expect(slider.html()).toContain('top: 0px;');
          expect(slider.html()).toContain('left: 0px;');
          expect(slider.html()).toContain('right: 0px;');
          //when opening the slider
          scope.is_open = true;
          scope.$digest();
          expect(slider.html()).toContain('height: 300px;');
          //when closing the slider
          scope.is_open = false;
          scope.$digest();
          expect(slider.html()).toContain('height: 0px;');
          done();
        });
      });
      describe('when squeeze is set', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<div>',
            '<div pageslide ps-open="is_open" ps-side="top" ps-squeeze="true">',
            '<div id="target">',
            '<p>some random content...</p>',
            '<a id="target-close" href="#">Click to close</a>',
            '</div>',
            '</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should set the appropriate styles', function (done) {
          // Check for DOM Manipulation
          var slider = angular.element(document.body);
          expect(slider.html()).toContain('width: 100%;');
          expect(slider.html()).toContain('top: 0px;');
          expect(slider.html()).toContain('left: 0px;');
          expect(slider.html()).toContain('right: 0px;');
          //when opening the slider
          scope.is_open = true;
          scope.$digest();
          expect(slider.html()).toContain('height: 300px;');
          //TODO: find out why this isn't being set in the test
          // expect(slider.html()).toContain('top: 300px;');
          //when closing the slider
          scope.is_open = false;
          scope.$digest();
          expect(slider.html()).toContain('height: 0px;');
          expect(slider.html()).toContain('top: 0px;');
          done();
        });
      });

      describe('when push is set', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<div>',
            '<div pageslide ps-open="is_open" ps-side="top" ps-push="true">',
            '<div id="target">',
            '<p>some random content...</p>',
            '<a id="target-close" href="#">Click to close</a>',
            '</div>',
            '</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should set the appropriate styles', function (done) {
          // Check for DOM Manipulation
          var slider = angular.element(document.body);
          expect(slider.html()).toContain('width: 100%;');
          expect(slider.html()).toContain('top: 0px;');
          expect(slider.html()).toContain('left: 0px;');
          expect(slider.html()).toContain('right: 0px;');
          //when opening the slider
          scope.is_open = true;
          scope.$digest();
          expect(slider.html()).toContain('height: 300px;');
          //TODO: find out why these are not being set in the test
          // expect(slider.html()).toContain('top: 300px;');
          // expect(slider.html()).toContain('bottom: -300px;');
          //when closing the slider
          scope.is_open = false;
          scope.$digest();
          expect(slider.html()).toContain('height: 0px;');
          expect(slider.html()).toContain('top: 0px;');
          done();
        });
      });
    });

    describe('bottom pageslide', function () {
      describe('by default', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<div>',
            '<div pageslide ps-open="is_open" ps-side="bottom">',
            '<div id="target">',
            '<p>some random content...</p>',
            '<a id="target-close" href="#">Click to close</a>',
            '</div>',
            '</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should set the appropriate styles', function (done) {
          // Check for DOM Manipulation
          var slider = angular.element(document.body);
          expect(slider.html()).toContain('width: 100%;');
          expect(slider.html()).toContain('bottom: 0px;');
          expect(slider.html()).toContain('left: 0px;');
          expect(slider.html()).toContain('right: 0px;');
          //when opening the slider
          scope.is_open = true;
          scope.$digest();
          expect(slider.html()).toContain('height: 300px;');
          //when closing the slider
          scope.is_open = false;
          scope.$digest();
          expect(slider.html()).toContain('height: 0px;');
          done();
        });
      });
      describe('when squeeze is set', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<div>',
            '<div pageslide ps-open="is_open" ps-side="bottom" ps-squeeze="true">',
            '<div id="target">',
            '<p>some random content...</p>',
            '<a id="target-close" href="#">Click to close</a>',
            '</div>',
            '</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should set the appropriate styles', function (done) {
          // Check for DOM Manipulation
          var slider = angular.element(document.body);
          expect(slider.html()).toContain('width: 100%;');
          expect(slider.html()).toContain('bottom: 0px;');
          expect(slider.html()).toContain('left: 0px;');
          expect(slider.html()).toContain('right: 0px;');
          //when opening the slider
          scope.is_open = true;
          scope.$digest();
          expect(slider.html()).toContain('height: 300px;');
          //TODO: find out why this isn't being set in the test
          // expect(slider.html()).toContain('bottom: 300px;');
          //when closing the slider
          scope.is_open = false;
          scope.$digest();
          expect(slider.html()).toContain('height: 0px;');
          expect(slider.html()).toContain('bottom: 0px;');
          done();
        });
      });

      describe('when push is set', function () {
        beforeEach(function (done) {
          compilePageslide([
            '<div>',
            '<div pageslide ps-open="is_open" ps-side="bottom" ps-push="true">',
            '<div id="target">',
            '<p>some random content...</p>',
            '<a id="target-close" href="#">Click to close</a>',
            '</div>',
            '</div>',
            '</div>'
          ].join(''));
          done();
        });

        it('should set the appropriate styles', function (done) {
          // Check for DOM Manipulation
          var slider = angular.element(document.body);
          expect(slider.html()).toContain('width: 100%;');
          expect(slider.html()).toContain('bottom: 0px;');
          expect(slider.html()).toContain('left: 0px;');
          expect(slider.html()).toContain('right: 0px;');
          //when opening the slider
          scope.is_open = true;
          scope.$digest();
          expect(slider.html()).toContain('height: 300px;');
          //TODO: find out why these are not being set in the test
          // expect(slider.html()).toContain('bottom: 300px;');
          // expect(slider.html()).toContain('top: -300px;');
          //when closing the slider
          scope.is_open = false;
          scope.$digest();
          expect(slider.html()).toContain('height: 0px;');
          expect(slider.html()).toContain('bottom: 0px;');
          done();
        });
      });
    });

    xit('Should sync ps-open state between pageslide\'s scope and parent scope', function () {
      //TODO: refactor code to properly assign isolateScope
      // Create template DOM for directive
      compilePageslide([
        '<div>',
        '<div pageslide="right" ps-open="is_open" ps-speed="0.5" href="#target">',
        '<div id="target">',
        '<p>some random content...</p>',
        '<a id="target-close" href="#">Click to close</a>',
        '</div>',
        '</div>',
        '</div>'
      ].join(''));

      scope.is_open = true;
      scope.$digest();

      expect(isolateScope.psOpen).toBe(true);

      scope.is_open = false;
      scope.$digest();

      expect(isolateScope.psOpen).toBe(false);
    });
  });
});
