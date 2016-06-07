var exec = require('child_process').exec;
var cmd = './node_modules/http-server/bin/http-server -o';

exec(cmd, __dirname);
