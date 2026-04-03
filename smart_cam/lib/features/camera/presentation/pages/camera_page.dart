/// Camera page with real-time AI suggestions overlay.
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../camera_service.dart';
import '../../../analysis/presentation/analysis_service.dart';
import '../../../settings/presentation/settings_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  Uint8List? _previousFrame;
  Timer? _frameTimer;

  @override
  void initState() {
    super.initState();
    _startFrameMonitoring();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  /// Start monitoring frames for stability and analysis.
  void _startFrameMonitoring() {
    // Check frames every 500ms
    _frameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      final cameraService = context.read<CameraService>();
      final analysisService = context.read<AnalysisService>();
      final settingsService = context.read<SettingsService>();

      if (!settingsService.settings.enableAutoAnalysis) return;

      // Capture current frame
      final currentFrame = await cameraService.captureFrameForAnalysis();
      if (currentFrame == null) return;

      // Calculate frame difference
      double difference = 1.0;
      if (_previousFrame != null) {
        difference = cameraService.calculateFrameDifference(
          currentFrame,
          _previousFrame!,
        );
      }

      // Check stability
      final isStable = analysisService.checkStability(difference);

      // If stable and scene changed significantly, trigger analysis
      if (isStable && difference > 0.1) {
        await analysisService.analyzeIfReady(currentFrame);
      } else if (difference < 0.1) {
        // Scene is too similar, reset stability counter
        analysisService.resetStability();
      }

      _previousFrame = currentFrame;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          _buildCameraPreview(),
          
          // AI suggestions overlay
          _buildOverlay(),
          
          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Consumer<CameraService>(
      builder: (context, cameraService, child) {
        if (!cameraService.isInitialized || cameraService.controller == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return CameraPreview(cameraService.controller!);
      },
    );
  }

  Widget _buildOverlay() {
    return Consumer<AnalysisService>(
      builder: (context, analysisService, child) {
        final result = analysisService.currentResult;

        if (result == null) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shooting advice
                Text(
                  '💡 ${result.shootingAdvice}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Camera parameters
                if (result.cameraParams.isNotEmpty) ...[
                  Text(
                    '📷 Parameters:',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatParams(result.cameraParams),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
                
                // Filter suggestions
                if (result.filterSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '🎨 Filters: ${result.filterSuggestions.join(", ")}',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 32),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          
          // Shutter button
          Consumer<CameraService>(
            builder: (context, cameraService, child) {
              return GestureDetector(
                onTap: () async {
                  final photo = await cameraService.takePhoto();
                  if (photo != null) {
                    _showPhotoResult(photo.path);
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 36,
                  ),
                ),
              );
            },
          ),
          
          // Placeholder for gallery
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  String _formatParams(Map<String, dynamic> params) {
    return params.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
  }

  void _showPhotoResult(String photoPath) {
    final analysisService = context.read<AnalysisService>();
    final result = analysisService.currentResult;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Captured'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📸 Photo saved successfully!'),
            const SizedBox(height: 16),
            if (result != null) ...[
              const Text('Edit Suggestions:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Filters: ${result.filterSuggestions.join(", ")}'),
              const SizedBox(height: 8),
              Text('Parameters: ${_formatParams(result.editParams)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
