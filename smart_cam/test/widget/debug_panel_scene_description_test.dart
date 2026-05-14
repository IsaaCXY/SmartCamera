import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_cam/features/analysis/domain/analysis_repository.dart';
import 'package:smart_cam/features/analysis/domain/analysis_result.dart';
import 'package:smart_cam/features/analysis/domain/edit_suggestion.dart';
import 'package:smart_cam/features/analysis/presentation/analysis_coordinator.dart';
import 'package:smart_cam/features/analysis/presentation/analysis_service.dart';
import 'package:smart_cam/features/camera/presentation/camera_service.dart';
import 'package:smart_cam/features/camera/presentation/pages/camera_page.dart';
import 'package:smart_cam/features/photo/presentation/photo_storage_service.dart';
import 'package:smart_cam/features/settings/presentation/settings_service.dart';

class _FakeAnalysisRepository implements AnalysisRepository {
  @override
  Future<AnalysisResult> analyzeImage(Uint8List imageData) async {
    return AnalysisResult(
      sceneDescription: '桌面上有一杯咖啡和一本打开的书',
      shootingAdvice: '靠近主体',
      cameraParams: const {'iso': '100'},
      filterSuggestions: const ['自然'],
      editParams: const {},
    );
  }

  @override
  Future<EditSuggestion> suggestEditsForPhoto(Uint8List imageData) async {
    return const EditSuggestion(
      filterSuggestions: ['自然'],
      editParams: {'brightness': '+5'},
    );
  }
}

void main() {
  testWidgets('debug panel shows scene description after analysis',
      (tester) async {
    final cameraService = CameraService();
    final analysisService = AnalysisService(
      repository: _FakeAnalysisRepository(),
    );
    await analysisService.analyzeIfReady(Uint8List.fromList([1]));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CameraService>.value(value: cameraService),
          ChangeNotifierProvider<AnalysisService>.value(
            value: analysisService,
          ),
          ChangeNotifierProvider<AnalysisCoordinator>(
            create: (_) => AnalysisCoordinator(cameraService: cameraService),
          ),
          ChangeNotifierProvider<SettingsService>(
            create: (_) => SettingsService(),
          ),
          ChangeNotifierProvider<PhotoStorageService>(
            create: (_) => PhotoStorageService(),
          ),
        ],
        child: const MaterialApp(
          home: CameraPage(),
        ),
      ),
    );

    expect(find.textContaining('画面描述: 桌面上有一杯咖啡和一本打开的书'), findsOneWidget);
  });
}
