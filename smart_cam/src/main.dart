/// Main entry point for the Smart Camera app.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/camera/presentation/camera_service.dart';
import 'features/analysis/presentation/analysis_service.dart';
import 'features/analysis/data/analysis_api_repository.dart';
import 'features/settings/presentation/settings_service.dart';
import 'features/camera/presentation/pages/camera_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const SmartCamApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SmartCamApp();
  }
}

class SmartCamApp extends StatelessWidget {
  const SmartCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final settingsService = SettingsService();
    final analysisRepository = AnalysisApiRepository(
      apiKey: settingsService.settings.apiKey,
      provider: settingsService.settings.selectedProvider,
    );
    final analysisService = AnalysisService(repository: analysisRepository);
    final cameraService = CameraService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => cameraService),
        ChangeNotifierProvider(create: (_) => analysisService),
        ChangeNotifierProvider(create: (_) => settingsService),
      ],
      child: MaterialApp(
        title: 'Smart Camera',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const CameraPageWrapper(),
          '/settings': (context) => const SettingsPage(),
        },
      ),
    );
  }
}

/// Wrapper to initialize camera on app start.
class CameraPageWrapper extends StatefulWidget {
  const CameraPageWrapper({super.key});

  @override
  State<CameraPageWrapper> createState() => _CameraPageWrapperState();
}

class _CameraPageWrapperState extends State<CameraPageWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameraService = context.read<CameraService>();
      await cameraService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CameraPage();
  }
}
