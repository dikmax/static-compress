part of static_compress;

class Watcher {
  AbstractTreeReader treeReader;
  AbstractMetadataContainer metadataContainer;

  Map<String, bool> hashes;
  TasksPool pool;

  Watcher(this.treeReader, this.metadataContainer, int threadsCount) {

    hashes = readHashes();

    pool = new TasksPool(this, threadsCount);
  }

  Map<String, bool> readHashes() {
    Map<String, bool> result = {};
    metadataContainer.getHashes().forEach((e) {
      result[e] = false;
    });

    return result;
  }

  void cleanHashes() {
    hashes.forEach((hash, used) {
      if (!used) {
        metadataContainer.removeHash(hash);
      }
    });
  }

  Set<String> unknownExtensions = new Set();

  Future process () async {
    SODirectory originalSet = treeReader.readTree();

    SODirectory processedSet = metadataContainer.getMetadata();

    compareSets(originalSet, processedSet);
    await pool.processQueue();
    metadataContainer.writeMetadata(originalSet);

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
        pool.addTask(new Task(item, metadataContainer));
      }
    });
  }
}
