module.exports = {
    beforeEach : function(browser) {
        browser.waitForEintopfStart = function(){
            return browser.waitForElementPresent("img[alt='einTOPF']", 35000).pause(1000);
        }
    },

    "should list the community patterns in 'Create Project' page": function (browser){
        browser.waitForElementVisible("#content", 25000);
        browser.assert.containsText("#content", "Create Project");
        browser.expect.element("#content").text.to.contain("Community Pattern");
        browser.expect.element(".cssPattern").to.be.present;
        browser.end();
    },

    "should navigate to settings and display the vagrant ssh config": function (browser){
        browser.waitForEintopfStart();
        browser.expect.element("a[title=\"settings\"]").to.be.present;
        browser.click("a[title=\"settings\"]");
        browser.pause(500);
        browser.expect.element("#content").text.to.contain("Vagrant ssh config").after(1000);
        browser.getValue("[ng-show=\"settings.vagrantSshConfig\"] [type=\"text\"]", function(result){
            this.assert.equal(result.state, "success");
        });
        browser.end();
    },

    "should display an error when a non git-url is used for project installation": function (browser){
        browser.waitForEintopfStart();
        browser.expect.element("form #projectName").to.be.visible;
        browser.setValue("form #projectName", ["www.localhost", browser.Keys.ENTER]);
        browser.submitForm("form #projectName");
        browser.waitForElementVisible("[ng-show=\"result.errorMessage\"]", 9000);
        browser.expect.element("[ng-show=\"result.errorMessage\"]").text.to.contain("invalid or unsupported git url");
        browser.end();
    }
};