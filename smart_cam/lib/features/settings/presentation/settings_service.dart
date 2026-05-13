import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../domain/app_settings.dart';

enum ApiValidationStatus {
  notConfigured,
  unverified,
  checking,
  valid,
  invalid,
}

class SettingsService extends ChangeNotifier {
  static const String _storageKey = 'app_settings';

  final http.Client _client;
  final bool _ownsClient;
  AppSettings _settings = AppSettings();
  ApiValidationStatus _apiValidationStatus = ApiValidationStatus.notConfigured;
  String? _apiValidationMessage;

  SettingsService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  AppSettings get settings => _settings;

  ApiValidationStatus get apiValidationStatus => _apiValidationStatus;

  String? get apiValidationMessage => _apiValidationMessage;

  bool get isApiConfigured => _settings.apiKey.trim().isNotEmpty;

  /// Update selected AI provider.
  void setProvider(String provider) {
    _settings.selectedProvider = provider;
    _resetApiValidationForCurrentConfig();
    notifyListeners();
    _saveSettings();
  }

  /// Update API key.
  void setApiKey(String key) {
    _settings.apiKey = key;
    _resetApiValidationForCurrentConfig();
    notifyListeners();
    _saveSettings();
  }

  /// Toggle auto analysis.
  void toggleAutoAnalysis(bool enabled) {
    _settings.enableAutoAnalysis = enabled;
    notifyListeners();
    _saveSettings();
  }

  void toggleManualAnalysisTrigger(bool enabled) {
    _settings.manualAnalysisTrigger = enabled;
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
    _resetApiValidationForCurrentConfig();
    notifyListeners();
    _saveSettings();
  }

  /// Update custom URL type.
  void setCustomUrlType(String type) {
    _settings.customUrlType = type;
    _resetApiValidationForCurrentConfig();
    notifyListeners();
    _saveSettings();
  }

  void setCustomModel(String model) {
    _settings.customModel = model;
    _resetApiValidationForCurrentConfig();
    notifyListeners();
    _saveSettings();
  }

  void setAzureEndpoint(String endpoint) {
    _settings.azureEndpoint = endpoint;
    _resetApiValidationForCurrentConfig();
    notifyListeners();
    _saveSettings();
  }

  void setAzureDeployment(String deployment) {
    _settings.azureDeployment = deployment;
    _resetApiValidationForCurrentConfig();
    notifyListeners();
    _saveSettings();
  }

  void setAzureApiVersion(String apiVersion) {
    _settings.azureApiVersion = apiVersion;
    _resetApiValidationForCurrentConfig();
    notifyListeners();
    _saveSettings();
  }

