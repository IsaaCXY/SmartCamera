import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_cam/features/analysis/data/analysis_api_repository.dart';

void main() {
  group('AnalysisApiRepository zhipu_glm', () {
    test('sends image analysis request to Zhipu GLM vision endpoint', () async {
      late http.BaseRequest capturedRequest;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedRequest = request;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'shooting_advice': 'Move closer to the subject',
                    'camera_params': {'iso': '100'},
                    'filter_suggestions': ['Natural'],
                    'edit_params': {'brightness': '+5'},
                  }),
                },
              },
            ],
          }),
          200,
        );
      });

      final repository = AnalysisApiRepository(
        client: client,
        apiKey: 'test-api-key',
        provider: 'zhipu_glm',
      );

      final result = await repository.analyzeImage(Uint8List.fromList([1, 2]));

      expect(
        capturedRequest.url.toString(),
        'https://open.bigmodel.cn/api/paas/v4/chat/completions',
      );
      expect(capturedRequest.headers['Authorization'], 'Bearer test-api-key');
      expect(capturedBody['model'], 'glm-4.5v');

      final messages = capturedBody['messages'] as List<dynamic>;
      final content = messages.first['content'] as List<dynamic>;
      expect(content.first['type'], 'image_url');
      expect(content.first['image_url']['url'], base64Encode([1, 2]));
      expect(content.last['type'], 'text');
      expect(content.last['text'], contains('shooting_advice'));
      expect(content.last['text'], contains('edit_params'));
      expect(content.last['text'], contains('Return all text values in Chinese'));

      expect(result.shootingAdvice, 'Move closer to the subject');
      expect(result.cameraParams['iso'], '100');
      expect(result.filterSuggestions, ['Natural']);
      expect(result.editParams['brightness'], '+5');
    });

    test('throws when Zhipu GLM content is not valid JSON', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'not json'},
              },
            ],
          }),
          200,
        );
      });

      final repository = AnalysisApiRepository(
        client: client,
        apiKey: 'test-api-key',
        provider: 'zhipu_glm',
      );

      expect(
        () => repository.analyzeImage(Uint8List.fromList([1])),
        throwsA(isA<Exception>()),
      );
    });
  });
}
