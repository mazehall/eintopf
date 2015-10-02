'use strict';

require('coffee-script/register');
var config = require('config');

var customConfig = require("../../../models/stores/config.coffee");

describe("config store", function () {

  it('should return a object', function() {
    expect(typeof customConfig).toBe('object');
  });

  it('should inherit config functions', function() {
    expect(customConfig.has).toBe(config.has);
    expect(customConfig.get).toBe(config.get);
  });

  it('should inherit config util functions', function() {
    expect(typeof customConfig.util).toBe('object');
    expect(customConfig.util.setModuleDefaults).toBe(config.util.setModuleDefaults);
    expect(customConfig.util.makeImmutable).toBe(config.util.makeImmutable);
  });

  it('should still have a working get function', function() {
    expect(customConfig.get('test.key')).toBe('value');
  });

  it('should throw error when setting existing var because of immutability', function() {
    var setConfigTestVar = function() {
      config.test.key = 'someOtherValue';
    };
    expect(setConfigTestVar).toThrow("Cannot assign to read only property 'key' of #<Object>");
  });

});