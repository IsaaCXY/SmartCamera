/// Service for analyzing camera frames and providing AI suggestions.
/// Handles API calls and analysis results.
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

  AnalysisService({required AnalysisRepository repository})
      : _repository = repository;

  /// Current analysis result (null if not analyzed yet).
  AnalysisResult? get currentResult => _currentResult;

  /// Whether analysis is currently in progress.
  bool get isAnalyzing => _isAnalyzing;

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
}
