module.exports = {
    "@tags": ["docker"],
    beforeEach : function(browser) {
        browser.waitForEintopfStart = function(){
            return browser.waitForElementPresent("img[alt='einTOPF']", 35000).pause(1000);
        }
    },

    "should switch to the 'logs' tab when project starts": function (browser){
        browser.waitForEintopfStart();
        browser.expect.element(".cssMenu li#eintopfphpdev > a.btn--link").to.be.visible;
        browser.click(".cssMenu li#eintopfphpdev > a.btn--link");
        browser.waitForElementPresent(".cssToolbar", 1000);

        browser.expect.element(".cssToolbar li.run > a").to.be.present;
        browser.click(".cssToolbar li.run > a");
        browser.assert.containsText("ul.cssTab > li.cssActive", "Logs");
        browser.expect.element("[marked=\"protocol\"]").to.be.visible;
        browser.end();
    },

    "should switch to the 'logs' tab when description update starts": function (browser){
        browser.waitForEintopfStart();
        browser.expect.element(".cssMenu li#eintopfphpdev > a.btn--link").to.be.visible;
        browser.click(".cssMenu li#eintopfphpdev > a.btn--link");
        browser.waitForElementPresent(".cssToolbar", 1000);

        browser.expect.element(".cssToolbar li.update > a").to.be.present;
        browser.click(".cssToolbar li.update > a");
        browser.assert.containsText("ul.cssTab > li.cssActive", "Logs");
        browser.expect.element("[marked=\"protocol\"]").to.be.visible;
        browser.end();
    },

    "should remove the 'running' css class and switch to the 'logs' tab by stopping a project": function (browser){
        browser.waitForEintopfStart();
        browser.expect.element(".cssMenu li#eintopfphpdev > a.btn--link").to.be.visible;
        browser.click(".cssMenu li#eintopfphpdev > a.btn--link");
        browser.waitForElementPresent(".cssToolbar", 1000);

        browser.expect.element(".cssToolbar li.stop > a").to.be.present;
        browser.click(".cssToolbar li.stop > a");
        browser.waitForElementNotPresent(".cssMenu li#eintopfphpdev i.fa-spin", 30000);
        browser.assert.cssClassPresent(".cssMenu li#eintopfphpdev i", "fa-power-off", "Project is not running");

        browser.assert.containsText("ul.cssTab > li.cssActive", "Logs");
        browser.expect.element("[marked=\"protocol\"]").to.be.visible;
        browser.end();
    },

    "should be removed from the sidebar when deleted a project": function (browser){
        browser.waitForEintopfStart();
        browser.expect.element(".cssMenu li#eintopfphpdev > a.btn--link").to.be.visible;
        browser.click(".cssMenu li#eintopfphpdev > a.btn--link");
        browser.waitForElementPresent(".cssToolbar", 1000);
        browser.expect.element(".cssToolbar li.delete > a").to.be.present;
        browser.click(".cssToolbar li.delete > a");

        browser.waitForElementNotPresent(".cssToolbar", 10000);
        browser.expect.element(".cssMenu li#eintopfphpdev").to.not.be.present.after(1000);
        browser.end();
    }
};