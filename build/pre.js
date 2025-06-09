function __ffmpegjs(__ffmpegjs_opts = {}) {
  var Module = {};

  function __ffmpegjs_toU8(data) {
    if (Array.isArray(data) || data instanceof ArrayBuffer) {
      data = new Uint8Array(data);
    } else if (!data) {
      // `null` for empty files.
      data = new Uint8Array(0);
    } else if (!(data instanceof Uint8Array)) {
      // Avoid unnecessary copying.
      data = new Uint8Array(data.buffer || []);
    }
    return data;
  }

  Object.keys(__ffmpegjs_opts).forEach(function(key) {
    if (key != "mounts" && key != "MEMFS") {
      Module[key] = __ffmpegjs_opts[key];
    }
  });

  Module["preRun"] = function() {
    __ffmpegjs_opts["mounts"]?.forEach(function(mount) {
      var fs = FS.filesystems[mount["type"]];
      if (!fs)
        throw new Error("Bad mount type");

      var mountpoint = mount["mountpoint"];
      // NOTE(Kagami): Subdirs are not allowed in the paths to simplify
      // things and avoid ".." escapes.
      if (!mountpoint.match(/^\/[^\/]+$/) ||
          mountpoint === "/." ||
          mountpoint === "/.." ||
          mountpoint === "/tmp" ||
          mountpoint === "/home" ||
          mountpoint === "/dev" ||
          mountpoint === "/work") {
        throw new Error("Bad mount point");
      }
      FS.mkdir(mountpoint);
      FS.mount(fs, mount["opts"], mountpoint);
    });

    FS.mkdir("/work");
    FS.chdir("/work");

    FS.registerDevice(FS.makedev(14, 3), {
      write: (stream, buffer, offset, length, pos) => {
        const chunk = buffer.slice(offset, offset + length);
        self.postMessage({
          type: "output",
          data: {
            "chunk": chunk,
            "size": length,
          },
        }, [chunk.buffer]);
        return length;
      },
    });
    FS.mkdev('/dev/output', FS.makedev(14, 3));

    __ffmpegjs_opts["MEMFS"]?.forEach(file => {
      const { name, data } = file;

      if (name.match(/\//))
        throw new Error("Bad file name");

      const fd = FS.open(name, "w+");
      const contents = __ffmpegjs_toU8(data);
      FS.write(fd, contents, 0, contents.length);
      FS.close(fd);
    });

    __ffmpegjs_opts["LAZYFS"]?.forEach(file =>{
      const { name, data } = file;

      if (name.match(/\//))
        throw new Error("Bad file name");

      const ref = FS.createLazyFile('/work', name, data, true, true);
      ref.stream_ops.close = function (stream) {
        FS.truncate(stream.path, 0);
      };
    });
  };

  Module["postRun"] = function() {
    Module["done"]()
  };
  // #region
