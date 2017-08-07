$(document).ready(function(){
  var list = new List();

  function displayAdverts() {
    var string = "";
    list.adverts().forEach(function(advert){
      string += "<li>" + advert.name() + " - Booked: " + advert.isBooked() + "</li>";
    });
    $(".advert-list").html(string);
  }

  $(".add-advert").click(function() {
    if (list.adverts().length >= 1) {
      return;
    }
    var name = $(".advert-name").val();
    var advert = new Advert(name);
    list.add(advert);
    displayAdverts();
  });

  $(".book").click(function() {
    list.adverts()[0].book();
    displayAdverts();
  });
});
