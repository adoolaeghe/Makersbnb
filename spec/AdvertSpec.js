describe("Advert", function() {
  var advert;
  var name = 'Cosy flat';
  beforeEach(function() {
    advert = new Advert(name);
  });

  it("should have a name", function() {
    expect(advert.name()).toEqual(name);
  });

  it("should not be booked by default", function(){
    expect(advert.isBooked()).toBeFalsy();
  });

  it("can be booked", function(){
    advert.book();
    expect(advert.isBooked()).toBeTruthy();
  });
});
