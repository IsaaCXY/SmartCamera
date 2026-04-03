/// API service for communicating with AI backend.
/// Supports multiple LLM providers through configuration.
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
      // Convert image to base64
      final String base64Image = base64Encode(imageData);

      // Build request based on provider
      final Map<String, dynamic> requestBody = _buildRequest(base64Image);

      // Send request
      final response = await _client.post(
        Uri.parse('${AppConfig.apiBaseUrl}/analyze'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'X-Provider': provider,
        },
        body: jsonEncode(requestBody),
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final result = AnalysisResult.fromJson(jsonData);
        AppLogger.i('Analysis complete: ${result.shootingAdvice}', 'AnalysisApi');
        return result;
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.e('Analysis failed', 'AnalysisApi', e);
      rethrow;
    }
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

  void dispose() {
    _client.close();
  }
}
