$(document).ready(function(){
  var list = new List();

  function displayAdverts() {
    var string = "";
    var index = 0;
    list.adverts().forEach(function(advert){
      string += "<li class='advert1'><span class='advert1Name'>" + advert.name() + "</span> - Booked: <span class='advert1Booked'>" + advert.isBooked() + "</span></li>";
      index += 1;
    });
    $(".advertList").html(string);
  }

  $(".addAdvert").click(function() {
    // if (list.adverts().length >= 1) {
    //   return;
    // }

    // var name = $(".advertName").val();
    // var json = JSON.stringify({name: $(".advertName").val()})
    // $post('http://localhost:3000/new-advert', json);

    // var advert = new Advert(name);
    // list.add(advert);
    // displayAdverts();
  });

  $(".bookAdvert").click(function() {
    list.adverts()[0].book();
    displayAdverts();
  });
});
