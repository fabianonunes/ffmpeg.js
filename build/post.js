  // #endregion
  return __ffmpegjs_return;
}

var __ffmpegjs_running = false;

function emit(type, data) {
  self.postMessage({"type": type, "data": data});
}

self.onmessage = function(e) {
  var msg = e.data;

  if (msg["type"] !== "run")
    return emit("error", "unknown command");

  if (__ffmpegjs_running)
    return emit("error", "already running");

  emit("run");
  __ffmpegjs_running = true;

  var opts = {};
  Object.keys(msg).forEach(function(key) {
    if (key !== "type") {
      opts[key] = msg[key]
    }
  });

  opts["stdin"] = function() {
    // NOTE(Kagami): Since it's not possible to pass stdin callback
    // via Web Worker message interface, set stdin to no-op. We are
    // messing with other handlers anyway.
  };

  opts["print"] = function(line) {
    emit("stdout", line);
  }

  opts["printErr"] = function(line) {
    line.split("\r").forEach(function(line) {
      emit("stderr", line);
    });
  }

  opts["onExit"] = function(code) {
    emit("exit", code);
  };

  opts["done"] = function (_result) {
    __ffmpegjs_running = false;
    emit("done");
  }

  __ffmpegjs(opts);
};

self.postMessage({"type": "ready"});
