/// Camera service for handling camera operations.
/// Manages camera initialization, preview, and image capture.
import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/logger.dart';

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  
  bool _isInitialized = false;
  bool _isProcessing = false;

  /// Whether camera is ready to use.
  bool get isInitialized => _isInitialized;

  /// Current camera controller.
  CameraController? get controller => _controller;

  /// Available cameras.
  List<CameraDescription>? get cameras => _cameras;

  /// Initialize camera with back camera by default.
  Future<void> initialize() async {
    try {
      AppLogger.i('Initializing camera...', 'CameraService');
      
      // Get available cameras
      _cameras = await availableCameras();
      
      // Find back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Create controller with optimal settings
      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isInitialized = true;
      
      AppLogger.i('Camera initialized successfully', 'CameraService');
      notifyListeners();
    } catch (e) {
      AppLogger.e('Camera initialization failed', 'CameraService', e);
      rethrow;
    }
  }

  /// Capture current frame as image bytes for analysis.
  /// Returns resized image suitable for API processing.
  Future<Uint8List?> captureFrameForAnalysis() async {
    if (!_isInitialized || _controller == null || _isProcessing) {
      return null;
    }

    try {
      _isProcessing = true;
      
      // Take picture
      final XFile file = await _controller!.takePicture();
      
      // Read and resize image
      final bytes = await file.readAsBytes();
      
      // TODO: Implement image resizing to AppConfig.analysisImageWidth/Height
      // For now, return original bytes (backend can handle resizing)
      
      AppLogger.d('Frame captured: ${bytes.length} bytes', 'CameraService');
      return bytes;
    } catch (e) {
      AppLogger.e('Frame capture failed', 'CameraService', e);
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Calculate difference between consecutive frames.
  /// Simple implementation using histogram comparison.
  double calculateFrameDifference(Uint8List current, Uint8List previous) {
    if (current.length != previous.length) {
      return 1.0; // Maximum difference if sizes don't match
    }

    int diffSum = 0;
    final sampleStep = current.length ~/ 1000; // Sample 1000 points
    
    for (int i = 0; i < current.length; i += sampleStep) {
      diffSum += (current[i] - previous[i]).abs();
    }
    
    final avgDiff = diffSum / (current.length ~/ sampleStep);
    final normalizedDiff = avgDiff / 255.0; // Normalize to 0-1
    
    return normalizedDiff.clamp(0.0, 1.0);
  }

  /// Take a photo and save to file.
  Future<XFile?> takePhoto() async {
    if (!_isInitialized || _controller == null) {
      return null;
    }

    try {
      AppLogger.i('Taking photo...', 'CameraService');
      final photo = await _controller!.takePicture();
      AppLogger.i('Photo saved: ${photo.path}', 'CameraService');
      return photo;
    } catch (e) {
      AppLogger.e('Photo capture failed', 'CameraService', e);
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
