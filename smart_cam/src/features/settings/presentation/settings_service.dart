/// Settings service for managing app preferences.
import 'package:flutter/foundation.dart';
import '../domain/app_settings.dart';

class SettingsService extends ChangeNotifier {
  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  /// Update selected AI provider.
  void setProvider(String provider) {
    _settings.selectedProvider = provider;
    notifyListeners();
  }

  /// Update API key.
  void setApiKey(String key) {
    _settings.apiKey = key;
    notifyListeners();
  }

  /// Toggle auto analysis.
  void toggleAutoAnalysis(bool enabled) {
    _settings.enableAutoAnalysis = enabled;
    notifyListeners();
  }

  /// Toggle grid lines.
  void toggleGridLines(bool show) {
    _settings.showGridLines = show;
    notifyListeners();
  }

  /// Load settings from storage (placeholder).
  Future<void> loadSettings() async {
    // TODO: Implement persistent storage with shared_preferences
    _settings = AppSettings();
    notifyListeners();
  }

  /// Save settings to storage (placeholder).
  Future<void> saveSettings() async {
    // TODO: Implement persistent storage with shared_preferences
    print('Settings saved: ${_settings.toJson()}');
  }
}
