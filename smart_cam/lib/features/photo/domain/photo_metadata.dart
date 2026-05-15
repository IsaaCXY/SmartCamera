// Photo metadata model for storing photo information and AI analysis results.
import '../../analysis/domain/analysis_result.dart';
import '../../analysis/domain/edit_suggestion.dart';

class PhotoMetadata {
  /// Unique identifier for the photo
  final String id;

  /// Path to the original photo file
  final String originalPath;

  /// Path to the thumbnail file
  final String thumbnailPath;

  /// Timestamp when the photo was captured
  final DateTime capturedAt;

  /// AI analysis result (optional)
  final AnalysisResult? analysisResult;

  /// On-demand edit suggestion for this photo (optional)
  final EditSuggestion? editSuggestion;

  /// Camera settings used (optional)
  final Map<String, dynamic>? cameraSettings;

  PhotoMetadata({
    required this.id,
    required this.originalPath,
    required this.thumbnailPath,
    required this.capturedAt,
    this.analysisResult,
    this.editSuggestion,
    this.cameraSettings,
  });

  /// Create PhotoMetadata from JSON
  factory PhotoMetadata.fromJson(Map<String, dynamic> json) {
    return PhotoMetadata(
      id: json['id'] as String,
      originalPath: json['originalPath'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      analysisResult: json['analysisResult'] != null
          ? AnalysisResult.fromJson(
              json['analysisResult'] as Map<String, dynamic>)
          : null,
      editSuggestion: json['editSuggestion'] != null
          ? EditSuggestion.fromJson(
              json['editSuggestion'] as Map<String, dynamic>)
          : null,
      cameraSettings: json['cameraSettings'] != null
          ? Map<String, dynamic>.from(json['cameraSettings'] as Map)
          : null,
    );
  }

  /// Convert PhotoMetadata to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalPath': originalPath,
      'thumbnailPath': thumbnailPath,
      'capturedAt': capturedAt.toIso8601String(),
      'analysisResult': analysisResult?.toJson(),
      'editSuggestion': editSuggestion?.toJson(),
      'cameraSettings': cameraSettings,
    };
  }

  PhotoMetadata copyWith({
    AnalysisResult? analysisResult,
    EditSuggestion? editSuggestion,
    Map<String, dynamic>? cameraSettings,
  }) {
    return PhotoMetadata(
      id: id,
      originalPath: originalPath,
      thumbnailPath: thumbnailPath,
      capturedAt: capturedAt,
      analysisResult: analysisResult ?? this.analysisResult,
      editSuggestion: editSuggestion ?? this.editSuggestion,
      cameraSettings: cameraSettings ?? this.cameraSettings,
    );
  }

  @override
  String toString() {
    return 'PhotoMetadata(id: $id, capturedAt: $capturedAt, hasAnalysis: ${analysisResult != null}, hasEditSuggestion: ${editSuggestion != null})';
  }
}
