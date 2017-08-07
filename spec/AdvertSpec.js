describe("Advert", function() {
  var advert;
  var name = 'Cosy flat';
  beforeEach(function() {
    advert = new Advert(name);
  });

  it("should have a name", function() {
    expect(advert.name()).toEqual(name);
  });
});
