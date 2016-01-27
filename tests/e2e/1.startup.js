module.exports = {
    "should load mazehall and node modules without an error": function (browser){
        browser.waitForElementVisible("html", 2000);
        browser.expect.element("html").text.to.not.match(/Cannot GET/ig);
        browser.endSession();
    },

    "should set the title to 'eintopf' when mazehall module 'gui' loaded": function (browser){
        browser.pause(1000);
        browser.assert.title("Eintopf");
        browser.endSession();
    },

    "should start the server and show the project list": function (browser){
        browser.waitForElementVisible(".cssSetup", 2000);
        browser.expect.element(".cssSetup").text.to.contain("Start VirtualBox").after(5000);
        browser.waitForEintopfStart();
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