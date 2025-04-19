enum LogLevel { debug, info, warning, error }

class Logger {
  static final Logger _instance = Logger._internal();

  factory Logger() => _instance;

  Logger._internal();

  final bool _isProduction = false; // Set to true for production builds
  LogLevel _level = LogLevel.debug;

  void setLevel(LogLevel level) {
    _level = level;
  }

  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isProduction) return;
    if (_level.index <= LogLevel.debug.index) {
      _log('DEBUG', message, error, stackTrace);
    }
  }

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_level.index <= LogLevel.info.index) {
      _log('INFO', message, error, stackTrace);
    }
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_level.index <= LogLevel.warning.index) {
      _log('WARNING', message, error, stackTrace);
    }
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_level.index <= LogLevel.error.index) {
      _log('ERROR', message, error, stackTrace);
    }
  }

  void _log(
    String prefix,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    final now = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('[$now] $prefix: $message');

    if (error != null) {
      // ignore: avoid_print
      print('Error details: $error');
    }

    if (stackTrace != null) {
      // ignore: avoid_print
      print('Stack trace: $stackTrace');
    }
  }
}

final logger = Logger();
