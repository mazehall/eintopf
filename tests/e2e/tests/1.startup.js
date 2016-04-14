module.exports = {

  afterEach: function(browser, done) {
    browser.closeWindow().end(done);
  },

  //@todo test not reliable because Eintopf could start to quick
  //"should show init state": function (browser){
  //  browser.waitForElementVisible(".cssSetup", 10000);
  //  browser.expect.element(".cssSetup").text.to.contain("check Vagrant config");
  //  browser.expect.element(".cssSetup").text.to.contain("check and start Eintopf-Docker-Service")
  //},
  //
  //"should set the title to 'eintopf' when mazehall module 'gui' loaded": function (browser){
  //  browser.waitForElementPresent("img[alt='einTOPF']", 10000);
  //  browser.pause(1000);
  //  browser.assert.title("Eintopf");
  //}

};