// Service for analyzing camera frames and providing AI suggestions.
// Handles API calls and analysis results.
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/logger.dart';
import '../domain/analysis_result.dart';
import '../domain/analysis_repository.dart';

enum AnalysisRunStatus {
  idle,
  analyzing,
  success,
  failed,
}

class AnalysisService extends ChangeNotifier {
  final AnalysisRepository _repository;

  AnalysisResult? _currentResult;
  bool _isAnalyzing = false;
  DateTime? _lastAnalysisTime;
  AnalysisRunStatus _lastRunStatus = AnalysisRunStatus.idle;
  String? _lastRunMessage;
  String? _lastErrorMessage;

  AnalysisService({required AnalysisRepository repository})
      : _repository = repository;

  /// Current analysis result (null if not analyzed yet).
  AnalysisResult? get currentResult => _currentResult;

  /// Whether analysis is currently in progress.
  bool get isAnalyzing => _isAnalyzing;

  AnalysisRunStatus get lastRunStatus => _lastRunStatus;

  String? get lastRunMessage => _lastRunMessage;

  String? get lastErrorMessage => _lastErrorMessage;

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
    _lastRunStatus = AnalysisRunStatus.analyzing;
    _lastRunMessage = '检测中';
    _lastErrorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.analyzeImage(imageData);
      _currentResult = result;
      _lastAnalysisTime = DateTime.now();
      _lastRunStatus = AnalysisRunStatus.success;
      _lastRunMessage =
          result.shootingAdvice.isEmpty ? '检测成功' : result.shootingAdvice;
      _lastErrorMessage = null;

      AppLogger.i('Analysis completed successfully', 'AnalysisService');
      notifyListeners();
      return true;
    } catch (e) {
      _lastRunStatus = AnalysisRunStatus.failed;
      _lastRunMessage = e.toString();
      _lastErrorMessage = e.toString();
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
    _lastRunStatus = AnalysisRunStatus.idle;
    _lastRunMessage = null;
    _lastErrorMessage = null;
    notifyListeners();
  }
}
