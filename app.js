var express = require('express');
var bodyParser = require('body-parser');
var path = require('path');
var http = require('http');
var fs   = require('fs');
var EJS  = require('ejs');

// app.engine('html', EJS.renderFile);

var app = express();

app.set('views', __dirname + '/app/views/');
app.set('view engine', 'ejs');
app.use(express.static(__dirname + '/app/js'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended:false}));
//app.use(express.static(path.join(__dirname, 'app')));
app.set('port', process.env.PORT || 3000);

app.get('/', function(req, res) {
  //res.sendFile(path.join(__dirname+'/app/views/index.html'));
  res.render('index');
});

app.get('/users/new', function(req, res) {
  res.render('users/new');
//  res.sendFile(path.join(__dirname+'/app/views/users/new.html'));
});

app.post('/users/new', function(req, res) {
  var name = req.body.name;
  var username = req.body.username;
  var email = req.body.username;
  var password = req.body.password;
  var passwordConfirmation = req.body.passwordConfirmation;
  console.log(name);
  res.send(name);
  //res.sendFile(path.join(__dirname+'/app/views/users/new.html'));
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
