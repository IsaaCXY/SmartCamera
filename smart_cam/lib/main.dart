// Main entry point for the Smart Camera app.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/camera/presentation/camera_service.dart';
import 'features/analysis/presentation/analysis_service.dart';
import 'features/analysis/presentation/analysis_coordinator.dart';
import 'features/analysis/data/analysis_api_repository.dart';
import 'features/settings/presentation/settings_service.dart';
import 'features/camera/presentation/pages/camera_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/photo/presentation/photo_storage_service.dart';
import 'features/photo/presentation/pages/photo_gallery_page.dart';
import 'features/photo/presentation/pages/photo_detail_page.dart';

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

class SmartCamApp extends StatefulWidget {
  const SmartCamApp({super.key});

  @override
  State<SmartCamApp> createState() => _SmartCamAppState();
}

class _SmartCamAppState extends State<SmartCamApp> {
  late final SettingsService _settingsService;
  late final AnalysisService _analysisService;
  late final AnalysisCoordinator _analysisCoordinator;
  late final CameraService _cameraService;
  late final PhotoStorageService _photoStorageService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Create settings service first
    _settingsService = SettingsService();
    await _settingsService.loadSettings();

    // Create camera service first (coordinator depends on it)
    _cameraService = CameraService();

    // Now create other services with loaded settings
    final analysisRepository = AnalysisApiRepository(
      apiKey: _settingsService.settings.apiKey,
      provider: _settingsService.settings.selectedProvider,
    );
    _analysisService = AnalysisService(repository: analysisRepository);
    _analysisCoordinator = AnalysisCoordinator(
      cameraService: _cameraService,
    );
    _photoStorageService = PhotoStorageService();

    // Initialize camera and storage
    try {
      await _cameraService.initialize();
      await _photoStorageService.initialize();
    } catch (e) {
      // Camera/storage initialization failed, but we can still show the app
      // Use silent failure for graceful degradation
    }

    // Mark as initialized and rebuild
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _cameraService),
        ChangeNotifierProvider(create: (_) => _analysisService),
        ChangeNotifierProvider(create: (_) => _analysisCoordinator),
        ChangeNotifierProvider(create: (_) => _settingsService),
        ChangeNotifierProvider(create: (_) => _photoStorageService),
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
          '/gallery': (context) => const PhotoGalleryPage(),
          '/photo-detail': (context) => const PhotoDetailPage(),
        },
      ),
    );
  }
}

/// Wrapper to display camera page after initialization.
class CameraPageWrapper extends StatelessWidget {
  const CameraPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraPage();
  }
}
