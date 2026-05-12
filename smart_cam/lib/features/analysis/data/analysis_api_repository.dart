import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/utils/logger.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/analysis_result.dart';
import '../domain/analysis_repository.dart';
import '../domain/edit_suggestion.dart';

typedef AppSettingsProvider = AppSettings Function();

class AnalysisApiRepository implements AnalysisRepository {
  final http.Client _client;
  final AppSettingsProvider _settingsProvider;

  AnalysisApiRepository({
    http.Client? client,
    String apiKey = '',
    String provider = 'openai',
    AppSettingsProvider? settingsProvider,
  })  : _client = client ?? http.Client(),
        _settingsProvider = settingsProvider ??
            (() => AppSettings(
                  selectedProvider: provider,
                  apiKey: apiKey,
                ));

  @override
  Future<AnalysisResult> analyzeImage(Uint8List imageData) async {
    final settings = _settingsProvider();
    AppLogger.i(
      'Analyzing image with provider: ${settings.selectedProvider}',
      'AnalysisApi',
    );

    try {
      final resultJson = await _analyzeImageWithPrompt(
        settings: settings,
        imageData: imageData,
        prompt: _shootingAdvicePrompt,
      );
      final result = AnalysisResult.fromJson(resultJson);
      AppLogger.i(
        'Analysis complete: ${result.shootingAdvice}',
        'AnalysisApi',
      );
      return result;
    } catch (e) {
      AppLogger.e('Analysis failed', 'AnalysisApi', e);
      rethrow;
    }
  }

