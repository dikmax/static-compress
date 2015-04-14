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
