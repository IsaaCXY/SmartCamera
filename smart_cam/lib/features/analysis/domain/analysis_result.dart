/// Domain model for AI analysis results.
class AnalysisResult {
  final String sceneDescription;
  final String shootingAdvice;
  final Map<String, dynamic> cameraParams;
  final List<String> filterSuggestions;
  final Map<String, dynamic> editParams;

  AnalysisResult({
    this.sceneDescription = '',
    required this.shootingAdvice,
    required this.cameraParams,
    required this.filterSuggestions,
    required this.editParams,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      sceneDescription: json['scene_description'] ?? '',
      shootingAdvice: json['shooting_advice'] ?? '',
      cameraParams: Map<String, dynamic>.from(json['camera_params'] ?? {}),
      filterSuggestions: List<String>.from(json['filter_suggestions'] ?? []),
      editParams: Map<String, dynamic>.from(json['edit_params'] ?? {}),
    );
  }

  /// Convert AnalysisResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'scene_description': sceneDescription,
      'shooting_advice': shootingAdvice,
      'camera_params': cameraParams,
      'filter_suggestions': filterSuggestions,
      'edit_params': editParams,
    };
  }

  @override
  String toString() {
    return 'AnalysisResult(scene: $sceneDescription, advice: $shootingAdvice, params: $cameraParams)';
  }
}
