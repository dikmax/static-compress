part of static_compress;

class Watcher {
  AbstractTreeReader treeReader;
  Directory dataDirectory;
  Map<String, AbstractTransformer> transformers;
  Map<String, bool> hashes;
  TasksPool pool;

  Watcher(TransformersMapFactory _transformersMapFactory,
          this.treeReader, String _dataDirectory, int threadsCount) {
    dataDirectory = new Directory(absolute(_dataDirectory));
    if (!dataDirectory.existsSync()) {
      dataDirectory.createSync(recursive: true);
    }

    hashes = readHashes();

    pool = new TasksPool(this, threadsCount);

    transformers = _transformersMapFactory();
  }

  Map<String, bool> readHashes() {
    Map<String, bool> result = {};
    dataDirectory.listSync().forEach((e) {
      var name = basename(e.path);
      if (name.length == 64) {
        result[name] = false;
      }
    });

    return result;
  }

  void cleanHashes() {
    hashes.forEach((hash, used) {
      if (!used) {
        Logger.root.info("Delete cache: $hash");
        new File(join(dataDirectory.path, hash)).deleteSync();
      }
    });
  }

  Set<String> unknownExtensions = new Set();

  Future process () async {
    SODirectory originalSet = treeReader.readTree();

    var metadata = new File(join(dataDirectory.path, '.metadata'));
    SODirectory processedSet;
    if (metadata.existsSync()) {
      var json = JSON.decode(UTF8.decode(GZIP.decode(metadata.readAsBytesSync())));
      //processedSet = SOItem.fromJson(dirname(watchDirectory.path), json);
      // TODO fix
      processedSet = SOItem.fromJson("", json);
    }

    compareSets(originalSet, processedSet);
    await pool.processQueue();
    metadata.writeAsBytesSync(GZIP.encode(UTF8.encode(JSON.encode(originalSet))));

    cleanHashes();

    Logger.root.info("Unknows extensions: $unknownExtensions");
  }

  void compareSets(SODirectory original, SODirectory processed) {
    // Check additions and changes
    original.children.forEach((name, item) {
      if (processed != null && item == processed.children[name] && item is SOFile) {
        var hash = (processed.children[name] as SOFile).hash;
        item.hash = hash;
        hashes[hash] = true;
        return true;
      }

      if (item.isDirectory) {
        compareSets(item, processed == null ? null : processed.children[name]);
      } else {
        processItem(item as SOFile);
      }
    });
  }

  void processItem(SOFile file) {
    var ext = extension(file.name);
    if (transformers[ext] == null) {
      return;
    }
    var transformer = transformers[ext];

    pool.addTask(new Task(file, transformer, dataDirectory));
  }
}
