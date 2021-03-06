var express = require('express');
var path = require('path');
var favicon = require('serve-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');


// Routes
var index = require('./routes/index');
var friends = require('./routes/friends');
var login = require('./routes/login');
var users = require('./routes/users');
var requests = require('./routes/requests');
var games = require('./routes/games');
var search = require('./routes/search');

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'app'));
app.set('view engine', 'jade');

// uncomment after placing your favicon in /public
//app.use(favicon(__dirname + '/public/favicon.ico'));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'app')));

app.use('/api/friends', friends);
app.use('/api/login', login);
app.use('/api/users', users);
app.use('/api/requests', requests);
app.use('/api/games', games);
app.use('/api/search', search);

app.use('*', index);


// catch 404 and forward to error handler
app.use(function(req, res, next) {
    var err = new Error('Not Found');
    err.status = 404;
    next(err);
});

// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
    app.use(function(err, req, res, next) {
        res.status(err.status || 500);
        res.send({
            message: err.message
        });
    });
}

// production error handler
// no stacktraces leaked to user
app.use(function(err, req, res, next) {
    res.status(err.status || 500);
    res.send({
        message : err.message
    });
});


module.exports = app;

//process.env.PORT || allows for deployed app port connection
var server = app.listen(process.env.PORT || 8888, function () {

  var host = server.address().address
  var port = server.address().port

  console.log('Example app listening at http://%s:%s', host, port)

})
