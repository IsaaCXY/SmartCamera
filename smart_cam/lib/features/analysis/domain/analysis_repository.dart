// Repository interface for analysis operations.
import 'dart:typed_data';
import '../domain/analysis_result.dart';

abstract class AnalysisRepository {
  /// Analyze image and return AI suggestions.
  Future<AnalysisResult> analyzeImage(Uint8List imageData);
}
