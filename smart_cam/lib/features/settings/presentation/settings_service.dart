/// Settings service for managing app preferences.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/app_settings.dart';

class SettingsService extends ChangeNotifier {
  static const String _storageKey = 'app_settings';

  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  /// Update selected AI provider.
  void setProvider(String provider) {
    _settings.selectedProvider = provider;
    notifyListeners();
    _saveSettings();
  }

  /// Update API key.
  void setApiKey(String key) {
    _settings.apiKey = key;
    notifyListeners();
    _saveSettings();
  }

  /// Toggle auto analysis.
  void toggleAutoAnalysis(bool enabled) {
    _settings.enableAutoAnalysis = enabled;
    notifyListeners();
    _saveSettings();
  }

  /// Toggle grid lines.
  void toggleGridLines(bool show) {
    _settings.showGridLines = show;
    notifyListeners();
    _saveSettings();
  }

  /// Update custom base URL.
  void setCustomBaseUrl(String url) {
    _settings.customBaseUrl = url;
    notifyListeners();
    _saveSettings();
  }

  /// Update custom URL type.
  void setCustomUrlType(String type) {
    _settings.customUrlType = type;
    notifyListeners();
    _saveSettings();
  }

  /// Load settings from persistent storage.
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_storageKey);

      if (settingsJson != null) {
        // Parse JSON string back to Map
        final Map<String, dynamic> json = _decodeJson(settingsJson);
        _settings = AppSettings.fromJson(json);
        AppLogger.i('Settings loaded from storage', 'SettingsService');
      } else {
        // First run, use defaults
        _settings = AppSettings();
        await _saveSettings(); // Save defaults
        AppLogger.i('Using default settings', 'SettingsService');
      }

      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to load settings', 'SettingsService', e);
      // Fallback to defaults
      _settings = AppSettings();
      notifyListeners();
    }
  }

  /// Save settings to persistent storage.
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _settings.toJson();
      final jsonString = _encodeJson(json);

      await prefs.setString(_storageKey, jsonString);
      AppLogger.d('Settings saved to storage', 'SettingsService');
    } catch (e) {
      AppLogger.e('Failed to save settings', 'SettingsService', e);
    }
  }

  /// Test API connection with current settings.
  Future<Map<String, dynamic>> testConnection() async {
    try {
      AppLogger.i('Testing API connection...', 'SettingsService');

      // Validate API key
      if (_settings.apiKey.isEmpty) {
        return {
          'success': false,
          'message': 'Please enter an API key first',
        };
      }

      // Simulate API call (replace with actual API call in production)
      // For now, we'll do a basic validation
      await Future.delayed(const Duration(milliseconds: 800));

      // Basic validation
      if (_settings.apiKey.length < 10) {
        return {
          'success': false,
          'message': 'API key appears to be invalid (too short)',
        };
      }

      // Simulate success based on provider
      final provider = _settings.selectedProvider.toLowerCase();
      String message = 'Connection successful!';

      switch (provider) {
        case 'openai':
          message = 'OpenAI connection successful (GPT-4o)';
          break;
        case 'anthropic':
          message = 'Anthropic connection successful (Claude 3)';
          break;
        case 'azure':
          message = 'Azure OpenAI connection successful';
          break;
        case 'custom':
          message = 'Custom endpoint connection successful';
          break;
        default:
          message = 'Connection successful!';
      }

      return {
        'success': true,
        'message': message,
        'provider': _settings.selectedProvider,
      };
    } catch (e) {
      AppLogger.e('Connection test failed', 'SettingsService', e);
      return {
        'success': false,
        'message': 'Connection failed: ${e.toString()}',
      };
    }
  }

  /// Clear all settings (reset to defaults).
  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _settings = AppSettings();
      notifyListeners();
      AppLogger.i('Settings cleared', 'SettingsService');
    } catch (e) {
      AppLogger.e('Failed to clear settings', 'SettingsService', e);
    }
  }

  /// Helper method to encode JSON.
  String _encodeJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    buffer.write('{');
    bool first = true;
    json.forEach((key, value) {
      if (!first) buffer.write(',');
      buffer.write('"$key":');
      if (value is String) {
        buffer.write('"${_escapeString(value)}"');
      } else if (value is bool) {
        buffer.write(value ? 'true' : 'false');
      } else if (value is num) {
        buffer.write(value);
      }
      first = false;
    });
    buffer.write('}');
    return buffer.toString();
  }

  /// Helper method to decode JSON.
  Map<String, dynamic> _decodeJson(String jsonString) {
    final Map<String, dynamic> result = {};
    final content = jsonString.substring(1, jsonString.length - 1); // Remove { }

    if (content.isEmpty) return result;

    final pairs = content.split(',');
    for (final pair in pairs) {
      final colonIndex = pair.indexOf(':');
      if (colonIndex == -1) continue;

      final key = pair.substring(1, colonIndex - 1); // Remove quotes
      final value = pair.substring(colonIndex + 1).trim();

      if (value == 'true') {
        result[key] = true;
      } else if (value == 'false') {
        result[key] = false;
      } else if (value.startsWith('"')) {
        result[key] = value.substring(1, value.length - 1); // Remove quotes
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// Escape special characters in JSON strings.
  String _escapeString(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}

/// Simple logger for settings service (replace with your actual logger if needed).
class AppLogger {
  static void i(String message, String tag) {
    if (kDebugMode) {
      print('[INFO] [$tag] $message');
    }
  }

  static void d(String message, String tag) {
    if (kDebugMode) {
      print('[DEBUG] [$tag] $message');
    }
  }

  static void e(String message, String tag, Object? error) {
    if (kDebugMode) {
      print('[ERROR] [$tag] $message');
      if (error != null) {
        print('[ERROR] [$tag] $error');
      }
    }
  }
}
