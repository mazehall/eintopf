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
    }
};