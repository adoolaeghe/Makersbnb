var express = require('express');
var bodyParser = require('body-parser');
var path = require('path');
var http = require('http');

var fs   = require('fs');
var EJS  = require('ejs');
var express = require('express');
var session = require('express-session');
var app = express();
var mongojs = require('mongojs');
var db = mongojs('makersBnB', ['adverts']);
var app = express();
var sess;

app.set('views', __dirname + '/app/views/');
app.set('view engine', 'ejs');
app.use(express.static(__dirname + '/app/js'));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended:false}));
app.use(session({secret: 'newsession'}));

app.set('port', process.env.PORT || 3000);

app.listen(3000, function() {
  console.log("Server started on Port 3000...");
});

app.get('/', function(req, res) {
  sess=req.session;
  db.users.find({email: "a@a"}, function(err, entries){
    if(err) {
      console.log(err);
    }
    console.log(entries);
  });

   db.adverts.find(function (err, docs) {
    if(err) {
      console.log(err);
    }
  console.log(docs);
    res.render('index', {
      adverts: docs
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
    var newUser = {
      username: req.body.username,
      email: req.body.email,
      password: req.body.password
    };

    db.users.findOne({email:req.body.email}, function(err, entry){
      if(err) {
        console.log(err);
      }
      console.log("Email already taken, please enter a unique email " + entry);
      // redirect
    });

    db.users.findOne({email:req.body.username}, function(err, entry){
      if(err) {
        console.log(err);
      }
      console.log("Username already taken, please enter a unique email " + entry);
      // redirect
    });

    db.users.insert(newUser, function(err, result){
      if(err){
        console.log(err);
      }
    });
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


app.post('/book', function (req, res) {
  // console.log(req.params);
  db.adverts.update({_id:mongojs.ObjectId(req.body.bookBtn)}, {$set: {booked:true}});
  res.redirect('/');
});

app.post('/new-advert', function(req, res) {
  // console.log(req.body.advertName);
  sess=req.session;
  var user;
  console.log("Adding advert for " + sess.email);
  db.users.findOne({email: sess.email}, function(err, foundUser){
    if(err){
      console.log(err);
    }
    user = foundUser;
    console.log(foundUser);
    console.log("User ID hexstring " + user._id.toHexString());
    var newAd = {
      userID : user._id.toHexString(),
      name: req.body.advertName,
      booked: false
    };
    db.adverts.insert(newAd, function(err, result){
      if(err){
        console.log(err);
      }
      console.log("Added advert to user " + user.email + result);
      res.redirect('/');
    });
  });
  // {_id: ObjectID.createFromHexString(userID)}

});


// //app is a callback function or an express application
// module.exports = app;
// if (!module.parent) {
//   http.createServer(app).listen(process.env.PORT, function(){
//     console.log("Server listening on port " + app.get('port'));
//   });
// }
