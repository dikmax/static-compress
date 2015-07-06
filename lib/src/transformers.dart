part of static_compress;

abstract class AbstractTransformer {
  String updateName(String name);

  List<int> transform(SOFile file);
}

class ZopfliTransformer extends AbstractTransformer {
  ZopfliTransformer() {
    var zopfli = whichSync("zopfli", orElse: () => null);
    if (zopfli == null) {
      throw new Exception("zopfli not found.");
    }
  }

  List<int> transform(SOFile file) {
    var res = Process.runSync("zopfli", ["-c", "--i100", "--gzip", file.path], stdoutEncoding: null);
    return res.stdout;
  }

  String updateName(String name) {
    return name + '.gz';
  }
}

class WebpTransformer extends AbstractTransformer {
  bool lossless;

  WebpTransformer(this.lossless) {
    var cwebp = whichSync("cwebp", orElse: () => null);
    if (cwebp == null) {
      throw new Exception("cwebp not found.");
    }
  }

  List<int> transform(SOFile file) {
    var res;
    if (lossless) {
      res = Process.runSync("cwebp", [file.path, "-mt", "-lossless", "-q", "100", "-m", "6", "-o", "-"], stdoutEncoding: null);
    } else {
      res = Process.runSync("cwebp", [file.path, "-jpeg_like", "-mt", "-m", "6", "-o", "-"], stdoutEncoding: null);
    }

    return res.stdout;
  }

  String updateName(String name) {
    return name + '.webp';
  }
}

typedef Map<String, AbstractTransformer> TransformersMapFactory();

Map<String, AbstractTransformer> defaultTransformersMapFactory() {
  Map<String, AbstractTransformer> result = {};

  try {
    var zopfliTransformer = new ZopfliTransformer();
    result.addAll({
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
    result.addAll({
      ".jpg": jpegTransformer,
      ".png": pngTransformer
    });
  } catch (e) {
    Logger.root.warning(e.message + " WebP processging will be disabled.");
  }

  return result;
}
