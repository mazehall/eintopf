module.exports = {
    "@tags": ["docker", "proxy"],

    "should have a active 'running app' container": function (browser){
        browser.waitForEintopfStart();
        browser.expect.element("a[ui-sref=\"cooking.apps\"]").to.be.present;
        browser.click("a[ui-sref=\"cooking.apps\"]");
        browser.waitForElementPresent("[ng-repeat=\"app in apps\"]", 1000);
        browser.assert.containsText(".list--unstyled > .grd-row.muted", "running apps");
        browser.expect.element(".grd.list--unstyled.cssContainer").text.to.match(/php.dev:/ig).after(1000);
        browser.endSession();
    },

    "should have a active 'proxy' container": function (browser){
        browser.waitForEintopfStart();
        browser.expect.element("a[ui-sref=\"cooking.containers\"]").to.be.present;
        browser.click("a[ui-sref=\"cooking.containers\"]");
        browser.waitForElementPresent("[ng-repeat=\"(key, value) in containers\"]", 1000);
        browser.expect.element(".grd.list--unstyled.cssContainer").text.to.match(/proxy/ig);
        browser.endSession();
    },

    "should call a project url": function (browser){
        browser.init("http://php.dev:4480/index.php");
        browser.waitForElementVisible("html", 2000);
        browser.assert.containsText("html", "Hello world");
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