var express = require('express');
var bodyParser = require('body-parser');
var path = require('path');
var http = require('http');
var fs   = require('fs');
var EJS  = require('ejs');
var express = require('express');
var session = require('express-session');
var app = express();

// app.engine('html', EJS.renderFile);

var app = express();
var sess;

app.set('views', __dirname + '/app/views/');
app.set('view engine', 'ejs');
app.use(express.static(__dirname + '/app/js'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended:false}));
app.use(session({secret: 'newsession'}));

app.set('port', process.env.PORT || 3000);

app.get('/', function(req, res) {
  sess=req.session;
  var email = 'james';
  sess.email = email;
  console.log(sess);
  res.render('index');
});

app.get('/users/new', function(req, res) {
  res.render('users/new');
});

app.post('/users/new', function(req, res) {
  var name = req.body.name;
  var username = req.body.username;
  var email = req.body.username;
  var password = req.body.password;
  var passwordConfirmation = req.body.passwordConfirmation;
  sess=req.session;
  sess.email = email;
  console.log(sess.email);
  sess.username = username;
  if(sess.email) {
    // res.send(name); //enter name in the database
    res.redirect('/');
  }
  else {
    res.redirect('/user/new');
  }
});

app.post('/session/new', function(req, res){
  sess=req.session;
  sess.email=req.body.email;
  sess.password=req.body.password;
  if (sess.email) {
    if (sess.password) {
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

app.listen(3000, function() {
  console.log("Server started on Port 3000...");
});

//app is a callback function or an express application
// module.exports = app;
// if (!module.parent) {
//   http.createServer(app).listen(process.env.PORT, function(){
//     console.log("Server listening on port " + app.get('port'));
//   });
// }
