import 'package:flutter/foundation.dart';

class AppLogEntry {
  final DateTime timestamp;
  final String level;
  final String tag;
  final String message;

  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  @override
  String toString() {
    return '[${timestamp.toIso8601String()}] [$level] [$tag] $message';
  }
}

class AppLogger extends ChangeNotifier {
  AppLogger._internal();

  static final AppLogger instance = AppLogger._internal();

  final List<AppLogEntry> _entries = [];

  List<AppLogEntry> get entries => List.unmodifiable(_entries.reversed);

  void info(String tag, String message) {
    _add('INFO', tag, message);
  }

  void error(String tag, String message,
      [Object? error, StackTrace? stackTrace]) {
    final buffer = StringBuffer(message);

    if (error != null) {
      buffer.write('\nERROR: $error');
    }

    if (stackTrace != null) {
      buffer.write('\nSTACK:\n$stackTrace');
    }

    _add('ERROR', tag, buffer.toString());
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  String exportAsText() {
    return _entries.map((e) => e.toString()).join('\n\n');
  }

  void _add(String level, String tag, String message) {
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );

    _entries.add(entry);

    if (_entries.length > 300) {
      _entries.removeAt(0);
    }

    debugPrint(entry.toString());
    notifyListeners();
  }
}
