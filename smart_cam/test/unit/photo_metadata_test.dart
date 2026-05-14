import 'package:flutter_test/flutter_test.dart';
import 'package:smart_cam/features/analysis/domain/analysis_result.dart';
import 'package:smart_cam/features/analysis/domain/edit_suggestion.dart';
import 'package:smart_cam/features/photo/domain/photo_metadata.dart';

void main() {
  test('stores realtime analysis separately from edit suggestions', () {
    final photo = PhotoMetadata(
      id: 'photo_1',
      originalPath: '/tmp/photo.jpg',
      thumbnailPath: '/tmp/thumb.jpg',
      capturedAt: DateTime.parse('2026-05-12T10:00:00Z'),
      analysisResult: AnalysisResult(
        sceneDescription: '桌面上有一杯咖啡和一本书',
        shootingAdvice: '靠近主体',
        cameraParams: {'iso': '100'},
        filterSuggestions: ['自然'],
        editParams: const {},
      ),
      editSuggestion: const EditSuggestion(
        filterSuggestions: ['胶片'],
        editParams: {'brightness': '+5'},
      ),
    );

    final restored = PhotoMetadata.fromJson(photo.toJson());

    expect(restored.analysisResult!.sceneDescription, '桌面上有一杯咖啡和一本书');
    expect(restored.analysisResult!.editParams, isEmpty);
    expect(restored.editSuggestion!.filterSuggestions, ['胶片']);
    expect(restored.editSuggestion!.editParams['brightness'], '+5');
  });

  test('loads legacy photos without edit suggestions', () {
    final restored = PhotoMetadata.fromJson({
      'id': 'photo_legacy',
      'originalPath': '/tmp/photo.jpg',
      'thumbnailPath': '/tmp/thumb.jpg',
      'capturedAt': '2026-05-12T10:00:00Z',
      'analysisResult': {
        'scene_description': '一条街道和远处建筑',
        'shooting_advice': '保持水平',
        'camera_params': <String, dynamic>{},
        'filter_suggestions': <String>[],
      },
    });

    expect(restored.editSuggestion, isNull);
    expect(restored.analysisResult!.sceneDescription, '一条街道和远处建筑');
    expect(restored.analysisResult!.editParams, isEmpty);
  });
}
