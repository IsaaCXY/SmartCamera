import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_cam/features/settings/presentation/settings_service.dart';

void main() {
  group('SettingsService', () {
    test('tests zhipu_glm connection with a real chat completion request',
        () async {
      SharedPreferences.setMockInitialValues({});

      late http.Request capturedRequest;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedRequest = request;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'OK'},
              },
            ],
          }),
          200,
        );
      });

      final service = SettingsService(client: client);
      expect(service.apiValidationStatus, ApiValidationStatus.notConfigured);

      service.setProvider('zhipu_glm');
      service.setApiKey('test-api-key');
      expect(service.apiValidationStatus, ApiValidationStatus.unverified);

      final result = await service.testConnection();

      expect(result['success'], isTrue);
      expect(result['message'], '智谱 GLM connection successful');
      expect(service.apiValidationStatus, ApiValidationStatus.valid);
      expect(service.apiValidationMessage, '智谱 GLM connection successful');
      expect(
        capturedRequest.url.toString(),
        'https://open.bigmodel.cn/api/paas/v4/chat/completions',
      );
      expect(capturedRequest.headers['Authorization'], 'Bearer test-api-key');
      expect(capturedBody['model'], 'glm-4.5v');
      expect(capturedBody['messages'].first['content'].first['text'],
          contains('OK'));
    });

    test('records invalid api status when connection test fails', () async {
      SharedPreferences.setMockInitialValues({});

      final client = MockClient((request) async {
        return http.Response('unauthorized', 401);
      });

      final service = SettingsService(client: client);
      service.setProvider('zhipu_glm');
      service.setApiKey('test-api-key');

      final result = await service.testConnection();

      expect(result['success'], isFalse);
      expect(service.apiValidationStatus, ApiValidationStatus.invalid);
      expect(service.apiValidationMessage, contains('401'));
    });

    test('tests openai connection with real chat completion request', () async {
      SharedPreferences.setMockInitialValues({});

      late http.Request capturedRequest;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((request) async {
        capturedRequest = request;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'OK'},
              },
            ],
          }),
          200,
        );
      });

      final service = SettingsService(client: client);
      service.setProvider('openai');
      service.setApiKey('openai-key');

      final result = await service.testConnection();

      expect(result['success'], isTrue);
      expect(result['message'], 'OpenAI connection successful');
      expect(
        capturedRequest.url.toString(),
        'https://api.openai.com/v1/chat/completions',
      );
      expect(capturedRequest.headers['Authorization'], 'Bearer openai-key');
      expect(capturedBody['model'], 'gpt-4.1-mini');
    });

    test('requires azure endpoint and deployment before testing connection',
        () async {
      SharedPreferences.setMockInitialValues({});

      final service = SettingsService(client: MockClient((request) async {
        fail('Azure request should not be sent when config is missing');
      }));
      service.setProvider('azure');
      service.setApiKey('azure-key');

      final result = await service.testConnection();

      expect(result['success'], isFalse);
      expect(result['message'], contains('Azure endpoint is required'));
      expect(service.apiValidationStatus, ApiValidationStatus.invalid);
    });

    test('toggles manual analysis trigger setting', () {
      SharedPreferences.setMockInitialValues({});

      final service = SettingsService();

      expect(service.settings.manualAnalysisTrigger, isFalse);
      service.toggleManualAnalysisTrigger(true);
      expect(service.settings.manualAnalysisTrigger, isTrue);
    });
  });
}
