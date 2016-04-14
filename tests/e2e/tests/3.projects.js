/**
 * Test requirements (for now):
 *  - Internet connectivity
 *  - Available default community registry
 *  - Folder .eintopf/xy/configs/testProject should not exist prior launching the test
 *  - Container of the testProject should not run
 */

var testProject = 'e2e-test';

module.exports = {
  "@tags": ["docker"],

  beforeEach: function(browser, done) {
    browser.waitForElementPresent("img[alt='einTOPF']", 10000, done);
  },

  afterEach: function(browser, done) {
    browser.closeWindow().end(done);
  },

  //@todo tests for project creation
  //"project descriptions 'PHP dev' should be installed and marked as this": function (browser){
  //    browser.waitForElementPresent(".cssPattern[data-name=\"PHP dev\"]", 15000);
  //    browser.click(".cssPattern[data-name=\"PHP dev\"] button");
  //    browser.waitForElementNotPresent(".cssPattern[data-name=\"PHP dev\"] button", 10000);
  //    browser.expect.element(".cssMenu li#eintopfphpdev").to.be.present.after(4000);
  //    browser.click("a[ui-sref=\"cooking.projects.create\"]");
  //    browser.pause(3000);
  //    browser.assert.cssClassPresent(".cssPattern[data-name=\"PHP dev\"] .media", "disabled");
  //},



  "Recipe 'PHP dev' should be available": function (browser){
    browser.waitForElementPresent(".cssPattern[data-name=\"PHP dev\"]", 15000);
    browser.expect.element(".cssPattern[data-name=\"PHP dev\"]").to.be.present;
    browser.expect.element(".cssPattern[data-name=\"PHP dev\"] button").text.to.contain("Clone");
  },

  "Recipe 'PHP dev' should open clone form": function (browser){
    browser.waitForElementPresent(".cssPattern[data-name=\"PHP dev\"]", 15000);
    browser.click(".cssPattern[data-name=\"PHP dev\"] button");
    browser.waitForElementNotPresent(".cssPattern[data-name=\"PHP dev\"] button", 10000);

    browser.expect.element("#container").text.to.contain("Clone Project");
    browser.expect.element("input#projectId").to.be.present;
    browser.expect.element("input#projectName").to.be.present;
    browser.expect.element("textarea#projectDescription").to.be.present;
  },

  //@todo initial environment
  "Should clone project 'PHP dev'": function (browser){
    browser.waitForElementPresent(".cssPattern[data-name=\"PHP dev\"]", 15000);
    browser.click(".cssPattern[data-name=\"PHP dev\"] button");
    browser.waitForElementNotPresent(".cssPattern[data-name=\"PHP dev\"] button", 10000);

    browser.setValue('input#projectId', testProject);
    browser.setValue('input#projectName', testProject);
    browser.setValue('textarea#projectDescription', testProject);
    browser.click("#buttonCloneProject");

    browser.waitForElementPresent(".cssPatternBig", 10000);
    browser.expect.element("#container").text.to.contain(testProject);
  },

  "Should fail cloning because id exists": function (browser){
    browser.waitForElementPresent(".cssPattern[data-name=\"PHP dev\"]", 15000);
    browser.click(".cssPattern[data-name=\"PHP dev\"] button");
    browser.waitForElementNotPresent(".cssPattern[data-name=\"PHP dev\"] button", 10000);

    browser.setValue('input#projectId', testProject);
    browser.setValue('input#projectName', testProject);
    browser.setValue('textarea#projectDescription', testProject);
    browser.click("#buttonCloneProject");

    browser.waitForElementVisible("[ng-if=\"errorMessage\"]", 9000);
    browser.expect.element("[ng-if=\"errorMessage\"]").text.to.contain("Project description with this id already exists");
  },

  "Should list project in the project sidebar": function (browser){
      browser.expect.element(".cssMenu li#" + testProject).to.be.present;
      browser.assert.cssClassPresent(".cssMenu li#" + testProject + " i", "fa-pause");
      browser.assert.cssClassNotPresent(".cssMenu li#" + testProject + " i", "fa-play", "Okay " + testProject + " is not running");
  },

  //@todo initial environment
  "Should start project": function (browser){
    browser.pause(5000); // wait for runtime stream info
    browser.expect.element(".cssMenu li#" + testProject + " button").to.be.visible;
    browser.assert.cssClassPresent(".cssMenu li#" + testProject + " i", "fa-pause");
    browser.click(".cssMenu li#" + testProject + " button");
    browser.waitForElementPresent(".cssMenu li#" + testProject + " i.fa-play", 20000);
  },

  "Should display app in apps tab of project detail page": function (browser){
    browser.pause(5000); // wait for runtime stream info
    browser.click(".cssMenu li#" + testProject);
    browser.waitForElementPresent("#containerProjectDetail", 1000);
    browser.expect.element(".cssTab li.tab_running_apps").to.be.present;
    browser.click(".cssTab > li.tab_running_apps");

    browser.pause(500);
    browser.expect.element("[ng-show=\"currentTab == 'apps'\"]").text.to.match(/php.dev:4480/i);
  },

  "Should display a active container in containers tab of project detail page": function (browser){
    browser.pause(5000); // wait for runtime stream info
    browser.click(".cssMenu li#" + testProject);
    browser.waitForElementPresent("#containerProjectDetail", 1000);
    browser.expect.element(".cssTab li.tab_containers").to.be.present;
    browser.click(".cssTab li.tab_containers");

    browser.pause(500);
    browser.expect.element("[ng-show=\"currentTab == 'containers'\"]").text.to.match(new RegExp(testProject.replace(/[^a-zA-Z0-9]/ig, ""), "i"));
    browser.expect.element("[ng-show=\"currentTab == 'containers'\"] .cssSwitchBg").text.to.equal("ON");
  },

  "should have a active 'running app' container": function (browser){
    browser.click("a[ui-sref=\"panel.main\"]");
    browser.pause(500);

    browser.click("a[ui-sref=\"panel.apps\"]");
    browser.pause(500);

    browser.waitForElementPresent("[ng-repeat=\"app in apps\"]", 1000);
    browser.assert.containsText(".cssPanelHead", "Running apps");
    browser.expect.element(".cssPanelBox").text.to.match(/php.dev:/ig).after(1000);
  },

  //@todo initial environment
  "Should stop project": function (browser){
    browser.pause(5000); // wait for runtime stream info
    browser.expect.element(".cssMenu li#" + testProject + " button").to.be.visible;
    browser.assert.cssClassPresent(".cssMenu li#" + testProject + " i", "fa-play");
    browser.click(".cssMenu li#" + testProject + " button");
    browser.waitForElementPresent(".cssMenu li#" + testProject + " i.fa-pause", 20000);
  }

};