// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:static_compress/static_compress.dart';
import 'package:args/args.dart';
import 'package:logging/logging.dart';

ArgParser getParser () {
  var result = new ArgParser();
  result.addFlag("help", abbr: "h", help: "Show help", negatable: false);
  result.addOption("dir", abbr: "d", help: "Directory to process [required]");
  result.addOption("meta", abbr: "m", help: 'Where to store metadata', defaultsTo: ".compress_data");
  result.addOption("threads", abbr: "t", help: "Threads count", defaultsTo: "4");
  return result;
}

main(List<String> args) async {
  var parser = getParser();
  var results;
  try {
    results = parser.parse(args);
  } catch (e) {
    if (e is FormatException) {
      print(e.message);
    }
    print("Usage:\n");
    print(parser.usage);
    return;
  }


  if (results['dir'] == null || results['help']) {
    print("Usage:\n");
    print(parser.usage);
    return;
  }

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.message}');
  });

  int threads = int.parse(results['threads'], onError: (_) => 4);

  Watcher watcher = new Watcher(results['dir'], results['meta'], threads);
  await watcher.process();
}
