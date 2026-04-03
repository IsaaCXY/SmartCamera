/// Settings model for app configuration.
class AppSettings {
  String selectedProvider;
  String apiKey;
  bool enableAutoAnalysis;
  bool showGridLines;

  AppSettings({
    this.selectedProvider = 'openai',
    this.apiKey = '',
    this.enableAutoAnalysis = true,
    this.showGridLines = true,
  });

  /// Create from JSON.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      selectedProvider: json['provider'] ?? 'openai',
      apiKey: json['api_key'] ?? '',
      enableAutoAnalysis: json['auto_analysis'] ?? true,
      showGridLines: json['grid_lines'] ?? true,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'provider': selectedProvider,
      'api_key': apiKey,
      'auto_analysis': enableAutoAnalysis,
      'grid_lines': showGridLines,
    };
  }
}
