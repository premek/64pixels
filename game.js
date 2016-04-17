
var Module;

if (typeof Module === 'undefined') Module = eval('(function() { try { return Module || {} } catch(e) { return {} } })()');

if (!Module.expectedDataFileDownloads) {
  Module.expectedDataFileDownloads = 0;
  Module.finishedDataFileDownloads = 0;
}
Module.expectedDataFileDownloads++;
(function() {
 var loadPackage = function(metadata) {

    var PACKAGE_PATH;
    if (typeof window === 'object') {
      PACKAGE_PATH = window['encodeURIComponent'](window.location.pathname.toString().substring(0, window.location.pathname.toString().lastIndexOf('/')) + '/');
    } else if (typeof location !== 'undefined') {
      // worker
      PACKAGE_PATH = encodeURIComponent(location.pathname.toString().substring(0, location.pathname.toString().lastIndexOf('/')) + '/');
    } else {
      throw 'using preloaded data can only be done on a web page or in a web worker';
    }
    var PACKAGE_NAME = 'game.data';
    var REMOTE_PACKAGE_BASE = 'game.data';
    if (typeof Module['locateFilePackage'] === 'function' && !Module['locateFile']) {
      Module['locateFile'] = Module['locateFilePackage'];
      Module.printErr('warning: you defined Module.locateFilePackage, that has been renamed to Module.locateFile (using your locateFilePackage for now)');
    }
    var REMOTE_PACKAGE_NAME = typeof Module['locateFile'] === 'function' ?
                              Module['locateFile'](REMOTE_PACKAGE_BASE) :
                              ((Module['filePackagePrefixURL'] || '') + REMOTE_PACKAGE_BASE);
  
    var REMOTE_PACKAGE_SIZE = metadata.remote_package_size;
    var PACKAGE_UUID = metadata.package_uuid;
  
    function fetchRemotePackage(packageName, packageSize, callback, errback) {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', packageName, true);
      xhr.responseType = 'arraybuffer';
      xhr.onprogress = function(event) {
        var url = packageName;
        var size = packageSize;
        if (event.total) size = event.total;
        if (event.loaded) {
          if (!xhr.addedTotal) {
            xhr.addedTotal = true;
            if (!Module.dataFileDownloads) Module.dataFileDownloads = {};
            Module.dataFileDownloads[url] = {
              loaded: event.loaded,
              total: size
            };
          } else {
            Module.dataFileDownloads[url].loaded = event.loaded;
          }
          var total = 0;
          var loaded = 0;
          var num = 0;
          for (var download in Module.dataFileDownloads) {
          var data = Module.dataFileDownloads[download];
            total += data.total;
            loaded += data.loaded;
            num++;
          }
          total = Math.ceil(total * Module.expectedDataFileDownloads/num);
          if (Module['setStatus']) Module['setStatus']('Downloading data... (' + loaded + '/' + total + ')');
        } else if (!Module.dataFileDownloads) {
          if (Module['setStatus']) Module['setStatus']('Downloading data...');
        }
      };
      xhr.onload = function(event) {
        var packageData = xhr.response;
        callback(packageData);
      };
      xhr.send(null);
    };

    function handleError(error) {
      console.error('package error:', error);
    };
  
      var fetched = null, fetchedCallback = null;
      fetchRemotePackage(REMOTE_PACKAGE_NAME, REMOTE_PACKAGE_SIZE, function(data) {
        if (fetchedCallback) {
          fetchedCallback(data);
          fetchedCallback = null;
        } else {
          fetched = data;
        }
      }, handleError);
    
  function runWithFS() {

    function assert(check, msg) {
      if (!check) throw msg + new Error().stack;
    }
Module['FS_createPath']('/', 'font', true, true);
Module['FS_createPath']('/', 'img', true, true);
Module['FS_createPath']('/', 'lib', true, true);
Module['FS_createPath']('/lib', 'hump', true, true);
Module['FS_createPath']('/', 'music', true, true);
Module['FS_createPath']('/', 'sfx', true, true);

    function DataRequest(start, end, crunched, audio) {
      this.start = start;
      this.end = end;
      this.crunched = crunched;
      this.audio = audio;
    }
    DataRequest.prototype = {
      requests: {},
      open: function(mode, name) {
        this.name = name;
        this.requests[name] = this;
        Module['addRunDependency']('fp ' + this.name);
      },
      send: function() {},
      onload: function() {
        var byteArray = this.byteArray.subarray(this.start, this.end);

          this.finish(byteArray);

      },
      finish: function(byteArray) {
        var that = this;

        Module['FS_createDataFile'](this.name, null, byteArray, true, true, true); // canOwn this data in the filesystem, it is a slide into the heap that will never change
        Module['removeRunDependency']('fp ' + that.name);

        this.requests[this.name] = null;
      },
    };

        var files = metadata.files;
        for (i = 0; i < files.length; ++i) {
          new DataRequest(files[i].start, files[i].end, files[i].crunched, files[i].audio).open('GET', files[i].filename);
        }

  
    function processPackageData(arrayBuffer) {
      Module.finishedDataFileDownloads++;
      assert(arrayBuffer, 'Loading data file failed.');
      assert(arrayBuffer instanceof ArrayBuffer, 'bad input to processPackageData');
      var byteArray = new Uint8Array(arrayBuffer);
      var curr;
      
        // copy the entire loaded file into a spot in the heap. Files will refer to slices in that. They cannot be freed though
        // (we may be allocating before malloc is ready, during startup).
        if (Module['SPLIT_MEMORY']) Module.printErr('warning: you should run the file packager with --no-heap-copy when SPLIT_MEMORY is used, otherwise copying into the heap may fail due to the splitting');
        var ptr = Module['getMemory'](byteArray.length);
        Module['HEAPU8'].set(byteArray, ptr);
        DataRequest.prototype.byteArray = Module['HEAPU8'].subarray(ptr, ptr+byteArray.length);
  
          var files = metadata.files;
          for (i = 0; i < files.length; ++i) {
            DataRequest.prototype.requests[files[i].filename].onload();
          }
              Module['removeRunDependency']('datafile_game.data');

    };
    Module['addRunDependency']('datafile_game.data');
  
    if (!Module.preloadResults) Module.preloadResults = {};
  
      Module.preloadResults[PACKAGE_NAME] = {fromCache: false};
      if (fetched) {
        processPackageData(fetched);
        fetched = null;
      } else {
        fetchedCallback = processPackageData;
      }
    
  }
  if (Module['calledRun']) {
    runWithFS();
  } else {
    if (!Module['preRun']) Module['preRun'] = [];
    Module["preRun"].push(runWithFS); // FS is not initialized yet, wait for it
  }

 }
 loadPackage({"files": [{"audio": 0, "start": 0, "crunched": 0, "end": 576, "filename": "/conf.lua"}, {"audio": 0, "start": 576, "crunched": 0, "end": 11582, "filename": "/main.lua"}, {"audio": 0, "start": 11582, "crunched": 0, "end": 31546, "filename": "/font/tom-thumb.bdf"}, {"audio": 0, "start": 31546, "crunched": 0, "end": 32669, "filename": "/img/bg1.png"}, {"audio": 0, "start": 32669, "crunched": 0, "end": 33633, "filename": "/img/car.png"}, {"audio": 0, "start": 33633, "crunched": 0, "end": 34681, "filename": "/img/fuel.png"}, {"audio": 0, "start": 34681, "crunched": 0, "end": 35744, "filename": "/img/road.png"}, {"audio": 0, "start": 35744, "crunched": 0, "end": 36741, "filename": "/img/sign.png"}, {"audio": 0, "start": 36741, "crunched": 0, "end": 37759, "filename": "/img/speed.png"}, {"audio": 0, "start": 37759, "crunched": 0, "end": 38921, "filename": "/img/tree.png"}, {"audio": 0, "start": 38921, "crunched": 0, "end": 41140, "filename": "/lib/hump/README.md"}, {"audio": 0, "start": 41140, "crunched": 0, "end": 46485, "filename": "/lib/hump/camera.lua"}, {"audio": 0, "start": 46485, "crunched": 0, "end": 49509, "filename": "/lib/hump/class.lua"}, {"audio": 0, "start": 49509, "crunched": 0, "end": 53043, "filename": "/lib/hump/gamestate.lua"}, {"audio": 0, "start": 53043, "crunched": 0, "end": 55798, "filename": "/lib/hump/signal.lua"}, {"audio": 0, "start": 55798, "crunched": 0, "end": 62153, "filename": "/lib/hump/timer.lua"}, {"audio": 0, "start": 62153, "crunched": 0, "end": 65713, "filename": "/lib/hump/vector-light.lua"}, {"audio": 0, "start": 65713, "crunched": 0, "end": 71032, "filename": "/lib/hump/vector.lua"}, {"audio": 1, "start": 71032, "crunched": 0, "end": 10458479, "filename": "/music/i think i get it.mp3"}, {"audio": 1, "start": 10458479, "crunched": 0, "end": 16213911, "filename": "/music/think of me think of us.mp3"}, {"audio": 1, "start": 16213911, "crunched": 0, "end": 16843247, "filename": "/sfx/cardooropenclose4.wav"}, {"audio": 1, "start": 16843247, "crunched": 0, "end": 16875119, "filename": "/sfx/going.wav"}, {"audio": 1, "start": 16875119, "crunched": 0, "end": 16911898, "filename": "/sfx/idle.mp3"}, {"audio": 1, "start": 16911898, "crunched": 0, "end": 17322742, "filename": "/sfx/radiofm.wav"}, {"audio": 1, "start": 17322742, "crunched": 0, "end": 17338205, "filename": "/sfx/speeddown.mp3"}, {"audio": 1, "start": 17338205, "crunched": 0, "end": 17728201, "filename": "/sfx/speedup.wav"}, {"audio": 1, "start": 17728201, "crunched": 0, "end": 17744918, "filename": "/sfx/start.mp3"}, {"audio": 1, "start": 17744918, "crunched": 0, "end": 17754112, "filename": "/sfx/stop.mp3"}], "remote_package_size": 17754112, "package_uuid": "f5e260be-0c16-4e68-9c16-9837a390a83d"});

})();
