/// Settings page for configuring app preferences.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/settings_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
          value: currentProvider,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select provider',
          ),
          items: const [
            DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
            DropdownMenuItem(value: 'anthropic', child: Text('Anthropic')),
            DropdownMenuItem(value: 'azure', child: Text('Azure OpenAI')),
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
    final apiKey = settingsService.settings.apiKey;

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
          obscureText: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter your API key',
            prefixIcon: Icon(Icons.key),
          ),
          onChanged: (value) {
            settingsService.setApiKey(value);
          },
          controller: TextEditingController(text: apiKey),
        ),
        const SizedBox(height: 8),
        Text(
          'Your API key is stored locally and used for authentication.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
}
