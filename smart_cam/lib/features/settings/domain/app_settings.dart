/// Settings model for app configuration.
class AppSettings {
  String selectedProvider;
  String apiKey;
  String customBaseUrl;          // Custom API base URL
  String customUrlType;          // URL type: openai/anthropic
  bool enableAutoAnalysis;
  bool showGridLines;

  AppSettings({
    this.selectedProvider = 'openai',
    this.apiKey = '',
    this.customBaseUrl = '',
    this.customUrlType = 'openai',
    this.enableAutoAnalysis = true,
    this.showGridLines = true,
  });

  /// Create from JSON.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      selectedProvider: json['provider'] ?? 'openai',
      apiKey: json['api_key'] ?? '',
      customBaseUrl: json['custom_base_url'] ?? '',
      customUrlType: json['custom_url_type'] ?? 'openai',
      enableAutoAnalysis: json['auto_analysis'] ?? true,
      showGridLines: json['grid_lines'] ?? true,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'provider': selectedProvider,
      'api_key': apiKey,
      'custom_base_url': customBaseUrl,
      'custom_url_type': customUrlType,
      'auto_analysis': enableAutoAnalysis,
      'grid_lines': showGridLines,
    };
  }
}
