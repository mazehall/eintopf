module.exports = {
  "@tags": ["docker", "proxy"],

  beforeEach: function(browser, done) {
    browser.waitForElementPresent("img[alt='einTOPF']", 10000, done);
  },

  afterEach: function(browser, done) {
    browser.closeWindow().end(done);
  },

  "should have a active 'running app' container": function (browser){
    browser.pause(20000);

    browser.click("a[ui-sref=\"panel.main\"]");
    browser.pause(500);

    browser.click("a[ui-sref=\"panel.apps\"]");
    browser.pause(500);

    browser.waitForElementPresent("[ng-repeat=\"app in apps\"]", 1000);
    browser.assert.containsText(".cssPanelHead", "Running apps");
    browser.expect.element(".cssPanelBox").text.to.match(/php.dev:/ig).after(1000);
  },

  "should have a active 'proxy' container": function (browser){
    browser.pause(5000);

    browser.click("a[ui-sref=\"panel.main\"]");
    browser.pause(500);

    browser.click("a[ui-sref=\"panel.containers\"]");
    browser.pause(500);

    browser.waitForElementPresent("[ng-repeat=\"(key, value) in containers\"]", 1000);
    browser.expect.element(".cssPanelBox").text.to.match(/proxy/ig);
  }

};