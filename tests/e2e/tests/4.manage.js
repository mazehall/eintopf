var testProject = 'e2e-test';

//@todo improve id naming
module.exports = {
  "@tags": ["docker"],

  beforeEach: function(browser, done) {
    browser.waitForElementPresent("img[alt='einTOPF']", 10000, done);
  },

  afterEach: function(browser, done) {
    browser.closeWindow().end(done);
  },

  "should switch to the 'logs' tab when project starts": function (browser){
    browser.pause(5000); // wait for runtime stream info
    browser.expect.element(".cssMenu li#" + testProject + " button").to.be.visible;
    browser.assert.cssClassPresent(".cssMenu li#" + testProject + " i", "fa-pause");
    browser.click(".cssMenu li#" + testProject + " button");

    browser.pause(500);

    browser.assert.containsText("#tabLabelLog", "Logs");
    browser.expect.element("#tabContentLog").to.be.visible;
  },

  "should switch to the 'logs' tab when description update starts": function (browser){
    browser.pause(5000); // wait for runtime stream info

    browser.expect.element(".cssMenu li#" + testProject).to.be.visible;
    browser.click(".cssMenu li#" + testProject);
    browser.pause(500);

    browser.click("#buttonProjectPopup");
    browser.pause(500);

    browser.click("#update");
    browser.pause(500);

    browser.assert.containsText("#tabLabelLog", "Logs");
    browser.expect.element("#tabContentLog").to.be.visible;
  },

  "should switch to the 'logs' tab when stopping a project": function (browser){
    browser.pause(5000); // wait for runtime stream info
    browser.expect.element(".cssMenu li#" + testProject + " button").to.be.visible;
    browser.assert.cssClassPresent(".cssMenu li#" + testProject + " i", "fa-play");
    browser.click(".cssMenu li#" + testProject + " button");

    browser.pause(500);

    browser.assert.containsText("#tabLabelLog", "Logs");
    browser.expect.element("#tabContentLog").to.be.visible;
  },

  "should be removed from the sidebar when deleted a project": function (browser){
    browser.pause(5000); // wait for runtime stream info

    browser.expect.element(".cssMenu li#" + testProject).to.be.visible;
    browser.click(".cssMenu li#" + testProject);
    browser.pause(500);

    browser.click("#buttonProjectPopup");
    browser.pause(500);

    browser.click("#hide");
    browser.pause(500);

    browser.expect.element(".cssMenu li#" + testProject).to.not.be.present.after(1000);
  }

};