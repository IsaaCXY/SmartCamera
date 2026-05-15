// Settings page for configuring app preferences.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;
  late TextEditingController _apiKeyController;
  late TextEditingController _customBaseUrlController;
  late TextEditingController _customModelController;
  late TextEditingController _azureEndpointController;
  late TextEditingController _azureDeploymentController;
  late TextEditingController _azureApiVersionController;

  @override
  void initState() {
    super.initState();
    final settingsService = context.read<SettingsService>();
    _apiKeyController =
        TextEditingController(text: settingsService.settings.apiKey);
    _customBaseUrlController =
        TextEditingController(text: settingsService.settings.customBaseUrl);
    _customModelController =
        TextEditingController(text: settingsService.settings.customModel);
    _azureEndpointController =
        TextEditingController(text: settingsService.settings.azureEndpoint);
    _azureDeploymentController =
        TextEditingController(text: settingsService.settings.azureDeployment);
    _azureApiVersionController =
        TextEditingController(text: settingsService.settings.azureApiVersion);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customBaseUrlController.dispose();
    _customModelController.dispose();
    _azureEndpointController.dispose();
    _azureDeploymentController.dispose();
    _azureApiVersionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI Provider Selection
          _buildProviderSection(context),

          const Divider(height: 32),

          // API Key Input
          _buildApiKeySection(context),

          const Divider(height: 32),

          // Custom Provider Configuration (only shown when custom is selected)
          _buildCustomProviderSection(context),

          // Azure Provider Configuration (only shown when azure is selected)
          _buildAzureProviderSection(context),

          const Divider(height: 32),

          // Test Connection Button
          _buildTestSection(context),

          const Divider(height: 32),

          // Toggle Options
          _buildToggleSection(context),
        ],
      ),
    );
  }

  Widget _buildProviderSection(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final currentProvider = settingsService.settings.selectedProvider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Provider',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value:currentProvider,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select provider',
          ),
          items: const [
            DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
            DropdownMenuItem(value: 'anthropic', child: Text('Anthropic')),
            DropdownMenuItem(value: 'azure', child: Text('Azure OpenAI')),
            DropdownMenuItem(value: 'zhipu_glm', child: Text('智谱 GLM')),
            DropdownMenuItem(value: 'custom', child: Text('Custom Endpoint')),
          ],
          onChanged: (value) {
            if (value != null) {
              settingsService.setProvider(value);
            }
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Select your preferred AI service provider for image analysis.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildApiKeySection(BuildContext context) {
    final settingsService = context.watch<SettingsService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'API Key',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiKeyController,
          obscureText: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter your API key',
            prefixIcon: Icon(Icons.key),
          ),
          onChanged: (value) {
            settingsService.setApiKey(value);
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Your API key is stored locally and used for authentication.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCustomProviderSection(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final currentProvider = settingsService.settings.selectedProvider;

    // Only show when custom provider is selected
    if (currentProvider != 'custom') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Endpoint Configuration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Base URL Input
        TextField(
          controller: _customBaseUrlController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'https://api.example.com/v1',
            prefixIcon: Icon(Icons.link),
            labelText: 'Base URL',
          ),
          onChanged: (value) {
            settingsService.setCustomBaseUrl(value);
          },
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _customModelController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'gpt-4.1-mini',
            prefixIcon: Icon(Icons.smart_toy),
            labelText: 'Model',
          ),
          onChanged: (value) {
            settingsService.setCustomModel(value);
          },
        ),
        const SizedBox(height: 16),

        // URL Type Dropdown
        DropdownButtonFormField<String>(
          value:settingsService.settings.customUrlType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'URL Type',
            prefixIcon: Icon(Icons.api),
          ),
          items: const [
            DropdownMenuItem(
              value: 'openai',
              child: Text('OpenAI-compatible'),
            ),
            DropdownMenuItem(
              value: 'anthropic',
              child: Text('Anthropic-compatible'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              settingsService.setCustomUrlType(value);
            }
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Configure your custom endpoint. Select the API format your endpoint uses.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAzureProviderSection(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final currentProvider = settingsService.settings.selectedProvider;

    if (currentProvider != 'azure') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Azure OpenAI Configuration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _azureEndpointController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'https://your-resource.openai.azure.com',
            prefixIcon: Icon(Icons.cloud),
            labelText: 'Endpoint',
          ),
          onChanged: (value) {
            settingsService.setAzureEndpoint(value);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _azureDeploymentController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'your-vision-deployment',
            prefixIcon: Icon(Icons.smart_toy),
            labelText: 'Deployment',
          ),
          onChanged: (value) {
            settingsService.setAzureDeployment(value);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _azureApiVersionController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '2024-02-15-preview',
            prefixIcon: Icon(Icons.api),
            labelText: 'API Version',
          ),
          onChanged: (value) {
            settingsService.setAzureApiVersion(value);
          },
        ),
      ],
    );
  }

  Widget _buildToggleSection(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final settings = settingsService.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Auto Analysis Toggle
        SwitchListTile(
          title: const Text('Enable Auto Analysis'),
          subtitle: const Text('Automatically analyze scene for suggestions'),
          value: settings.enableAutoAnalysis,
          onChanged: (value) {
            settingsService.toggleAutoAnalysis(value);
          },
        ),

        SwitchListTile(
          title: const Text('Manual Realtime Analysis'),
          subtitle: const Text('Long-press shutter to analyze current frame'),
          value: settings.manualAnalysisTrigger,
          onChanged: (value) {
            settingsService.toggleManualAnalysisTrigger(value);
          },
        ),

        // Grid Lines Toggle
        SwitchListTile(
          title: const Text('Show Grid Lines'),
          subtitle: const Text('Display rule-of-thirds grid on preview'),
          value: settings.showGridLines,
          onChanged: (value) {
            settingsService.toggleGridLines(value);
          },
        ),
      ],
    );
  }

  Widget _buildTestSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Connection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isTesting ? null : _testConnection,
          icon: _isTesting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cloud_done, size: 20),
          label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: _isTesting ? Colors.grey : Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        if (_testMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _testSuccess == true
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _testSuccess == true ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _testSuccess == true ? Icons.check_circle : Icons.error,
                  color: _testSuccess == true ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _testMessage!,
                    style: TextStyle(
                      color: _testSuccess == true
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Test your API key and provider connection before using the camera.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    try {
      final settingsService = context.read<SettingsService>();
      final result = await settingsService.testConnection();

      setState(() {
        _testMessage = result['message'] as String;
        _testSuccess = result['success'] as bool;
      });

      // Show snackbar for better visibility
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_testMessage!),
            backgroundColor: _testSuccess == true ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _testMessage = 'Test failed: ${e.toString()}';
        _testSuccess = false;
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }
}
