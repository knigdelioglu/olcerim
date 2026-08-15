import 'dart:developer' as developer;

abstract final class AppLogger {
  static void info(String message) {
    developer.log(message, name: 'olcerim');
  }

  static void warning(String message, [Object? error, StackTrace? stack]) {
    developer.log(
      message,
      name: 'olcerim',
      level: 900,
      error: error,
      stackTrace: stack,
    );
  }

  static void error(String message, Object error, StackTrace? stack) {
    developer.log(
      message,
      name: 'olcerim',
      level: 1000,
      error: error,
      stackTrace: stack,
    );
  }
}
