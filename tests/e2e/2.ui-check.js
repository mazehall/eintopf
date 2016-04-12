module.exports = {

  beforeEach: function(browser, done) {
    browser.waitForElementPresent("img[alt='einTOPF']", 10000, done);
  },

  afterEach: function(browser, done) {
    browser.closeWindow().end(done);
  },

  "should list the community patterns in 'Create Project' page": function (browser){
    browser.waitForElementVisible("#content", 25000);
    browser.assert.containsText("#content", "Create Project");
    browser.expect.element("#content").text.to.contain("Community Pattern");
    browser.expect.element(".cssPattern").to.be.present;
  },

  "should display an error when a non git-url is used for project installation": function (browser){
    browser.expect.element("form #projectName").to.be.visible;
    browser.setValue("form #projectName", ["www.localhost", browser.Keys.ENTER]);
    browser.click("#buttonRegisterUrl");
    browser.waitForElementVisible("[ng-show=\"errorMessage\"]", 9000);
    browser.expect.element("[ng-show=\"errorMessage\"]").text.to.contain("Invalid project url");
  },

  "should settings panel and display 3 links": function (browser){
    browser.expect.element("a[ui-sref=\"panel.main\"]").to.be.present;
    browser.click("a[ui-sref=\"panel.main\"]");
    browser.pause(500);
    browser.expect.element("a[ui-sref=\"panel.containers\"]").to.be.present;
    browser.expect.element("a[ui-sref=\"panel.apps\"]").to.be.present;
    browser.expect.element("a[ui-sref=\"panel.settings\"]").to.be.present;
  },

  "should navigate to settings and display the vagrant ssh config": function (browser){
    browser.click("a[ui-sref=\"panel.main\"]");
    browser.pause(500);

    browser.click("a[ui-sref=\"panel.settings\"]");
    browser.pause(500);
    browser.expect.element("div[ui-view=\"panelContent\"]").text.to.contain("ssh config");
    browser.getValue("[ng-show=\"settings.vagrantSshConfig\"] [type=\"text\"]", function(result){
        this.assert.equal(result.state, "success");
    });
  },

  "should navigate to containers and display the vagrant ssh config": function (browser){
    browser.click("a[ui-sref=\"panel.main\"]");
    browser.pause(500);

    browser.click("a[ui-sref=\"panel.containers\"]");
    browser.pause(500);
    browser.expect.element("div[ui-view=\"panelContent\"]").text.to.contain("Name", "Status");
  },

  "should navigate to apps and display the vagrant ssh config": function (browser){
    browser.click("a[ui-sref=\"panel.main\"]");
    browser.pause(500);

    browser.click("a[ui-sref=\"panel.apps\"]");
    browser.pause(500);
    browser.expect.element("div[ui-view=\"panelContent\"]").text.to.contain("url");
  },

  "should close panel": function (browser){
    browser.click("a[ui-sref=\"panel.main\"]");
    browser.pause(500);

    browser.click("#buttonClosePanel");
    browser.pause(500);
    browser.expect.element("div[ui-view=\"panelContent\"]").to.not.be.present;
  }

  //@todo menu toolbar

};