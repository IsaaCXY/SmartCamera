/// Core configuration for the application.
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8000/api';
  static const Duration apiTimeout = Duration(seconds: 10);
  static const String zhipuGlmApiUrl =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  static const String zhipuGlmVisionModel = 'glm-4.5v';

  // Camera Configuration
  static const Duration analysisCooldown = Duration(seconds: 3);

  // Stability Detection Configuration
  static const double stabilityAlpha = 0.3; // EMA smoothing factor
  static const double stabilityThreshold = 0.8; // Stability threshold
  static const double stableFrameDiffThreshold = 0.08;
  static const double motionFrameDiffThreshold = 0.12;
  static const int requiredStableFrames = 3;
  static const double movingScoreCap = 0.50;
  static const double borderlineScoreCap = 0.75;

  // Scene Change Detection Configuration
  static const int sceneChangeWindowSize = 10; // Window size for sliding window
  static const double sceneChangeThreshold = 0.3; // Change threshold
  static const double sceneChangeTrigger = 0.4; // Trigger analysis threshold

  // Image Configuration
  static const int analysisImageWidth = 640;
  static const int analysisImageHeight = 480;
  static const int analysisImageQuality = 80;

  // Photo Storage Configuration
  static const int thumbnailSize = 200;
  static const int thumbnailQuality = 85;
  static const String photosDirName = 'photos';
  static const String thumbnailsDirName = 'thumbnails';
  static const String metadataFileName = 'metadata.json';
  static const String photoIdPrefix = 'photo';
}
