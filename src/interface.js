$(document).ready(function(){
  var list = new List();

  function displayAdverts() {
    var string = "";
    var index = 0;
    list.adverts().forEach(function(advert){
      string += "<li class='.advert1'>" + advert.name() + " - Booked: " + advert.isBooked() + "</li>";
      index += 1;
    });
    $(".advertList").html(string);
  }

  $(".addAdvert").click(function() {
    if (list.adverts().length >= 1) {
      return;
    }
    var name = $(".advertName").val();
    var advert = new Advert(name);
    list.add(advert);
    displayAdverts();
  });

  $(".bookAdvert").click(function() {
    list.adverts()[0].book();
    displayAdverts();
  });
});
