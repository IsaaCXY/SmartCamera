import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_cam/features/analysis/domain/analysis_repository.dart';
import 'package:smart_cam/features/analysis/domain/analysis_result.dart';
import 'package:smart_cam/features/analysis/domain/edit_suggestion.dart';
import 'package:smart_cam/features/analysis/presentation/analysis_service.dart';

class _FakeAnalysisRepository implements AnalysisRepository {
  _FakeAnalysisRepository(this._handler);

  final Future<AnalysisResult> Function(Uint8List imageData) _handler;

  @override
  Future<AnalysisResult> analyzeImage(Uint8List imageData) {
    return _handler(imageData);
  }

  @override
  Future<EditSuggestion> suggestEditsForPhoto(Uint8List imageData) async {
    return const EditSuggestion(
      filterSuggestions: ['Natural'],
      editParams: {'brightness': '+5'},
    );
  }
}

void main() {
  group('AnalysisService debug status', () {
    test('records analyzing and success result status', () async {
      final completer = Completer<AnalysisResult>();
      final service = AnalysisService(
        repository: _FakeAnalysisRepository((_) async {
          return completer.future;
        }),
      );
      final statuses = <AnalysisRunStatus>[];
      service.addListener(() => statuses.add(service.lastRunStatus));

      final future = service.analyzeIfReady(Uint8List.fromList([1]));
      await Future<void>.delayed(Duration.zero);

      expect(service.isAnalyzing, isTrue);
      expect(service.lastRunStatus, AnalysisRunStatus.analyzing);
      expect(statuses, contains(AnalysisRunStatus.analyzing));

      completer.complete(
        AnalysisResult(
          shootingAdvice: 'Use softer light',
          cameraParams: const {'iso': '100'},
          filterSuggestions: const ['Natural'],
          editParams: const {'brightness': '+5'},
        ),
      );

      final started = await future;

      expect(started, isTrue);
      expect(service.isAnalyzing, isFalse);
      expect(service.lastRunStatus, AnalysisRunStatus.success);
      expect(service.lastRunMessage, 'Use softer light');
      expect(service.lastErrorMessage, isNull);
    });

    test('records failed result status and error message', () async {
      final service = AnalysisService(
        repository: _FakeAnalysisRepository((_) async {
          throw Exception('network failed');
        }),
      );

      final started = await service.analyzeIfReady(Uint8List.fromList([1]));

      expect(started, isFalse);
      expect(service.isAnalyzing, isFalse);
      expect(service.lastRunStatus, AnalysisRunStatus.failed);
      expect(service.lastRunMessage, contains('network failed'));
      expect(service.lastErrorMessage, contains('network failed'));
    });

    test('manual analysis bypasses cooldown', () async {
      var requestCount = 0;
      final service = AnalysisService(
        repository: _FakeAnalysisRepository((_) async {
          requestCount += 1;
          return AnalysisResult(
            shootingAdvice: '保持水平',
            cameraParams: const {},
            filterSuggestions: const [],
            editParams: const {},
          );
        }),
      );

      expect(await service.analyzeIfReady(Uint8List.fromList([1])), isTrue);
      expect(await service.analyzeNow(Uint8List.fromList([2])), isTrue);

      expect(requestCount, 2);
    });
  });
}
