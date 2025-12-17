import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Initialize logging for the app. Call this once in main().
void initLogging({Level level = Level.INFO}) {
  Logger.root.level = level;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('${record.level.name} [${record.loggerName}] ${record.message}');
      if (record.error != null) {
        print('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        print(record.stackTrace);
      }
    }
  });
}

/// Get a logger for a class. Usage:
/// ```dart
/// final _log = getLogger('MyClass');
/// _log.info('Something happened');
/// _log.fine('Debug info');  // Only shown if level <= FINE
/// ```
Logger getLogger(String name) => Logger(name);
