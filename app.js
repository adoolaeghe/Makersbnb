var express = require('express');
var bodyParser = require('body-parser');
var path = require('path');
var http = require('http');

var app = express();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended:false}));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', function(req, res) {
  res.render('index',{});
});

// app.listen(3000, function() {
//   console.log("Server started on Port 3000...");
// });

//app is a callback function or an express application
module.exports = app;
if (!module.parent) {
  http.createServer(app).listen(process.env.PORT, function(){
    console.log("Server listening on port " + app.get('port'));
  });
}
