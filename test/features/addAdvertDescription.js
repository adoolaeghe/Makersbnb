process.env.NODE_ENV = 'test';
var app = require('../../app.js');
var Browser = require('zombie');
var assert = require('assert');
var http = require('http');


describe("entering details for new advert", function(){

  before(function() {
    this.server = http.createServer(app).listen(3000);

    this.browser = new Browser({ site: 'http://localhost:3000' });
  });

  before(function(done) {
    this.browser.visit('/new-advert', done);
  });

  it('should show an advert that has been posted', function(done){
    var browser = this.browser;
    browser.fill('.advertName', "buckingham");
    browser.pressButton('.submitAdBtn', function(error){
      if (error) return done(error);
      browser.assert.elements('.listing',{ atLeast:1 });
      done();
    });
  });

  after(function(done) {
    this.server.close(done);
  });
});