  @override
  Future<EditSuggestion> suggestEditsForPhoto(Uint8List imageData) async {
    final settings = _settingsProvider();
    AppLogger.i(
      'Requesting edit suggestions with provider: ${settings.selectedProvider}',
      'AnalysisApi',
    );

    try {
      final resultJson = await _analyzeImageWithPrompt(
        settings: settings,
        imageData: imageData,
        prompt: _editSuggestionPrompt,
      );
      return EditSuggestion.fromJson(resultJson);
    } catch (e) {
      AppLogger.e('Edit suggestion failed', 'AnalysisApi', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _analyzeImageWithPrompt({
    required AppSettings settings,
    required Uint8List imageData,
    required String prompt,
  }) async {
    final base64Image = base64Encode(imageData);

    switch (settings.selectedProvider) {
      case 'openai':
        return _postOpenAiCompatibleImage(
          uri: Uri.parse(AppConfig.openAiChatCompletionsUrl),
          apiKey: settings.apiKey,
          model: AppConfig.openAiVisionModel,
          base64Image: base64Image,
          prompt: prompt,
          label: 'OpenAI',
        );
      case 'anthropic':
        return _postAnthropicImage(
          uri: Uri.parse(AppConfig.anthropicMessagesUrl),
          apiKey: settings.apiKey,
          model: AppConfig.anthropicVisionModel,
          base64Image: base64Image,
          prompt: prompt,
          label: 'Anthropic',
        );
      case 'azure':
        return _postOpenAiCompatibleImage(
          uri: _buildAzureChatCompletionsUri(settings),
          apiKey: settings.apiKey,
          model: settings.azureDeployment.trim(),
          base64Image: base64Image,
          prompt: prompt,
          label: 'Azure OpenAI',
          useAzureApiKeyHeader: true,
        );
      case 'custom':
        return _postCustomImage(settings, base64Image, prompt);
      case 'zhipu_glm':
        return _postZhipuGlmImage(settings, base64Image, prompt);
      default:
        throw Exception('Unsupported provider: ${settings.selectedProvider}');
    }
  }

  Future<Map<String, dynamic>> _postCustomImage(
    AppSettings settings,
    String base64Image,
    String prompt,
  ) {
    final baseUrl = _requireNonEmpty(settings.customBaseUrl, 'Custom base URL');
    final model = _requireNonEmpty(settings.customModel, 'Custom model');

    if (settings.customUrlType == 'anthropic') {
      return _postAnthropicImage(
        uri: _appendEndpoint(baseUrl, 'messages'),
        apiKey: settings.apiKey,
        model: model,
        base64Image: base64Image,
        prompt: prompt,
        label: 'Custom Anthropic-compatible',
      );
    }

    return _postOpenAiCompatibleImage(
      uri: _appendEndpoint(baseUrl, 'chat/completions'),
      apiKey: settings.apiKey,
      model: model,
      base64Image: base64Image,
      prompt: prompt,
      label: 'Custom OpenAI-compatible',
    );
  }

  Future<Map<String, dynamic>> _postOpenAiCompatibleImage({
    required Uri uri,
    required String apiKey,
    required String model,
    required String base64Image,
    required String prompt,
    required String label,
    bool useAzureApiKeyHeader = false,
  }) async {
    final response = await _client
        .post(
          uri,
          headers: _jsonHeaders(
            apiKey,
            useAzureApiKeyHeader: useAzureApiKeyHeader,
          ),
          body: jsonEncode({
            'model': _requireNonEmpty(model, '$label model'),
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': prompt},
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:image/jpeg;base64,$base64Image',
                    },
                  },
                ],
              },
            ],
          }),
        )
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('$label API error: ${response.statusCode} - ${response.body}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return _decodeModelJson(_extractChatCompletionContent(jsonData, label));
  }

  Future<Map<String, dynamic>> _postAnthropicImage({
    required Uri uri,
    required String apiKey,
    required String model,
    required String base64Image,
    required String prompt,
    required String label,
  }) async {
    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _requireNonEmpty(apiKey, '$label API key'),
            'anthropic-version': AppConfig.anthropicVersion,
          },
          body: jsonEncode({
            'model': _requireNonEmpty(model, '$label model'),
            'max_tokens': 800,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'image',
                    'source': {
                      'type': 'base64',
                      'media_type': 'image/jpeg',
                      'data': base64Image,
                    },
                  },
                  {'type': 'text', 'text': prompt},
                ],
              },
            ],
          }),
        )
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('$label API error: ${response.statusCode} - ${response.body}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return _decodeModelJson(_extractAnthropicContent(jsonData, label));
  }

  Future<Map<String, dynamic>> _postZhipuGlmImage(
    AppSettings settings,
    String base64Image,
    String prompt,
  ) async {
    final response = await _client
        .post(
          Uri.parse(AppConfig.zhipuGlmApiUrl),
          headers: _jsonHeaders(settings.apiKey),
          body: jsonEncode({
            'model': AppConfig.zhipuGlmVisionModel,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'image_url',
                    'image_url': {'url': base64Image},
                  },
                  {'type': 'text', 'text': prompt},
                ],
              },
            ],
            'thinking': {'type': 'disabled'},
          }),
        )
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Zhipu GLM API error: ${response.statusCode} - ${response.body}',
      );
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return _decodeModelJson(
      _extractChatCompletionContent(jsonData, 'Zhipu GLM'),
    );
  }

  Map<String, String> _jsonHeaders(
    String apiKey, {
    bool useAzureApiKeyHeader = false,
  }) {
    final key = _requireNonEmpty(apiKey, 'API key');
    return {
      'Content-Type': 'application/json',
      if (useAzureApiKeyHeader) 'api-key': key else 'Authorization': 'Bearer $key',
    };
  }

  Uri _buildAzureChatCompletionsUri(AppSettings settings) {
    final endpoint = _requireNonEmpty(settings.azureEndpoint, 'Azure endpoint');
    final deployment =
        _requireNonEmpty(settings.azureDeployment, 'Azure deployment');
    final apiVersion =
        _requireNonEmpty(settings.azureApiVersion, 'Azure API version');
    final base = endpoint.endsWith('/')
        ? endpoint.substring(0, endpoint.length - 1)
        : endpoint;
    return Uri.parse(
      '$base/openai/deployments/${Uri.encodeComponent(deployment)}/chat/completions?api-version=${Uri.encodeQueryComponent(apiVersion)}',
    );
  }

  Uri _appendEndpoint(String baseUrl, String suffix) {
    final trimmed =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    if (trimmed.endsWith(suffix)) {
      return Uri.parse(trimmed);
    }
    return Uri.parse('$trimmed/$suffix');
  }

  String _extractChatCompletionContent(
    Map<String, dynamic> jsonData,
    String label,
  ) {
    try {
      final choices = jsonData['choices'] as List<dynamic>;
      final firstChoice = choices.first as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>;
      final content = message['content'];
      if (content is String) {
        return content;
      }
    } catch (_) {
      // Throw the explicit exception below.
    }
    throw Exception('$label response missing choices[0].message.content');
  }

  String _extractAnthropicContent(
    Map<String, dynamic> jsonData,
    String label,
  ) {
    try {
      final content = jsonData['content'] as List<dynamic>;
      final firstText = content.firstWhere(
        (item) => item is Map<String, dynamic> && item['type'] == 'text',
      ) as Map<String, dynamic>;
      final text = firstText['text'];
      if (text is String) {
        return text;
      }
    } catch (_) {
      // Throw the explicit exception below.
    }
    throw Exception('$label response missing content text');
  }

  Map<String, dynamic> _decodeModelJson(String content) {
    final trimmed = content.trim();
    try {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      final fencedJson = RegExp(
        r'```(?:json)?\s*([\s\S]*?)\s*```',
        multiLine: true,
      ).firstMatch(trimmed);
      if (fencedJson != null) {
        try {
          return jsonDecode(fencedJson.group(1)!.trim())
              as Map<String, dynamic>;
        } catch (_) {
          // Throw the explicit exception below.
        }
      }
    }
    throw Exception('Model response content is not valid JSON');
  }

  String _requireNonEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw Exception('$name is required');
    }
    return value.trim();
  }

  static const String _shootingAdvicePrompt = '''
You are a professional photography assistant. Analyze the camera frame and return only valid JSON with this exact shape:
{
  "shooting_advice": "one concise composition, lighting, or angle suggestion",
  "camera_params": {
    "iso": "recommended ISO",
    "exposure": "recommended exposure compensation",
    "focus": "recommended focus mode",
    "white_balance": "recommended white balance"
  },
  "filter_suggestions": ["2-3 suitable filter names"]
}
Return all text values in Chinese (Simplified Chinese). Keep JSON keys exactly as shown.
Do not include post-processing or edit parameters.
Do not wrap the JSON in markdown.
''';

  static const String _editSuggestionPrompt = '''
You are a professional photo editor. Analyze this saved photo and return only valid JSON with this exact shape:
{
  "filter_suggestions": ["2-3 suitable filter names"],
  "edit_params": {
    "brightness": "post-processing brightness adjustment",
    "contrast": "post-processing contrast adjustment",
    "saturation": "post-processing saturation adjustment",
    "sharpness": "post-processing sharpness adjustment"
  }
}
Return all text values in Chinese (Simplified Chinese). Keep JSON keys exactly as shown.
Do not include shooting advice or camera capture parameters.
Do not wrap the JSON in markdown.
''';

  void dispose() {
    _client.close();
  }
}
