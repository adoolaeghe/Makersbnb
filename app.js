var express = require('express');
var bodyParser = require('body-parser');
var path = require('path');
var http = require('http');
var mongojs = require('mongojs');
var db = mongojs('makersBnB', ['adverts']);

var app = express();

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended:false}));
app.use(express.static(path.join(__dirname, 'public')));

app.listen(3000, function() {
  console.log("Server started on Port 3000...");
});

app.get('/', function(req, res) {
  console.log("hiya");
  db.adverts.find(function (err, docs) {
    if(err) {
      console.log(err);
    }
    console.log(docs);
      res.render('index', {});
  });
});



app.post('/new-advert', function(req, res) {
  // console.log(req.body.advertName);
  var newAd = {
    name: req.body.advertName,
    booked: false
  }

  db.adverts.insert(newAd, function(err, result){
    if(err){
      console.log(err);
    }
    res.redirect('/');
  })
});

//app is a callback function or an express application
// module.exports = app;
// if (!module.parent) {
//   http.createServer(app).listen(process.env.PORT, function(){
//     console.log("Server listening on port " + app.get('port'));
//   });
// }
