import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_cam/features/settings/domain/app_settings.dart';
import 'package:smart_cam/features/analysis/data/analysis_api_repository.dart';

void main() {
  group('AnalysisApiRepository direct providers', () {
    test('sends realtime analysis request to OpenAI without edit params',
        () async {
      late http.BaseRequest capturedRequest;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedRequest = request;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'shooting_advice': '靠近主体',
                    'camera_params': {'iso': '100'},
                    'filter_suggestions': ['自然'],
                  }),
                },
              },
            ],
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final repository = AnalysisApiRepository(
        client: client,
        settingsProvider: () => AppSettings(
          selectedProvider: 'openai',
          apiKey: 'openai-key',
        ),
      );

      final result = await repository.analyzeImage(Uint8List.fromList([1, 2]));

      expect(capturedRequest.url.toString(),
          'https://api.openai.com/v1/chat/completions');
      expect(capturedRequest.headers['Authorization'], 'Bearer openai-key');
      expect(capturedBody['model'], 'gpt-4.1-mini');

      final content = capturedBody['messages'].first['content'] as List;
      expect(content.first['text'], contains('shooting_advice'));
      expect(content.first['text'], isNot(contains('edit_params')));
      expect(content.last['image_url']['url'],
          'data:image/jpeg;base64,${base64Encode([1, 2])}');
      expect(result.shootingAdvice, '靠近主体');
      expect(result.editParams, isEmpty);
    });

    test('requests edit suggestions separately from realtime analysis',
        () async {
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'filter_suggestions': ['胶片'],
                    'edit_params': {'brightness': '+5'},
                  }),
                },
              },
            ],
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final repository = AnalysisApiRepository(
        client: client,
        settingsProvider: () => AppSettings(
          selectedProvider: 'openai',
          apiKey: 'openai-key',
        ),
      );

      final suggestion =
          await repository.suggestEditsForPhoto(Uint8List.fromList([1, 2]));

      final content = capturedBody['messages'].first['content'] as List;
      expect(content.first['text'], contains('edit_params'));
      expect(content.first['text'], isNot(contains('shooting_advice')));
      expect(suggestion.filterSuggestions, ['胶片']);
      expect(suggestion.editParams['brightness'], '+5');
    });

    test('sends Anthropic vision request with base64 image source', () async {
      late http.BaseRequest capturedRequest;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedRequest = request;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'content': [
              {
                'type': 'text',
                'text': jsonEncode({
                  'shooting_advice': '保持水平',
                  'camera_params': {'focus': 'auto'},
                  'filter_suggestions': ['自然'],
                }),
              },
            ],
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final repository = AnalysisApiRepository(
        client: client,
        settingsProvider: () => AppSettings(
          selectedProvider: 'anthropic',
          apiKey: 'anthropic-key',
        ),
      );

      final result = await repository.analyzeImage(Uint8List.fromList([3, 4]));

      expect(capturedRequest.url.toString(),
          'https://api.anthropic.com/v1/messages');
      expect(capturedRequest.headers['x-api-key'], 'anthropic-key');
      expect(capturedRequest.headers['anthropic-version'], '2023-06-01');
      expect(capturedBody['model'], 'claude-sonnet-4-20250514');

      final content = capturedBody['messages'].first['content'] as List;
      expect(content.first['type'], 'image');
      expect(content.first['source']['data'], base64Encode([3, 4]));
      expect(content.last['text'], isNot(contains('edit_params')));
      expect(result.shootingAdvice, '保持水平');
    });

    test('sends Azure OpenAI request with deployment endpoint', () async {
      late http.BaseRequest capturedRequest;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedRequest = request;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'shooting_advice': '降低曝光',
                    'camera_params': {'exposure': '-0.3'},
                    'filter_suggestions': ['冷色'],
                  }),
                },
              },
            ],
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final repository = AnalysisApiRepository(
        client: client,
        settingsProvider: () => AppSettings(
          selectedProvider: 'azure',
          apiKey: 'azure-key',
          azureEndpoint: 'https://example.openai.azure.com',
          azureDeployment: 'vision-deployment',
          azureApiVersion: '2024-02-15-preview',
        ),
      );

      await repository.analyzeImage(Uint8List.fromList([5, 6]));

      expect(
        capturedRequest.url.toString(),
        'https://example.openai.azure.com/openai/deployments/vision-deployment/chat/completions?api-version=2024-02-15-preview',
      );
      expect(capturedRequest.headers['api-key'], 'azure-key');
      expect(capturedBody['model'], 'vision-deployment');
    });

    test('sends custom OpenAI-compatible request to configured endpoint',
        () async {
      late http.BaseRequest capturedRequest;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedRequest = request;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'shooting_advice': '靠近一点',
                    'camera_params': {'iso': '200'},
                    'filter_suggestions': ['鲜明'],
                  }),
                },
              },
            ],
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final repository = AnalysisApiRepository(
        client: client,
        settingsProvider: () => AppSettings(
          selectedProvider: 'custom',
          apiKey: 'custom-key',
          customBaseUrl: 'https://custom.example/v1',
          customUrlType: 'openai',
          customModel: 'custom-vision',
        ),
      );

      await repository.analyzeImage(Uint8List.fromList([7, 8]));

      expect(capturedRequest.url.toString(),
          'https://custom.example/v1/chat/completions');
      expect(capturedRequest.headers['Authorization'], 'Bearer custom-key');
      expect(capturedBody['model'], 'custom-vision');
    });
  });

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
      expect(content.last['text'], isNot(contains('edit_params')));
      expect(content.last['text'], contains('Return all text values in Chinese'));

      expect(result.shootingAdvice, 'Move closer to the subject');
      expect(result.cameraParams['iso'], '100');
      expect(result.filterSuggestions, ['Natural']);
      expect(result.editParams, isEmpty);
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
