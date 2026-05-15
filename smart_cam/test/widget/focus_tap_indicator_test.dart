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
  int requestCount = 0;

  @override
  Future<AnalysisResult> analyzeImage(Uint8List imageData) async {
    requestCount += 1;
    return AnalysisResult(
      shootingAdvice: '保持水平',
      cameraParams: const {},
      filterSuggestions: const [],
      editParams: const {},
    );
  }

  @override
  Future<EditSuggestion> suggestEditsForPhoto(Uint8List imageData) async {
    return const EditSuggestion(
      filterSuggestions: [],
      editParams: {},
    );
  }
}

void main() {
  testWidgets('focus tap indicator renders around the tapped point',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: Stack(
              children: [
                FocusTapIndicator(
                  position: Offset(200, 300),
                  previewSize: Size(400, 600),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('focus_tap_indicator')), findsOneWidget);
    final topLeft = tester.getTopLeft(
      find.byKey(const Key('focus_tap_indicator')),
    );
    expect(topLeft.dx, 164);
    expect(topLeft.dy, 264);
  });

  testWidgets('tapping camera preview shows focus feedback box',
      (tester) async {
    final cameraService = CameraService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CameraService>.value(value: cameraService),
          ChangeNotifierProvider<AnalysisService>(
            create: (_) => AnalysisService(
              repository: _FakeAnalysisRepository(),
            ),
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

    await tester.tapAt(const Offset(200, 300));
    await tester.pump();

    expect(find.byKey(const Key('focus_tap_indicator')), findsOneWidget);
  });

  testWidgets(
      'long pressing shutter manually triggers analysis with neon border',
      (tester) async {
    final cameraService = _ManualAnalysisCameraService();
    final analysisRepository = _FakeAnalysisRepository();
    final settingsService = SettingsService()
      ..toggleManualAnalysisTrigger(true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CameraService>.value(value: cameraService),
          ChangeNotifierProvider<AnalysisService>(
            create: (_) => AnalysisService(
              repository: analysisRepository,
            ),
          ),
          ChangeNotifierProvider<AnalysisCoordinator>(
            create: (_) => AnalysisCoordinator(cameraService: cameraService),
          ),
          ChangeNotifierProvider<SettingsService>.value(value: settingsService),
          ChangeNotifierProvider<PhotoStorageService>(
            create: (_) => PhotoStorageService(),
          ),
        ],
        child: const MaterialApp(
          home: CameraPage(),
        ),
      ),
    );

    await tester.longPress(find.byIcon(Icons.camera_alt));
    await tester.pump(const Duration(milliseconds: 100));

    expect(analysisRepository.requestCount, 1);
    expect(
        find.byKey(const Key('manual_analysis_neon_border')), findsOneWidget);
  });
}

class _ManualAnalysisCameraService extends CameraService {
  @override
  Future<Uint8List?> captureFrameForAnalysis() async {
    return Uint8List.fromList([1, 2, 3]);
  }
}
