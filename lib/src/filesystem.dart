part of static_compress;

abstract class SOItem {
  String path;
  String name;
  bool isDirectory;

  SOItem(this.path, this.name, this.isDirectory);

  Map toJson() {
    var map = new Map();
    map['name'] = name;
    map['directory'] = isDirectory;
    return map;
  }

  static SOItem fromJson(String path, json) {
    if (json['directory']) {
      return SODirectory.fromJson(path, json);
    } else {
      return SOFile.fromJson(path, json);
    }
  }
}

class SODirectory extends SOItem {
  Map<String, SOItem> children;
  SODirectory(path, name) : super(path, name, true), children = {};

  Map toJson() {
    var map = super.toJson();
    map['children'] = new List.from(children.values);
    return map;
  }

  static SODirectory fromJson(String path, json) {
    var subPath = join(path, json['name']);
    var result = new SODirectory(subPath, json['name']);
    result.children = {};
    json['children'].forEach((e) {
      var item = SOItem.fromJson(subPath, e);
      result.children[item.name] = item;
    });
    return result;
  }

  bool operator== (obj) => obj is SODirectory && obj.name == name;
}

class SOFile extends SOItem {
  DateTime modified;
  int size;
  String hash;

  SOFile(path, name, this.modified, this.size) : super(path, name, false);

  Map toJson() {
    var map = super.toJson();
    map['modified'] = modified.toIso8601String();
    map['size'] = size;
    map['hash'] = hash;
    return map;
  }

  static SOFile fromJson(String path, json) {
    var result = new SOFile(join(path, json['name']), json['name'], DateTime.parse(json['modified']), json['size']);
    result.hash = json['hash'];
    return result;
  }

  bool operator== (obj) => obj is SOFile && obj.name == name && obj.modified == modified && obj.size == size;
}
