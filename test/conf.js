exports.config = {
    seleniumAddress: 'http://localhost:4444/wd/hub',
    specs: ['basic-spec.js'],
    onPrepare: function() {
      browser.ignoreSynchronization = true;
    }
};

