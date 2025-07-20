import 'package:flutter/foundation.dart';

/// Log levels
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Logger service for application-wide logging
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  factory LoggerService() => _instance;

  LoggerService._internal();

  /// Current log level
  LogLevel _logLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// Whether to include timestamps
  bool includeTimestamp = true;

  /// Whether to include the source location
  bool includeSource = kDebugMode;

  /// Log listeners for external logging (e.g., crash reporting)
  final List<void Function(LogLevel level, String message, dynamic error, StackTrace? stackTrace)> _listeners = [];

  /// Set the minimum log level
  void setLogLevel(LogLevel level) {
    _logLevel = level;
  }

  /// Add a log listener
  void addListener(void Function(LogLevel level, String message, dynamic error, StackTrace? stackTrace) listener) {
    _listeners.add(listener);
  }

  /// Remove a log listener
  void removeListener(void Function(LogLevel level, String message, dynamic error, StackTrace? stackTrace) listener) {
    _listeners.remove(listener);
  }

  /// Log verbose message
  void verbose(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.verbose, message, error, stackTrace);
  }

  /// Log debug message
  void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// Log info message
  void info(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Log warning message
  void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Log error message
  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Log fatal message
  void fatal(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, error, stackTrace);
  }

  /// Internal logging method
  void _log(LogLevel level, String message, dynamic error, StackTrace? stackTrace) {
    // Check if should log based on level
    if (level.index < _logLevel.index) return;

    final timestamp = includeTimestamp ? DateTime.now().toIso8601String() : '';
    final levelStr = level.name.toUpperCase();
    final source = includeSource ? _getSource() : '';

    String fullMessage = '';
    if (includeTimestamp) fullMessage += '[$timestamp] ';
    fullMessage += '[$levelStr] ';
    if (includeSource && source.isNotEmpty) fullMessage += '[$source] ';
    fullMessage += message;

    // Print to console
    if (kDebugMode) {
      switch (level) {
        case LogLevel.verbose:
        case LogLevel.debug:
        case LogLevel.info:
          debugPrint(fullMessage);
          break;
        case LogLevel.warning:
          debugPrint('\x1B[33m$fullMessage\x1B[0m'); // Yellow
          break;
        case LogLevel.error:
        case LogLevel.fatal:
          debugPrint('\x1B[31m$fullMessage\x1B[0m'); // Red
          if (error != null) {
            debugPrint('\x1B[31mError: $error\x1B[0m');
          }
          if (stackTrace != null) {
            debugPrint('\x1B[31mStackTrace:\n$stackTrace\x1B[0m');
          }
          break;
      }
    }

    // Notify listeners
    for (final listener in _listeners) {
      try {
        listener(level, message, error, stackTrace);
      } catch (e) {
        // Prevent listener errors from breaking logging
        if (kDebugMode) {
          print('Error in log listener: $e');
        }
      }
    }
  }

  /// Get the source location of the log call
  String _getSource() {
    try {
      final stackTrace = StackTrace.current;
      final frames = stackTrace.toString().split('\n');
      
      // Skip frames from this logger
      for (final frame in frames) {
        if (!frame.contains('logger_service.dart') && 
            !frame.contains('package:flutter/')) {
          final match = RegExp(r'#\d+\s+(.+)\s+\((.+):(\d+):(\d+)\)').firstMatch(frame);
          if (match != null) {
            final file = match.group(2)?.split('/').last ?? '';
            final line = match.group(3) ?? '';
            return '$file:$line';
          }
        }
      }
    } catch (_) {
      // Ignore errors in getting source
    }
    return '';
  }
}

/// Global logger instance
final logger = LoggerService();