import 'dart:math' as math;

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/logger.dart';

class StabilityEngine {
  double _score = 0.0;
  int _stableFrameCount = 0;

  /// Update stability score based on frame difference.
  /// Returns current stability (0.0 - 1.0).
  double update(double frameDifference) {
    if (frameDifference.isNaN || frameDifference < 0 || frameDifference > 1) {
      AppLogger.w(
          'Invalid frame difference: $frameDifference', 'StabilityEngine');
      return _score;
    }

    if (frameDifference >= AppConfig.motionFrameDiffThreshold) {
      _stableFrameCount = 0;
      _score = math.min(_score, AppConfig.movingScoreCap);
    } else if (frameDifference <= AppConfig.stableFrameDiffThreshold) {
      _stableFrameCount++;
      final stableProgress = _stableFrameCount / AppConfig.requiredStableFrames;
      _score = math.max(_score, stableProgress.clamp(0.0, 1.0));
    } else {
      _stableFrameCount = 0;
      _score = math.min(_score, AppConfig.borderlineScoreCap);
    }

    AppLogger.d(
      'Stability: ${_score.toStringAsFixed(3)} '
          '(diff: ${frameDifference.toStringAsFixed(3)}, stableFrames: $_stableFrameCount)',
      'StabilityEngine',
    );
    return _score;
  }

  /// Current stability score (0.0 - 1.0)
  double get score => _score;

  /// Whether the scene is currently stable
  bool get isStable =>
      _stableFrameCount >= AppConfig.requiredStableFrames &&
      _score >= AppConfig.stabilityThreshold;

  /// Reset stability tracking
  void reset() {
    _score = 0.0;
    _stableFrameCount = 0;
    AppLogger.d('Stability reset', 'StabilityEngine');
  }
}
