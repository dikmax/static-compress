// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:static_compress/static_compress.dart';
import 'package:args/args.dart';
import 'package:logging/logging.dart';

ArgParser getParser () {
  var result = new ArgParser();
  result.addOption("dir", abbr: "d", help: "Directory to process [required]");
  result.addOption("meta", abbr: "m", help: 'Where to store metadata', defaultsTo: ".compress_data");
  return result;
}

main(List<String> args) {
  var parser = getParser();
  var results = parser.parse(args);

  if (results['dir'] == null) {
    print("Usage:\n");
    print(parser.usage);
    return;
  }

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.message}');
  });

  Watcher watcher = new Watcher(results['dir'], results['meta']);
  watcher.process();
}
