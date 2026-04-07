/// Scene change detection using sliding window algorithm.
/// Detects meaningful content changes (scene, subject, pose changes).
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/logger.dart';

class SceneChangeDetector {
  final List<double> _window = [];
  double _currentScore = 0.0;

  /// Update scene change score based on frame difference.
  /// Returns scene change degree (0.0 - 1.0).
  ///
  /// Uses sliding window to average differences over time.
  /// Higher average difference = more scene change
  double update(double frameDifference) {
    // Validate input
    if (frameDifference.isNaN) {
      AppLogger.w('NaN frame difference, returning old score', 'SceneChangeDetector');
      return _currentScore;
    }

    if (frameDifference < 0 || frameDifference > 1) {
      AppLogger.w('Invalid frame difference: $frameDifference', 'SceneChangeDetector');
      return _currentScore;
    }

    // Add to sliding window
    _window.add(frameDifference);

    // Keep window size constant
    if (_window.length > AppConfig.sceneChangeWindowSize) {
      _window.removeAt(0);
    }

    // Need minimum samples for meaningful result
    if (_window.length < 3) {
      _currentScore = 0.0;
      return _currentScore;
    }

    // Calculate average difference over the window
    double avgDiff = _window.reduce((a, b) => a + b) / _window.length;

    // Scene change score = average difference / threshold
    // This normalizes the score: if avgDiff equals threshold, score = 1.0
    _currentScore = (avgDiff / AppConfig.sceneChangeThreshold).clamp(0.0, 1.0);

    AppLogger.d('Scene change: ${_currentScore.toStringAsFixed(3)} (avg: ${avgDiff.toStringAsFixed(3)})', 'SceneChangeDetector');
    return _currentScore;
  }

  /// Current scene change score (0.0 - 1.0)
  double get score => _currentScore;

  /// Whether a scene change has been detected
  bool get hasChanged => _currentScore > AppConfig.sceneChangeTrigger;

  /// Reset scene change tracking
  void reset() {
    _window.clear();
    _currentScore = 0.0;
    AppLogger.d('Scene change detector reset', 'SceneChangeDetector');
  }
}
