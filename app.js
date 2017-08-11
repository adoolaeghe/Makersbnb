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
app.use(express.static(path.join(__dirname + '/public')));
app.use(express.static(path.join(__dirname + '/lib')));
app.use(session({secret: 'newsession'}));
app.use(methodOverride('_method'));

app.set('port', process.env.PORT || 3000);
//
app.listen(3000, function() {
  console.log("Server started on Port 3000...");
});

app.get('/', function(req, res) {
  sess=req.session;

  if(sess.email) {
    console.log("You are logged in");
  }
  var message = ((sess.email ? ("Welcome, " +sess.username) : "Please log in or sign up"));
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
  sess=req.session;
  console.log("Signed up with email: " + sess.email);
  if(req.body.password == req.body.passwordComfirmation) {
    var newUser = {
      name: req.body.name,
      username: req.body.username,
      email: req.body.email,
      password: req.body.password,
    };

    db.users.insert(newUser, function(err, result){
      if(err){
        console.log(err);
      }
      sess.email = req.body.email;
      sess.username = req.body.username;
      res.redirect('/');
    });
  }
});

app.get('/sessions/new', function(req, res) {
  res.render('sessions/new');
});

app.post('/sessions/new', function(req, res){
  console.log("Logged in with email:" + req.body.email);
  sess=req.session;
  db.users.findOne({email: req.body.email}, function(err, foundUser){
    console.log(foundUser);
    if(foundUser == null){
      res.redirect('/users/new');
    }
    else if (err){
      console.log(err);
      res.redirect('/users/new');
    }
    else if(req.body.password === foundUser.password){
      sess.email=req.body.email;
      sess.password=req.body.password;
      res.redirect('/');
    }
    else {
      res.redirect('/sessions/new');
    }
  });
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
  db.adverts.update({_id:mongojs.ObjectId(req.body.bookBtn)}, {$set: {booked:true}});
  res.redirect('/');
});

app.get('/new-advert', function(req, res) {
  res.render('advert/new');
});

app.post('/new-advert', function(req, res) {
  sess=req.session;
  var user;
  console.log("Adding advert for" + sess.email);
  db.users.findOne({email: sess.email}, function(err, foundUser) {

    if(err){
      console.log(err);
    }
  user = foundUser;
  console.log(foundUser);
  console.log("User ID hexstring" + user._id.toHexString());

  var newAd = {
    userId : user._id.toHexString(),
    name: req.body.advertName,
    description: req.body.advertDescription,
    booked: false
  };

  db.adverts.insert(newAd, function(err, result){
      if(err){
        console.log(err);
      }
      console.log("Added advert to user"+ user.email + result);
      res.redirect('/');
    });
  });
});


//
// module.exports = app;
// if (!module.parent) {
//   http.createServer(app).listen(process.env.PORT, function(){
//     console.log("Server listening on port " + app.get('port'));
//   });
// }
