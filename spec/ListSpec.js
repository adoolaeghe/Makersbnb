describe("List", function() {
  var list;
  var advert;
  beforeEach(function() {
    list = new List();
    advert = jasmine.createSpy("advert");
  });

  it("should add an advert", function() {
    list.add(advert);
    expect(list.adverts()).toContain(advert);
  });
});
