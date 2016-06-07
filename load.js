var load = function (file, callback) {
  var xhr = new XMLHttpRequest();
  xhr.open('GET', file, true);
  xhr.responseType = 'arraybuffer';
  xhr.onload = function() {
    var content = new Uint8Array(this.response);
    callback(content);
  }
  xhr.send();
}

define('load', [], function () {
    return load;
});
