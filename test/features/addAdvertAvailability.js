process.env.NODE_ENV = 'test';
var app = require('../../app.js');
var Browser = require('zombie');
var assert = require('assert');
var http = require('http');


describe("entering availability for new advert", function(){

  before(function() {
    this.server = http.createServer(app).listen(3000);
    this.browser = new Browser({ site: 'http://localhost:3000' });
  });

  beforeEach(function(done) {
    this.browser.visit('/new-advert', done);
  });

  it('should show the available dates as per that entered in the new advert form', function(done){
    var browser = this.browser;
    var startDate = "01/01/2020";
    var startDateOutput = new Date(startDate).toDateString();
    var endDate = "07/07/2017";
    var endDateOutput = new Date(endDate).toDateString();

    browser.fill('.advertStartDate', startDate);
    browser.fill('.advertEndDate', endDate);

    browser.pressButton('.submitAdBtn', function(error){
      if (error) return done(error);
      assert.equal(browser.text('.advertList').indexOf(startDateOutput) !== -1, true);
      assert.equal(browser.text('.advertList').indexOf(endDateOutput) !== -1, true);
      done();
    });
  });


  after(function(done) {
    this.server.close(done);
  });
});
