part of static_compress;

class Watcher {
  Directory watchDirectory;
  Directory dataDirectory;
  Map<String, AbstractTransformer> transformers;
  Map<String, bool> hashes;

  Watcher(String _watchDirectory, String _dataDirectory) {
    watchDirectory = new Directory(absolute(_watchDirectory));
    if (!watchDirectory.existsSync()) {
      throw new Exception("Watch directory not found");
    }
    dataDirectory = new Directory(absolute(_dataDirectory));
    if (!dataDirectory.existsSync()) {
      dataDirectory.createSync(recursive: true);
    }

    hashes = readHashes();

    transformers = {};

    try {
      var zopfliTransformer = new ZopfliTransformer();
      transformers.addAll({
        ".css": zopfliTransformer,
        ".js": zopfliTransformer,
        ".json": zopfliTransformer,
        ".html": zopfliTransformer,
        ".rss": zopfliTransformer,
        ".txt": zopfliTransformer,
        ".xml": zopfliTransformer,

        ".eot": zopfliTransformer,
        ".svg": zopfliTransformer,
        ".ttf": zopfliTransformer,
        ".woff": zopfliTransformer,
      });
    } catch(e) {
      Logger.root.warning(e.message + " Gzip processging will be disabled.");
    }

    try {
      var jpegTransformer = new WebpTransformer(false);
      var pngTransformer = new WebpTransformer(true);
      transformers.addAll({
        ".jpg": jpegTransformer,
        ".png": pngTransformer
      });
    } catch (e) {
      Logger.root.warning(e.message + " WebP processging will be disabled.");
    }
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

  SODirectory readTree(Directory dir) {
    var result = new SODirectory(dir.path, basename(dir.path));

    var list = dir.listSync();
    list.forEach((el) {
      var stat = el.statSync();
      if (stat.type == FileSystemEntityType.DIRECTORY) {
        var item = readTree(el as Directory);
        result.children[item.name] = item;
      } else if (stat.type == FileSystemEntityType.FILE) {
        var ext = extension(el.path);
        if (transformers[ext] == null) {
          unknownExtensions.add(ext);
          return;
        }
        var item = new SOFile(el.path, basename(el.path), stat.modified, stat.size);
        result.children[item.name] = item;
      }
    });

    return result;
  }

  void process () {
    SODirectory originalSet = readTree(watchDirectory);
    var metadata = new File(join(dataDirectory.path, '.metadata'));
    SODirectory processedSet;
    if (metadata.existsSync()) {
      var json = JSON.decode(UTF8.decode(GZIP.decode(metadata.readAsBytesSync())));
      processedSet = SOItem.fromJson(dirname(watchDirectory.path), json);
    }

    compareSets(originalSet, processedSet);
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

    Logger.root.info("Process: ${file.path}");
    var f = new File(file.path);
    var hash = new SHA256();
    hash.add(f.readAsBytesSync());
    var sha256 = hash.close();
    file.hash = CryptoUtils.bytesToHex(sha256);

    var cacheFile = new File(join(dataDirectory.path, file.hash));
    var resultFile = new File(transformer.updateName(file.path));
    if (cacheFile.existsSync()) {
      if (resultFile.existsSync()) {
        resultFile.deleteSync();
      }
      cacheFile.copySync(resultFile.path);
    } else {
      var fileContents = transformer.transform(file);
      cacheFile.writeAsBytesSync(fileContents);
      resultFile.writeAsBytesSync(fileContents);
    }
    hashes[file.hash] = true;
  }
}
