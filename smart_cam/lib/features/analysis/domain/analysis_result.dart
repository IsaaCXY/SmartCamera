/// Domain model for AI analysis results.
class AnalysisResult {
  final String shootingAdvice;
  final Map<String, dynamic> cameraParams;
  final List<String> filterSuggestions;
  final Map<String, dynamic> editParams;

  AnalysisResult({
    required this.shootingAdvice,
    required this.cameraParams,
    required this.filterSuggestions,
    required this.editParams,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      shootingAdvice: json['shooting_advice'] ?? '',
      cameraParams: Map<String, dynamic>.from(json['camera_params'] ?? {}),
      filterSuggestions: List<String>.from(json['filter_suggestions'] ?? []),
      editParams: Map<String, dynamic>.from(json['edit_params'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'AnalysisResult(advice: $shootingAdvice, params: $cameraParams)';
  }
}
