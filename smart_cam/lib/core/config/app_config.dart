/// Core configuration for the application.
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8000/api';
  static const Duration apiTimeout = Duration(seconds: 10);
  
  // Camera Configuration
  static const double minStabilityThreshold = 0.85;
  static const int stabilityCheckFrames = 5;
  static const Duration analysisCooldown = Duration(seconds: 3);
  
  // Image Configuration
  static const int analysisImageWidth = 640;
  static const int analysisImageHeight = 480;
  static const int analysisImageQuality = 80;
}
