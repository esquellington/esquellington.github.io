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
Module['FS_createPath']('/data', 'yaycandies', true, true);
Module['FS_createPath']('/data/yaycandies', 'size1', true, true);
Module['FS_createPath']('/data', 'sfx', true, true);

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
 loadPackage({"files": [{"audio": 0, "start": 0, "crunched": 0, "end": 26, "filename": "/conf.lua"}, {"audio": 0, "start": 26, "crunched": 0, "end": 28096, "filename": "/main.lua"}, {"audio": 0, "start": 28096, "crunched": 0, "end": 29096, "filename": "/.emacs.desktop"}, {"audio": 0, "start": 29096, "crunched": 0, "end": 29182, "filename": "/test.lua"}, {"audio": 0, "start": 29182, "crunched": 0, "end": 57455, "filename": "/main.lua~"}, {"audio": 1, "start": 57455, "crunched": 0, "end": 252226, "filename": "/data/CarnivalRides-Long-Mono-T18.ogg"}, {"audio": 1, "start": 252226, "crunched": 0, "end": 384169, "filename": "/data/CarnivalRides-Long-Mono-T12.ogg"}, {"audio": 1, "start": 384169, "crunched": 0, "end": 615563, "filename": "/data/CarnivalRides-Long-Mono-T24.ogg"}, {"audio": 0, "start": 615563, "crunched": 0, "end": 617202, "filename": "/data/OldManD0.png"}, {"audio": 0, "start": 617202, "crunched": 0, "end": 624657, "filename": "/data/king_0.png"}, {"audio": 1, "start": 624657, "crunched": 0, "end": 788497, "filename": "/data/CarnivalRides-Long-Mono-T15.ogg"}, {"audio": 0, "start": 788497, "crunched": 0, "end": 948391, "filename": "/data/bg_grass.jpg"}, {"audio": 1, "start": 948391, "crunched": 0, "end": 1414930, "filename": "/data/carnivalrides.ogg"}, {"audio": 0, "start": 1414930, "crunched": 0, "end": 1750923, "filename": "/data/NCFOM.png"}, {"audio": 1, "start": 1750923, "crunched": 0, "end": 1976690, "filename": "/data/CarnivalRides-Long-Mono-T21.ogg"}, {"audio": 0, "start": 1976690, "crunched": 0, "end": 1984618, "filename": "/data/bomb.png"}, {"audio": 0, "start": 1984618, "crunched": 0, "end": 1985036, "filename": "/data/yaycandies/size1/bean_shadow.png"}, {"audio": 0, "start": 1985036, "crunched": 0, "end": 1986488, "filename": "/data/yaycandies/size1/wrappedsolid_green.png"}, {"audio": 0, "start": 1986488, "crunched": 0, "end": 1987997, "filename": "/data/yaycandies/size1/bean_red.png"}, {"audio": 0, "start": 1987997, "crunched": 0, "end": 1989484, "filename": "/data/yaycandies/size1/bean_orange.png"}, {"audio": 0, "start": 1989484, "crunched": 0, "end": 1993317, "filename": "/data/yaycandies/size1/swirl_orange.png"}, {"audio": 0, "start": 1993317, "crunched": 0, "end": 1997033, "filename": "/data/yaycandies/size1/swirl_pink.png"}, {"audio": 0, "start": 1997033, "crunched": 0, "end": 1998474, "filename": "/data/yaycandies/size1/wrappedsolid_purple.png"}, {"audio": 0, "start": 1998474, "crunched": 0, "end": 2002195, "filename": "/data/yaycandies/size1/swirl_purple.png"}, {"audio": 0, "start": 2002195, "crunched": 0, "end": 2003593, "filename": "/data/yaycandies/size1/bean_white.png"}, {"audio": 0, "start": 2003593, "crunched": 0, "end": 2005026, "filename": "/data/yaycandies/size1/wrappedsolid_teal.png"}, {"audio": 0, "start": 2005026, "crunched": 0, "end": 2005439, "filename": "/data/yaycandies/size1/wrappedsolid_shadow.png"}, {"audio": 0, "start": 2005439, "crunched": 0, "end": 2006013, "filename": "/data/yaycandies/size1/swirl_shadow.png"}, {"audio": 0, "start": 2006013, "crunched": 0, "end": 2009871, "filename": "/data/yaycandies/size1/swirl_green.png"}, {"audio": 0, "start": 2009871, "crunched": 0, "end": 2013746, "filename": "/data/yaycandies/size1/swirl_red.png"}, {"audio": 0, "start": 2013746, "crunched": 0, "end": 2017513, "filename": "/data/yaycandies/size1/swirl_blue.png"}, {"audio": 0, "start": 2017513, "crunched": 0, "end": 2018954, "filename": "/data/yaycandies/size1/bean_yellow.png"}, {"audio": 0, "start": 2018954, "crunched": 0, "end": 2020333, "filename": "/data/yaycandies/size1/wrappedsolid_orange.png"}, {"audio": 0, "start": 2020333, "crunched": 0, "end": 2021906, "filename": "/data/yaycandies/size1/bean_green.png"}, {"audio": 0, "start": 2021906, "crunched": 0, "end": 2023325, "filename": "/data/yaycandies/size1/wrappedsolid_red.png"}, {"audio": 0, "start": 2023325, "crunched": 0, "end": 2024897, "filename": "/data/yaycandies/size1/bean_blue.png"}, {"audio": 0, "start": 2024897, "crunched": 0, "end": 2026408, "filename": "/data/yaycandies/size1/bean_pink.png"}, {"audio": 0, "start": 2026408, "crunched": 0, "end": 2027677, "filename": "/data/yaycandies/size1/wrappedsolid_yellow.png"}, {"audio": 0, "start": 2027677, "crunched": 0, "end": 2029237, "filename": "/data/yaycandies/size1/bean_purple.png"}, {"audio": 1, "start": 2029237, "crunched": 0, "end": 2039425, "filename": "/data/sfx/Pickup2.wav"}, {"audio": 1, "start": 2039425, "crunched": 0, "end": 2066770, "filename": "/data/sfx/Death0.ogg"}, {"audio": 1, "start": 2066770, "crunched": 0, "end": 2116541, "filename": "/data/sfx/EvilLaughter1.ogg"}, {"audio": 1, "start": 2116541, "crunched": 0, "end": 2126729, "filename": "/data/sfx/Pickup1.wav"}, {"audio": 1, "start": 2126729, "crunched": 0, "end": 2251047, "filename": "/data/sfx/Bomb2.wav"}, {"audio": 0, "start": 2251047, "crunched": 0, "end": 2251147, "filename": "/data/sfx/Pickup0.bfxrsound"}, {"audio": 0, "start": 2251147, "crunched": 0, "end": 2251294, "filename": "/data/sfx/Bomb1.bfxrsound"}, {"audio": 0, "start": 2251294, "crunched": 0, "end": 2251385, "filename": "/data/sfx/Throw1.bfxrsound"}, {"audio": 1, "start": 2251385, "crunched": 0, "end": 2293735, "filename": "/data/sfx/Throw1.wav"}, {"audio": 1, "start": 2293735, "crunched": 0, "end": 2339301, "filename": "/data/sfx/Bomb1.wav"}, {"audio": 1, "start": 2339301, "crunched": 0, "end": 2349489, "filename": "/data/sfx/Pickup0.wav"}, {"audio": 0, "start": 2349489, "crunched": 0, "end": 2349636, "filename": "/data/sfx/Bomb2.bfxrsound"}, {"audio": 0, "start": 2349636, "crunched": 0, "end": 2349797, "filename": "/data/sfx/Throw0.bfxrsound"}, {"audio": 0, "start": 2349797, "crunched": 0, "end": 2350024, "filename": "/data/sfx/Throw3.bfxrsound"}, {"audio": 1, "start": 2350024, "crunched": 0, "end": 2408790, "filename": "/data/sfx/EvilLaughter0.mp3"}, {"audio": 1, "start": 2408790, "crunched": 0, "end": 2444974, "filename": "/data/sfx/Throw3.wav"}, {"audio": 1, "start": 2444974, "crunched": 0, "end": 2474156, "filename": "/data/sfx/Throw0.wav"}, {"audio": 0, "start": 2474156, "crunched": 0, "end": 2474357, "filename": "/data/sfx/Throw2.bfxrsound"}, {"audio": 0, "start": 2474357, "crunched": 0, "end": 2474580, "filename": "/data/sfx/Raro.bfxrsound"}, {"audio": 0, "start": 2474580, "crunched": 0, "end": 2474796, "filename": "/data/sfx/Submarine.bfxrsound"}, {"audio": 1, "start": 2474796, "crunched": 0, "end": 2514608, "filename": "/data/sfx/Throw2.wav"}, {"audio": 0, "start": 2514608, "crunched": 0, "end": 2514708, "filename": "/data/sfx/Bomb0.bfxrsound"}, {"audio": 1, "start": 2514708, "crunched": 0, "end": 2563952, "filename": "/data/sfx/Bomb0.wav"}], "remote_package_size": 2563952, "package_uuid": "75081be1-e5f7-4ab0-b020-c90e20071e71"});

})();
