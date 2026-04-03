/// Service for analyzing camera frames and providing AI suggestions.
/// Handles stability detection and throttling of API calls.
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/logger.dart';
import '../domain/analysis_result.dart';
import '../domain/analysis_repository.dart';

class AnalysisService extends ChangeNotifier {
  final AnalysisRepository _repository;

  AnalysisResult? _currentResult;
  bool _isAnalyzing = false;
  DateTime? _lastAnalysisTime;
  Timer? _stabilityTimer;
  
  // Stability detection state
  List<double> _frameDifferences = [];

  AnalysisService({required AnalysisRepository repository})
      : _repository = repository;

  /// Current analysis result (null if not analyzed yet).
  AnalysisResult? get currentResult => _currentResult;

  /// Whether analysis is currently in progress.
  bool get isAnalyzing => _isAnalyzing;

  /// Check if scene is stable enough for analysis.
  /// Returns true if the scene has been stable for N frames.
  bool checkStability(double currentDifference) {
    _frameDifferences.add(currentDifference);
    
    // Keep only last N frames
    if (_frameDifferences.length > AppConfig.stabilityCheckFrames) {
      _frameDifferences.removeAt(0);
    }

    // Need at least N frames to determine stability
    if (_frameDifferences.length < AppConfig.stabilityCheckFrames) {
      return false;
    }

    // Calculate average difference
    final avgDifference = _frameDifferences.reduce((a, b) => a + b) / 
        _frameDifferences.length;

    // Stable if average difference is below threshold
    final isStable = avgDifference < (1 - AppConfig.minStabilityThreshold);
    
    AppLogger.d('Stability check: avg=$avgDifference, stable=$isStable', 'AnalysisService');
    return isStable;
  }

  /// Reset stability tracking (call when scene changes significantly).
  void resetStability() {
    _frameDifferences.clear();
    AppLogger.d('Stability reset', 'AnalysisService');
  }

  /// Analyze current frame if conditions are met.
  /// Returns true if analysis was started.
  Future<bool> analyzeIfReady(Uint8List imageData) async {
    // Check cooldown
    if (_lastAnalysisTime != null) {
      final elapsed = DateTime.now().difference(_lastAnalysisTime!);
      if (elapsed < AppConfig.analysisCooldown) {
        AppLogger.d('Skipping analysis: cooldown active', 'AnalysisService');
        return false;
      }
    }

    // Check if already analyzing
    if (_isAnalyzing) {
      AppLogger.d('Skipping analysis: already in progress', 'AnalysisService');
      return false;
    }

    // Start analysis
    _isAnalyzing = true;
    notifyListeners();

    try {
      final result = await _repository.analyzeImage(imageData);
      _currentResult = result;
      _lastAnalysisTime = DateTime.now();
      
      AppLogger.i('Analysis completed successfully', 'AnalysisService');
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.e('Analysis failed', 'AnalysisService', e);
      return false;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Clear current analysis result.
  void clearResult() {
    _currentResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stabilityTimer?.cancel();
    super.dispose();
  }
}
