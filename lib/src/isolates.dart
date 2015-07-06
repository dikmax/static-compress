part of static_compress;

class Task {
  SOFile file;
  AbstractMetadataContainer metadataContainer;

  Task(this.file, this.metadataContainer);
}

class Log {
  String message;
  Level logLevel;

  Log(this.message, [this.logLevel = Level.INFO]);
}

class TasksPool {
  Queue<Task> queue;
  List<Isolate> running;
  Watcher watcher;
  int runningCount;
  int maxThreads;

  StreamController streamController;

  TasksPool(this.watcher, [this.maxThreads = 4]) {
    queue = new Queue();
    running = [];
    runningCount = 0;

    streamController = new StreamController();
  }

  void addTask(Task task) {
    queue.addLast(task);
  }

  Future processQueue() async {
    bool started = await _initialStart();

    if (!started) {
      Logger.root.info("No files to process");
      streamController.add(null);
    }
    return streamController.stream.first;
  }

  Future<bool> _initialStart() async {
    bool result = queue.length > 0;
    for (int i = 0; i < min(maxThreads, queue.length); ++i) {
      startTask();
    }

    return result;
  }

  Future startTask() async {
    if (queue.length == 0) {
      if (runningCount == 0) {
        Logger.root.info("All files processed");
        streamController.add(null);
      }
      return;
    }
    ++runningCount;
    Task task = queue.removeFirst();

    Isolate isolate;
    ReceivePort receivePort = new ReceivePort();
    receivePort.listen((msg) {
      if (msg is SendPort) {
        msg.send(task);
      } else if (msg is Log) {
        Logger.root.log(msg.logLevel, msg.message);
      } else if (msg is String){
        watcher.hashes[msg] = true;
        task.file.hash = msg;
      } else {
        running.remove(isolate);
        receivePort.close();
        --runningCount;
        startTask();
      }
    });

    isolate = await Isolate.spawn(runTask, receivePort.sendPort);
    running.add(isolate);
  }
}

void runTask(SendPort sendPort) {
  ReceivePort receivePort = new ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.first.then((msg) {
    if (msg is! Task) {
      return;
    }
    SOFile file = msg.file;
    AbstractMetadataContainer metadataContainer = msg.metadataContainer;

    sendPort.send(new Log("Process: ${file.path}"));
    var f = new File(file.path);
    var hash = new SHA256();
    hash.add(f.readAsBytesSync());
    var sha256 = hash.close();
    file.hash = CryptoUtils.bytesToHex(sha256);
    sendPort.send(file.hash);

    if (!metadataContainer.restoreFromCache(file)) {
      // Creating new copy
      metadataContainer.generateFile(file);
    }

    sendPort.send(false);
    receivePort.close();
  });
}