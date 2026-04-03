/// Logger utility for consistent logging across the app.
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void d(String message, [String? tag]) {
    _logger.d(_formatMessage(message, tag));
  }

  static void i(String message, [String? tag]) {
    _logger.i(_formatMessage(message, tag));
  }

  static void w(String message, [String? tag]) {
    _logger.w(_formatMessage(message, tag));
  }

  static void e(String message, [String? tag, dynamic error]) {
    _logger.e(_formatMessage(message, tag), error: error);
  }

  static String _formatMessage(String message, String? tag) {
    return tag != null ? '[$tag] $message' : message;
  }
}
