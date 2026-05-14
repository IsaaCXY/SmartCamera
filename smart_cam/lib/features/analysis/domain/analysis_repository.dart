// Repository interface for analysis operations.
import 'dart:typed_data';
import '../domain/analysis_result.dart';
import '../domain/edit_suggestion.dart';

abstract class AnalysisRepository {
  /// Analyze image and return AI suggestions.
  Future<AnalysisResult> analyzeImage(Uint8List imageData);

  /// Analyze a saved photo and return post-processing suggestions.
  Future<EditSuggestion> suggestEditsForPhoto(Uint8List imageData);
}
