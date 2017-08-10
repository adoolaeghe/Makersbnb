var express = require('express');
var bodyParser = require('body-parser');
var path = require('path');
var http = require('http');
var methodOverride = require('method-override');

var fs   = require('fs');
var EJS  = require('ejs');
var express = require('express');
var session = require('express-session');
var app = express();
var mongojs = require('mongojs');
var db = mongojs('makersBnB', ['adverts']);
var app = express();
var sess;

app.set('views', __dirname + '/views/');
app.set('view engine', 'ejs');
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended:false}));
app.use(session({secret: 'newsession'}));
app.use(methodOverride('_method'));

app.set('port', process.env.PORT || 3000);
//
app.listen(3000, function() {
  console.log("Server started on Port 3000...");
});

app.get('/', function(req, res) {
  sess=req.session;
  var email = 'james';
  sess.email = email;
  if(sess.email) {
    console.log("You are logged in");
  }
  var message = ("Welcome" + (sess.email ? (", " +sess.email) : ", please log in."));
   db.adverts.find(function (err, docs) {
    if(err) {
      console.log(err);
    }
    console.log(docs);
      res.render('index', {
        adverts: docs,
        welcomeMessage: message
      });
    });
});

app.get('/users/new', function(req, res) {
  res.render('users/new');
});

app.post('/users/new', function(req, res) {
  var name = req.body.name;
  var username = req.body.username;
  var email = req.body.email;
  var password = req.body.password;
  var passwordConfirmation = req.body.passwordConfirmation;
  sess=req.session;
  sess.email = email;
  console.log("Signed up with email: " + sess.email);
  sess.username = username;
  if(sess.email) {
    // res.send(name); //enter name in the database
    res.redirect('/');
  }
  else {
    res.redirect('/user/new');
  }
});

app.get('/sessions/new', function(req, res) {
  res.render('sessions/new');
});

app.post('/sessions/new', function(req, res){
  console.log("Logged in with email:" + req.body.email);
  sess=req.session;
  sess.email=req.body.email;
  sess.password=req.body.password;
  if (sess.email) {
    if (sess.password) {
      // get user from database
      res.redirect('/');
    }
    else {
      res.redirect('/session/new');
    }
  }
  else {
    res.redirect('/user/new');
  }
});

app.delete('/sessions', function(req, res) {
  sess=req.session;
  sess.destroy(function(err) {
    if(err) {
      console.log(err);
    } else {
      console.log("You have logged out");
      res.redirect('/');
    }
  });
});


app.post('/book', function (req, res) {
  // console.log(req.params);
  db.adverts.update({_id:mongojs.ObjectId(req.body.bookBtn)}, {$set: {booked:true}});
  res.redirect('/');
});

app.get('/new-advert', function(req, res) {
  res.render('advert/new');
});

app.post('/new-advert', function(req, res) {
  // console.log(req.body.advertName);
  var newAd = {
    name: req.body.advertName,
    description: req.body.advertDescription,
    price: req.body.advertPrice,
    booked: false
  };

  db.adverts.insert(newAd, function(err, result){
    if(err){
      console.log(err);
    }
    res.redirect('/');
  });
});


//app is a callback function or an express application
// module.exports = app;
// if (!module.parent) {
//   http.createServer(app).listen(process.env.PORT, function(){
//     console.log("Server listening on port " + app.get('port'));
//   });
// }
