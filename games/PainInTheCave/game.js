
var Module;

if (typeof Module === 'undefined') Module = eval('(function() { try { return Module || {} } catch(e) { return {} } })()');

if (!Module.expectedDataFileDownloads) {
  Module.expectedDataFileDownloads = 0;
  Module.finishedDataFileDownloads = 0;
}
Module.TOTAL_MEMORY = 64000000
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
Module['FS_createPath']('/', 'data', true, true);
Module['FS_createPath']('/data', 'sound', true, true);
Module['FS_createPath']('/data', 'gfx', true, true);

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
 loadPackage({"files": [{"audio": 0, "start": 0, "crunched": 0, "end": 26, "filename": "/conf.lua"}, {"audio": 0, "start": 26, "crunched": 0, "end": 57352, "filename": "/main.lua"}, {"audio": 0, "start": 57352, "crunched": 0, "end": 58635, "filename": "/README.md"}, {"audio": 0, "start": 58635, "crunched": 0, "end": 64475, "filename": "/PainInTheCave.org"}, {"audio": 0, "start": 64475, "crunched": 0, "end": 67973, "filename": "/Postmortem.md~"}, {"audio": 0, "start": 67973, "crunched": 0, "end": 70238, "filename": "/Postmortem.md"}, {"audio": 1, "start": 70238, "crunched": 0, "end": 97583, "filename": "/data/sound/Death0.ogg"}, {"audio": 1, "start": 97583, "crunched": 0, "end": 122864, "filename": "/data/sound/Wilhelm.ogg"}, {"audio": 1, "start": 122864, "crunched": 0, "end": 1259240, "filename": "/data/sound/Krakatoa.ogg"}, {"audio": 0, "start": 1259240, "crunched": 0, "end": 1263434, "filename": "/data/gfx/Hunter-Walk-1.png"}, {"audio": 0, "start": 1263434, "crunched": 0, "end": 1267679, "filename": "/data/gfx/Scout-Walk-1.png"}, {"audio": 0, "start": 1267679, "crunched": 0, "end": 1272090, "filename": "/data/gfx/Bird-Fly-1.png"}, {"audio": 0, "start": 1272090, "crunched": 0, "end": 1275367, "filename": "/data/gfx/Skeleton.png"}, {"audio": 0, "start": 1275367, "crunched": 0, "end": 1282137, "filename": "/data/gfx/Wolf.png"}, {"audio": 0, "start": 1282137, "crunched": 0, "end": 1286358, "filename": "/data/gfx/Hunter.png"}, {"audio": 0, "start": 1286358, "crunched": 0, "end": 1301803, "filename": "/data/gfx/Bison-Walk-1.png"}, {"audio": 0, "start": 1301803, "crunched": 0, "end": 1303652, "filename": "/data/gfx/Plant.png"}, {"audio": 0, "start": 1303652, "crunched": 0, "end": 1307099, "filename": "/data/gfx/Gatherer-Walk-2.png"}, {"audio": 0, "start": 1307099, "crunched": 0, "end": 1311482, "filename": "/data/gfx/Bird.png"}, {"audio": 0, "start": 1311482, "crunched": 0, "end": 1326593, "filename": "/data/gfx/Bison.png"}, {"audio": 0, "start": 1326593, "crunched": 0, "end": 1342247, "filename": "/data/gfx/Bison-Idle-2.png"}, {"audio": 0, "start": 1342247, "crunched": 0, "end": 1931734, "filename": "/data/gfx/Background.jpg"}, {"audio": 0, "start": 1931734, "crunched": 0, "end": 1932407, "filename": "/data/gfx/Arrow.png"}, {"audio": 0, "start": 1932407, "crunched": 0, "end": 1936921, "filename": "/data/gfx/Hunter-Idle-1.png"}, {"audio": 0, "start": 1936921, "crunched": 0, "end": 1940851, "filename": "/data/gfx/Gatherer-Walk-1.png"}, {"audio": 0, "start": 1940851, "crunched": 0, "end": 1946307, "filename": "/data/gfx/Meat.png"}, {"audio": 0, "start": 1946307, "crunched": 0, "end": 1952742, "filename": "/data/gfx/Wolf-Idle-2.png"}, {"audio": 0, "start": 1952742, "crunched": 0, "end": 1956556, "filename": "/data/gfx/Carcass.png"}, {"audio": 0, "start": 1956556, "crunched": 0, "end": 1960326, "filename": "/data/gfx/Gatherer-Idle-2.png"}, {"audio": 0, "start": 1960326, "crunched": 0, "end": 2496874, "filename": "/data/gfx/Tutorial.jpg"}, {"audio": 0, "start": 2496874, "crunched": 0, "end": 2500402, "filename": "/data/gfx/Gatherer-Idle-1.png"}, {"audio": 0, "start": 2500402, "crunched": 0, "end": 3015350, "filename": "/data/gfx/Splash.jpg"}, {"audio": 0, "start": 3015350, "crunched": 0, "end": 3027725, "filename": "/data/gfx/Fire.png"}, {"audio": 0, "start": 3027725, "crunched": 0, "end": 3033528, "filename": "/data/gfx/Aura-1.png"}, {"audio": 0, "start": 3033528, "crunched": 0, "end": 3037933, "filename": "/data/gfx/Hunter-Walk-2.png"}, {"audio": 0, "start": 3037933, "crunched": 0, "end": 3041948, "filename": "/data/gfx/Hunter-Idle-2.png"}, {"audio": 0, "start": 3041948, "crunched": 0, "end": 3048534, "filename": "/data/gfx/Wolf-Walk-2.png"}, {"audio": 0, "start": 3048534, "crunched": 0, "end": 3064823, "filename": "/data/gfx/Food.png"}, {"audio": 0, "start": 3064823, "crunched": 0, "end": 3070826, "filename": "/data/gfx/Aura-2.png"}, {"audio": 0, "start": 3070826, "crunched": 0, "end": 3084992, "filename": "/data/gfx/Bison-Idle-1.png"}, {"audio": 0, "start": 3084992, "crunched": 0, "end": 3089158, "filename": "/data/gfx/Scout-Idle-2.png"}, {"audio": 0, "start": 3089158, "crunched": 0, "end": 3097530, "filename": "/data/gfx/Cereal.png"}, {"audio": 0, "start": 3097530, "crunched": 0, "end": 3104300, "filename": "/data/gfx/Wolf-Walk-1.png"}, {"audio": 0, "start": 3104300, "crunched": 0, "end": 3119506, "filename": "/data/gfx/Bison-Walk-2.png"}, {"audio": 0, "start": 3119506, "crunched": 0, "end": 3132168, "filename": "/data/gfx/Fire-2.png"}, {"audio": 0, "start": 3132168, "crunched": 0, "end": 3135058, "filename": "/data/gfx/Wood.png"}, {"audio": 0, "start": 3135058, "crunched": 0, "end": 3138723, "filename": "/data/gfx/Scout-Walk-2.png"}, {"audio": 0, "start": 3138723, "crunched": 0, "end": 3142276, "filename": "/data/gfx/Scout-Idle-1.png"}, {"audio": 0, "start": 3142276, "crunched": 0, "end": 3145873, "filename": "/data/gfx/Gatherer.png"}, {"audio": 0, "start": 3145873, "crunched": 0, "end": 3152094, "filename": "/data/gfx/Wolf-Idle-1.png"}, {"audio": 0, "start": 3152094, "crunched": 0, "end": 3155875, "filename": "/data/gfx/Scout.png"}, {"audio": 0, "start": 3155875, "crunched": 0, "end": 3160384, "filename": "/data/gfx/Bird-Fly-2.png"}], "remote_package_size": 3160384, "package_uuid": "5c5ab1f4-f172-4e53-bf37-98ac8a2dc122"});

})();
