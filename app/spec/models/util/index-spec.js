'use strict';

require('coffee-script/register');
var config = require('config');

var utils = require('../../../models/util/index.coffee');

describe("set config", function () {

  beforeEach(function() {
    utils.setConfig(config);
  });

  it('should return false when no object was set', function() {
    expect(utils.setConfig('string')).toBeFalsy();
    expect(utils.setConfig(12345)).toBeFalsy();
  });

  it('should return null when object was set', function() {
    expect(utils.setConfig(config)).toBeTruthy();
  })

});

describe("get Eintopf home", function () {
  var orig = process.env;

  afterEach(function() {
    process.env = orig;
  });

  it("should return windows home");
  it("should return linux home");

  it("should return custom home", function() {
    process.env.EINTOPF_HOME = '/my/custom/home';
    expect(utils.getEintopfHome()).toBe(process.env.EINTOPF_HOME);
  });

});