  /// Load settings from persistent storage.
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_storageKey);

      if (settingsJson != null) {
        final Map<String, dynamic> json =
            jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(json);
        _resetApiValidationForCurrentConfig();
        AppLogger.i('Settings loaded from storage', 'SettingsService');
      } else {
        // First run, use defaults
        _settings = AppSettings();
        _resetApiValidationForCurrentConfig();
        await _saveSettings(); // Save defaults
        AppLogger.i('Using default settings', 'SettingsService');
      }

      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to load settings', 'SettingsService', e);
      // Fallback to defaults
      _settings = AppSettings();
      _resetApiValidationForCurrentConfig();
      notifyListeners();
    }
  }

  /// Save settings to persistent storage.
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_settings.toJson());

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
        _setApiValidation(
          ApiValidationStatus.notConfigured,
          'API key 未配置',
        );
        return {
          'success': false,
          'message': 'Please enter an API key first',
        };
      }

      _setApiValidation(ApiValidationStatus.checking, '正在验证 API');

      if (_settings.selectedProvider == 'zhipu_glm') {
        return await _testZhipuGlmConnection();
      }

      return await _testChatConnection();
    } catch (e) {
      AppLogger.e('Connection test failed', 'SettingsService', e);
      _setApiValidation(ApiValidationStatus.invalid, e.toString());
      return {
        'success': false,
        'message': 'Connection failed: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> _testZhipuGlmConnection() async {
    final response = await _client
        .post(
          Uri.parse(AppConfig.zhipuGlmApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_settings.apiKey}',
          },
          body: jsonEncode({
            'model': AppConfig.zhipuGlmVisionModel,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'text',
                    'text': 'Reply exactly OK to confirm connectivity.',
                  },
                ],
              },
            ],
            'thinking': {'type': 'disabled'},
          }),
        )
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      final message = '智谱 GLM connection failed: ${response.statusCode}';
      _setApiValidation(ApiValidationStatus.invalid, message);
      return {
        'success': false,
        'message': message,
      };
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = jsonData['choices'];
    if (choices is! List || choices.isEmpty) {
      const message = '智谱 GLM connection failed: invalid response';
      _setApiValidation(ApiValidationStatus.invalid, message);
      return {
        'success': false,
        'message': message,
      };
    }

    _setApiValidation(
      ApiValidationStatus.valid,
      '智谱 GLM connection successful',
    );
    return {
      'success': true,
      'message': '智谱 GLM connection successful',
      'provider': _settings.selectedProvider,
    };
  }

  Future<Map<String, dynamic>> _testChatConnection() async {
    final provider = _settings.selectedProvider;
    late final Uri uri;
    late final Map<String, String> headers;
    late final Map<String, dynamic> body;
    late final String successMessage;

    switch (provider) {
      case 'openai':
        uri = Uri.parse(AppConfig.openAiChatCompletionsUrl);
        headers = _bearerHeaders(_settings.apiKey);
        body = _openAiTextBody(AppConfig.openAiVisionModel);
        successMessage = 'OpenAI connection successful';
        break;
      case 'anthropic':
        uri = Uri.parse(AppConfig.anthropicMessagesUrl);
        headers = _anthropicHeaders(_settings.apiKey);
        body = _anthropicTextBody(AppConfig.anthropicVisionModel);
        successMessage = 'Anthropic connection successful';
        break;
      case 'azure':
        final endpoint =
            _requireConfig(_settings.azureEndpoint, 'Azure endpoint');
        final deployment =
            _requireConfig(_settings.azureDeployment, 'Azure deployment');
        final apiVersion =
            _requireConfig(_settings.azureApiVersion, 'Azure API version');
        uri = Uri.parse(
          '${_trimTrailingSlash(endpoint)}/openai/deployments/${Uri.encodeComponent(deployment)}/chat/completions?api-version=${Uri.encodeQueryComponent(apiVersion)}',
        );
        headers = _azureHeaders(_settings.apiKey);
        body = _openAiTextBody(deployment);
        successMessage = 'Azure OpenAI connection successful';
        break;
      case 'custom':
        final baseUrl =
            _requireConfig(_settings.customBaseUrl, 'Custom base URL');
        final model = _requireConfig(_settings.customModel, 'Custom model');
        if (_settings.customUrlType == 'anthropic') {
          uri = _appendEndpoint(baseUrl, 'messages');
          headers = _anthropicHeaders(_settings.apiKey);
          body = _anthropicTextBody(model);
        } else {
          uri = _appendEndpoint(baseUrl, 'chat/completions');
          headers = _bearerHeaders(_settings.apiKey);
          body = _openAiTextBody(model);
        }
        successMessage = 'Custom endpoint connection successful';
        break;
      default:
        final message = 'Unsupported provider: $provider';
        _setApiValidation(ApiValidationStatus.invalid, message);
        return {'success': false, 'message': message};
    }

    final response = await _client
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      final message = '$successMessage failed: ${response.statusCode}';
      _setApiValidation(ApiValidationStatus.invalid, message);
      return {'success': false, 'message': message};
    }

    _setApiValidation(ApiValidationStatus.valid, successMessage);
    return {
      'success': true,
      'message': successMessage,
      'provider': provider,
    };
  }

  /// Clear all settings (reset to defaults).
  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _settings = AppSettings();
      _resetApiValidationForCurrentConfig();
      notifyListeners();
      AppLogger.i('Settings cleared', 'SettingsService');
    } catch (e) {
      AppLogger.e('Failed to clear settings', 'SettingsService', e);
    }
  }

  void _resetApiValidationForCurrentConfig() {
    if (isApiConfigured) {
      _apiValidationStatus = ApiValidationStatus.unverified;
      _apiValidationMessage = 'API key 已配置，尚未验证';
    } else {
      _apiValidationStatus = ApiValidationStatus.notConfigured;
      _apiValidationMessage = 'API key 未配置';
    }
  }

  void _setApiValidation(ApiValidationStatus status, String message) {
    _apiValidationStatus = status;
    _apiValidationMessage = message;
    notifyListeners();
  }

  Map<String, String> _bearerHeaders(String apiKey) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  Map<String, String> _azureHeaders(String apiKey) {
    return {
      'Content-Type': 'application/json',
      'api-key': apiKey,
    };
  }

  Map<String, String> _anthropicHeaders(String apiKey) {
    return {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': AppConfig.anthropicVersion,
    };
  }

  Map<String, dynamic> _openAiTextBody(String model) {
    return {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Reply exactly OK to confirm connectivity.'
            },
          ],
        },
      ],
    };
  }

  Map<String, dynamic> _anthropicTextBody(String model) {
    return {
      'model': model,
      'max_tokens': 16,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Reply exactly OK to confirm connectivity.'
            },
          ],
        },
      ],
    };
  }

  String _requireConfig(String value, String name) {
    if (value.trim().isEmpty) {
      throw Exception('$name is required');
    }
    return value.trim();
  }

  Uri _appendEndpoint(String baseUrl, String suffix) {
    final trimmed = _trimTrailingSlash(baseUrl);
    if (trimmed.endsWith(suffix)) {
      return Uri.parse(trimmed);
    }
    return Uri.parse('$trimmed/$suffix');
  }

  String _trimTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
    super.dispose();
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
