/// Coordinator for frame analysis workflow.
/// Orchestrates stability detection, scene change detection, and analysis triggering.
library;

import 'package:flutter/foundation.dart';
import '../../camera/presentation/camera_service.dart';
import 'stability/stability_engine.dart';
import 'stability/scene_change_detector.dart';
import 'stability/analysis_trigger.dart';
import '../../../../core/utils/logger.dart';

class AnalysisCoordinator extends ChangeNotifier {
  final StabilityEngine _stability;
  final SceneChangeDetector _sceneChange;
  final AnalysisTrigger _trigger;
  final CameraService _cameraService;

  Uint8List? _previousFrame;

  AnalysisCoordinator({
    required CameraService cameraService,
  })   : _stability = StabilityEngine(),
        _sceneChange = SceneChangeDetector(),
        _trigger = AnalysisTrigger(
          stability: StabilityEngine(),
          sceneChange: SceneChangeDetector(),
        ),
        _cameraService = cameraService {
    AppLogger.i('AnalysisCoordinator initialized', 'AnalysisCoordinator');
  }

  /// Process a new frame from the camera.
  /// Calculates frame difference and updates stability/scene change detectors.
  Future<void> processFrame(Uint8List currentFrame) async {
    double difference = 1.0;

    // Calculate difference with previous frame
    if (_previousFrame != null) {
      try {
        difference = _cameraService.calculateFrameDifference(
          currentFrame,
          _previousFrame!,
        );
      } catch (e) {
        AppLogger.e('Failed to calculate frame difference', 'AnalysisCoordinator', e);
        difference = 1.0; // Assume maximum difference on error
      }
    }

    // Update stability engine
    try {
      _stability.update(difference);
    } catch (e) {
      AppLogger.e('Failed to update stability', 'AnalysisCoordinator', e);
    }

    // Update scene change detector
    try {
      _sceneChange.update(difference);
    } catch (e) {
      AppLogger.e('Failed to update scene change detector', 'AnalysisCoordinator', e);
    }

    // Store current frame for next comparison
    _previousFrame = currentFrame;

    // Notify listeners of state changes
    notifyListeners();
  }

  /// Current stability score (0.0 - 1.0)
  double get stability => _stability.score;

  /// Current scene change score (0.0 - 1.0)
  double get sceneChange => _sceneChange.score;

  /// Whether the scene is currently stable
  bool get isStable => _trigger.isStable;

  /// Whether analysis should be triggered
  bool get shouldAnalyze => _trigger.shouldAnalyze;

  /// Reset all tracking state
  void reset() {
    _stability.reset();
    _sceneChange.reset();
    _previousFrame = null;
    AppLogger.d('AnalysisCoordinator reset', 'AnalysisCoordinator');
    notifyListeners();
  }

  @override
  void dispose() {
    _previousFrame = null;
    super.dispose();
  }
}
