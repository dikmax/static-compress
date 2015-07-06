part of static_compress;

abstract class AbstractMetadataContainer {
  Map<String, AbstractTransformer> transformers;

  AbstractMetadataContainer(TransformersMapFactory transformersMapFactory) {
    transformers = transformersMapFactory();
  }

  Iterable<String> getHashes();
  void removeHash(String hash);
  void removeHashes(Iterable<String> hashes) {
    hashes.forEach(removeHash);
  }
  SODirectory getMetadata();
  void writeMetadata(SODirectory metadata);
  bool restoreFromCache(SOFile file);
  void generateFile(SOFile file);

  AbstractTransformer getTransformer(SOFile file) {
    var ext = extension(file.name);
    return transformers[ext];
  }
}

class MetadataContainer extends AbstractMetadataContainer {
  Directory dir;
  File metadataFile;

  MetadataContainer(this.dir, transformersMapFactory) : super(transformersMapFactory) {
    _checkAndCreate();
  }
  MetadataContainer.fromString(String _dir, transformersMapFactory) : super(transformersMapFactory) {
    dir = new Directory(absolute(_dir));
    _checkAndCreate();
  }

  void _checkAndCreate() {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    metadataFile = new File(join(dir.path, '.metadata'));
  }

  @override
  Iterable<String> getHashes() {
    List<String> result = <String>[];
    dir.listSync().forEach((e) {
      var name = basename(e.path);
      if (name.length == 64) {
        result.add(name);
      }
    });

    return result;
  }

  @override
  void removeHash(String hash) {
    Logger.root.info("Delete cache: $hash");
    new File(join(dir.path, hash)).deleteSync();
  }

  @override
  SODirectory getMetadata() {
    SODirectory result;
    if (metadataFile.existsSync()) {
      var json = JSON.decode(UTF8.decode(GZIP.decode(metadataFile.readAsBytesSync())));
      //processedSet = SOItem.fromJson(dirname(watchDirectory.path), json);
      // TODO fix
      result = SOItem.fromJson("", json);
    }
    return result;
  }

  @override
  void writeMetadata(SODirectory metadata) {
    metadataFile.writeAsBytesSync(GZIP.encode(UTF8.encode(JSON.encode(metadata))));
  }

  @override
  bool restoreFromCache(SOFile file) {
    var cacheFile = new File(join(dir.path, file.hash));
    var transformer = getTransformer(file);
    if (transformer == null) {
      return true;
    }
    var resultFile = new File(transformer.updateName(file.path));
    if (cacheFile.existsSync()) {
      if (resultFile.existsSync()) {
        resultFile.deleteSync(); // TODO remove filesystem dependency
      }
      cacheFile.copySync(resultFile.path); // TODO remove filesystem dependency
      return true;
    }

    return false;
  }

  @override
  void generateFile(SOFile file) {
    var transformer = getTransformer(file);
    if (transformer == null) {
      return;
    }
    var fileContents = transformer.transform(file);
    var cacheFile = new File(join(dir.path, file.hash));
    var resultFile = new File(transformer.updateName(file.path)); // TODO remove filesystem dependency
    cacheFile.writeAsBytesSync(fileContents);
    resultFile.writeAsBytesSync(fileContents);
  }
}