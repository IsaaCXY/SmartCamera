/// Analysis trigger that evaluates whether to analyze a frame.
/// Combines stability and scene change signals.
import 'stability_engine.dart';
import 'scene_change_detector.dart';
import '../../../../core/utils/logger.dart';

class AnalysisTrigger {
  final StabilityEngine _stability;
  final SceneChangeDetector _sceneChange;

  AnalysisTrigger({
    required StabilityEngine stability,
    required SceneChangeDetector sceneChange,
  })  : _stability = stability,
        _sceneChange = sceneChange;

  /// Whether analysis should be triggered.
  /// Analysis is triggered when:
  /// 1. Scene is stable (camera is steady)
  /// 2. Scene has changed (new content to analyze)
  bool get shouldAnalyze {
    final stable = _stability.isStable;
    final changed = _sceneChange.hasChanged;
    final result = stable && changed;

    if (result) {
      AppLogger.i('Analysis triggered: stable=$stable, changed=$changed', 'AnalysisTrigger');
    }

    return result;
  }

  /// Current stability score (0.0 - 1.0)
  double get stability => _stability.score;

  /// Current scene change score (0.0 - 1.0)
  double get sceneChange => _sceneChange.score;

  /// Whether the scene is currently stable
  bool get isStable => _stability.isStable;

  /// Whether a scene change has been detected
  bool get hasSceneChanged => _sceneChange.hasChanged;
}
