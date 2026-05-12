import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/utils/logger.dart';
import '../domain/analysis_result.dart';
import '../domain/analysis_repository.dart';

class AnalysisApiRepository implements AnalysisRepository {
  final http.Client _client;
  final String apiKey;
  final String provider; // 'openai', 'anthropic', 'azure', etc.

  AnalysisApiRepository({
    http.Client? client,
    required this.apiKey,
    this.provider = 'openai',
  }) : _client = client ?? http.Client();

  @override
  Future<AnalysisResult> analyzeImage(Uint8List imageData) async {
    AppLogger.i('Analyzing image with provider: $provider', 'AnalysisApi');

    try {
      final String base64Image = base64Encode(imageData);

      if (provider == 'zhipu_glm') {
        return await _analyzeWithZhipuGlm(base64Image);
      }

      final Map<String, dynamic> requestBody = _buildRequest(base64Image);
      final response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/analyze'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
              'X-Provider': provider,
            },
            body: jsonEncode(requestBody),
          )
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final result = AnalysisResult.fromJson(jsonData);
        AppLogger.i(
            'Analysis complete: ${result.shootingAdvice}', 'AnalysisApi');
        return result;
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.e('Analysis failed', 'AnalysisApi', e);
      rethrow;
    }
  }

  Future<AnalysisResult> _analyzeWithZhipuGlm(String base64Image) async {
    final response = await _client
        .post(
          Uri.parse(AppConfig.zhipuGlmApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(_buildZhipuGlmRequest(base64Image)),
        )
        .timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception(
          'Zhipu GLM API error: ${response.statusCode} - ${response.body}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractZhipuMessageContent(jsonData);
    final resultJson = _decodeModelJson(content);
    final result = AnalysisResult.fromJson(resultJson);
    AppLogger.i(
        'Zhipu GLM analysis complete: ${result.shootingAdvice}', 'AnalysisApi');
    return result;
  }

  /// Build request body based on provider type.
  Map<String, dynamic> _buildRequest(String base64Image) {
    return {
      'image': base64Image,
      'task': 'camera_advice',
      'return_format': {
        'shooting_advice': 'string',
        'camera_params': 'object',
        'filter_suggestions': 'array',
        'edit_params': 'object',
      },
    };
  }

  Map<String, dynamic> _buildZhipuGlmRequest(String base64Image) {
    return {
      'model': AppConfig.zhipuGlmVisionModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {'url': base64Image},
            },
            {
              'type': 'text',
              'text': _zhipuGlmPrompt,
            },
          ],
        },
      ],
      'thinking': {'type': 'disabled'},
    };
  }

  String _extractZhipuMessageContent(Map<String, dynamic> jsonData) {
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
    throw Exception('Zhipu GLM response missing choices[0].message.content');
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
    throw Exception('Zhipu GLM response content is not valid JSON');
  }

  static const String _zhipuGlmPrompt = '''
You are a professional photography assistant. Analyze the camera frame and return only valid JSON with this exact shape:
{
  "shooting_advice": "one concise composition, lighting, or angle suggestion",
  "camera_params": {
    "iso": "recommended ISO",
    "exposure": "recommended exposure compensation",
    "focus": "recommended focus mode",
    "white_balance": "recommended white balance"
  },
  "filter_suggestions": ["2-3 suitable filter names"],
  "edit_params": {
    "brightness": "post-processing brightness adjustment",
    "contrast": "post-processing contrast adjustment",
    "saturation": "post-processing saturation adjustment",
    "sharpness": "post-processing sharpness adjustment"
  }
}
Return all text values in Chinese (Simplified Chinese). Keep JSON keys exactly as shown.
Do not wrap the JSON in markdown.
''';

  void dispose() {
    _client.close();
  }
}
