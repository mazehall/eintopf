module.exports = {
    "@tags": ["docker"],

    "project descriptions 'PHP dev' should be available": function (browser){
        browser.waitForEintopfStart();
        browser.waitForElementPresent(".cssPattern[data-name=\"PHP dev\"]", 15000);
        browser.expect.element(".cssMenu li#eintopfphpdev").to.be.not.present;
        browser.expect.element(".cssPattern[data-name=\"PHP dev\"]").to.be.present;
        browser.expect.element(".cssPattern[data-name=\"PHP dev\"] button").text.to.contain("Create");
        browser.endSession();
    },

    "project descriptions 'PHP dev' should be installed and marked as this": function (browser){
        browser.waitForEintopfStart();
        browser.waitForElementPresent(".cssPattern[data-name=\"PHP dev\"]", 15000);
        browser.click(".cssPattern[data-name=\"PHP dev\"] button");
        browser.waitForElementNotPresent(".cssPattern[data-name=\"PHP dev\"] button", 10000);
        browser.expect.element(".cssMenu li#eintopfphpdev").to.be.present.after(4000);
        browser.click("a[ui-sref=\"cooking.projects.create\"]");
        browser.pause(3000);
        browser.assert.cssClassPresent(".cssPattern[data-name=\"PHP dev\"] .media", "disabled");
        browser.endSession();
    },

    "project descriptions 'PHP dev' should be listed in the project sidebar": function (browser){
        browser.waitForEintopfStart();
        browser.expect.element(".cssMenu li#eintopfphpdev").to.be.present;
        browser.assert.cssClassPresent(".cssMenu li#eintopfphpdev i", "fa-power-off");
        browser.assert.cssClassNotPresent(".cssMenu li#eintopfphpdev i", "fa-spin", "Okay project PHP dev is not running");
        browser.endSession();
    },

    "project description 'PHP dev' should start a container and marked as this": function (browser){
        browser.waitForEintopfStart();
        browser.expect.element(".cssMenu li#eintopfphpdev > a.btn--link").to.be.visible;
        browser.click(".cssMenu li#eintopfphpdev > a.btn--link");
        browser.waitForElementPresent(".cssToolbar", 1000);
        browser.expect.element(".cssToolbar li.run > a").to.be.present;
        browser.click(".cssToolbar li.run > a");
        browser.waitForElementPresent(".cssMenu li#eintopfphpdev i.fa-spin", 120000);
        browser.endSession();
    },

    "running projects should have two new tabs of their project detail page": function (browser){
        browser.waitForEintopfStart();
        browser.click(".cssMenu li#eintopfphpdev > a.btn--link");
        browser.waitForElementPresent(".cssToolbar", 1000).pause(3000);
        browser.expect.element(".cssTab").text.to.match(/Containers/i);
        browser.expect.element(".cssTab").text.to.match(/Running Apps/i);
        browser.endSession();
    },

    "running projects should have 'running app´s' of their project detail page": function (browser){
        browser.waitForEintopfStart();
        browser.click(".cssMenu li#eintopfphpdev > a.btn--link");
        browser.waitForElementPresent(".cssToolbar", 1000).pause(3000);
        browser.expect.element(".cssTab > li.tab_running_apps").to.be.present;
        browser.click(".cssTab > li.tab_running_apps");

        browser.pause(500);
        browser.expect.element("[ng-show=\"currentTab == 'apps'\"]").text.to.match(/php.dev:4480/i);
        browser.endSession();
    },

    "running projects should have a active container of their project detail page": function (browser){
        browser.waitForEintopfStart();
        browser.click(".cssMenu li#eintopfphpdev > a.btn--link");
        browser.waitForElementPresent(".cssToolbar", 1000).pause(3000);
        browser.expect.element(".cssTab > li.tab_containers").to.be.present;
        browser.click(".cssTab > li.tab_containers");

        browser.pause(500);
        browser.expect.element("[ng-show=\"currentTab == 'containers'\"]").text.to.match(/eintopfphpdev/i);
        browser.expect.element("[ng-show=\"currentTab == 'containers'\"] .cssSwitchBg").text.to.equal("ON");
        browser.endSession();
    },

    before: function(browser) {
        browser.waitForEintopfStart = function(){
            return browser.waitForElementPresent("img[alt='einTOPF']", 35000).pause(1000);
        };
        browser.endSession = function(){
            return browser.closeWindow().end();
        };
    }
};