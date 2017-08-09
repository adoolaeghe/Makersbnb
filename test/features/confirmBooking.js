process.env.NODE_ENV = 'test';
var app = require('../../app.js');
var Browser = require('zombie');
var assert = require('assert');
var http = require('http');

// http://www.redotheweb.com/2013/01/15/functional-testing-for-nodejs-using-mocha-and-zombie-js.html

describe('Confirm a booking', function() {

  before(function() {
    this.server = http.createServer(app).listen(3000);
    this.browser = new Browser({ site: 'http://localhost:3000' });
  });


  before(function(done) {
    this.browser.visit('/', done);
  });

  it('should display a signup button', function(){
    var browser = this.browser;
    browser.assert.element('.signUp');
  });

  after(function(done) {
    this.server.close(done);
  });
});
