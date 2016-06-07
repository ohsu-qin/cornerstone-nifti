requirejs.config({
    baseUrl: ".",
    paths: {
      "lodash": "./node_modules/lodash/lodash",
      "cornerstone": "./node_modules/cornerstone/dist/cornerstone",
      "niftiParser": "./niftiParser",
      "ndarray": "./ndarray",
      "load": "./load",
      "parse": "./parse",
      "display": "./display",
      "run": "./run"
    },
    shim: {
      "lodash": {
        exports: '_'
      }
    }
});
