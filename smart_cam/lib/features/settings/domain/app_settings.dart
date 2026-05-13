/// Settings model for app configuration.
class AppSettings {
  String selectedProvider;
  String apiKey;
  String customBaseUrl; // Custom API base URL
  String customUrlType; // URL type: openai/anthropic
  String customModel;
  String azureEndpoint;
  String azureDeployment;
  String azureApiVersion;
  bool enableAutoAnalysis;
  bool manualAnalysisTrigger;
  bool showGridLines;

  AppSettings({
    this.selectedProvider = 'openai',
    this.apiKey = '',
    this.customBaseUrl = '',
    this.customUrlType = 'openai',
    this.customModel = 'gpt-4.1-mini',
    this.azureEndpoint = '',
    this.azureDeployment = '',
    this.azureApiVersion = '2024-02-15-preview',
    this.enableAutoAnalysis = true,
    this.manualAnalysisTrigger = false,
    this.showGridLines = true,
  });

  /// Create from JSON.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      selectedProvider: json['provider'] ?? 'openai',
      apiKey: json['api_key'] ?? '',
      customBaseUrl: json['custom_base_url'] ?? '',
      customUrlType: json['custom_url_type'] ?? 'openai',
      customModel: json['custom_model'] ?? 'gpt-4.1-mini',
      azureEndpoint: json['azure_endpoint'] ?? '',
      azureDeployment: json['azure_deployment'] ?? '',
      azureApiVersion: json['azure_api_version'] ?? '2024-02-15-preview',
      enableAutoAnalysis: json['auto_analysis'] ?? true,
      manualAnalysisTrigger: json['manual_analysis_trigger'] ?? false,
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
      'custom_model': customModel,
      'azure_endpoint': azureEndpoint,
      'azure_deployment': azureDeployment,
      'azure_api_version': azureApiVersion,
      'auto_analysis': enableAutoAnalysis,
      'manual_analysis_trigger': manualAnalysisTrigger,
      'grid_lines': showGridLines,
    };
  }
}
