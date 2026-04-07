/// Stability detection engine using Exponential Moving Average (EMA).
/// Provides smooth stability scores that don't jump abruptly.
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/logger.dart';

class StabilityEngine {
  double _confidence = 0.0;

  /// Update stability score based on frame difference.
  /// Returns current stability (0.0 - 1.0).
  ///
  /// Higher frame difference = lower stability
  /// Uses EMA smoothing to prevent sudden jumps
  double update(double frameDifference) {
    // Validate input
    if (frameDifference < 0 || frameDifference > 1) {
      AppLogger.w('Invalid frame difference: $frameDifference', 'StabilityEngine');
      return _confidence;
    }

    // Convert frame difference to instant stability
    // Lower difference = higher stability
    double instantStability = 1.0 - frameDifference;

    // Apply EMA smoothing
    // new_confidence = (α × new_value) + ((1-α) × old_confidence)
    _confidence = (AppConfig.stabilityAlpha * instantStability) +
                  ((1 - AppConfig.stabilityAlpha) * _confidence);

    AppLogger.d('Stability: ${_confidence.toStringAsFixed(3)} (diff: ${frameDifference.toStringAsFixed(3)})', 'StabilityEngine');
    return _confidence;
  }

  /// Current stability score (0.0 - 1.0)
  double get score => _confidence;

  /// Whether the scene is currently stable
  bool get isStable => _confidence > AppConfig.stabilityThreshold;

  /// Reset stability tracking
  void reset() {
    _confidence = 0.0;
    AppLogger.d('Stability reset', 'StabilityEngine');
  }
}
