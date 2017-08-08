process.env.NODE_ENV = 'test';
var app = require('../../app.js');
var Browser = require('zombie');
var assert = require('assert');
var http = require('http');

// http://www.redotheweb.com/2013/01/15/functional-testing-for-nodejs-using-mocha-and-zombie-js.html

describe('Confirm a booking', function() {

  before(function() {
    this.server = http.createServer(app).listen(3000);
    // initialize the browser using the same port as the test application
    this.browser = new Browser({ site: 'http://localhost:3000' });
  });

  // load the contact page
  before(function(done) {
    this.browser.visit('/', done);
  });

  it('should display true when bookAdvert button is clicked', function(){
    var browser = this.browser;
    browser.fill('advertName', 'home');
    browser.pressButton('addAdvert').then(function() {
      browser.pressButton('bookAdvert').then(function() {
        assert.equal(browser.text('.advert1Booked'), 'true');
      });
    });
  });

  after(function(done) {
    this.server.close(done);
  });
});
