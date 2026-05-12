// Camera service for handling camera operations.
// Manages camera initialization, preview, and image capture.
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../../core/utils/logger.dart';
import '../../photo/domain/photo_metadata.dart';
import '../../photo/presentation/photo_storage_service.dart';
import '../../analysis/domain/analysis_result.dart';
import 'image_preprocessor.dart';

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  bool _isInitialized = false;
  bool _isProcessing = false;
  FlashMode _flashMode = FlashMode.off;

  /// Whether camera is ready to use.
  bool get isInitialized => _isInitialized;

  /// Current camera controller.
  CameraController? get controller => _controller;

  /// Available cameras.
  List<CameraDescription>? get cameras => _cameras;

  /// Current flash mode.
  FlashMode get flashMode => _flashMode;

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

      // Set default flash mode to off
      await _controller!.setFlashMode(FlashMode.off);
      _flashMode = FlashMode.off;

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

      final bytes = await file.readAsBytes();
      final processedBytes = ImagePreprocessor.preprocessForAnalysis(bytes);

      AppLogger.d(
        'Frame captured: ${bytes.length} bytes, processed: ${processedBytes.length} bytes',
        'CameraService',
      );
      return processedBytes;
    } catch (e) {
      AppLogger.e('Frame capture failed', 'CameraService', e);
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Calculate difference between consecutive frames.
  /// Decodes and compares images at a standardized resolution.
  /// Returns a value between 0.0 (identical) and 1.0 (completely different).
  double calculateFrameDifference(Uint8List current, Uint8List previous) {
    try {
      // Decode images
      img.Image? currentImage = img.decodeImage(current);
      img.Image? previousImage = img.decodeImage(previous);

      if (currentImage == null || previousImage == null) {
        AppLogger.w('Failed to decode one or both images', 'CameraService');
        return 1.0; // Return maximum difference if decoding fails
      }

      // Standardize size for comparison (32x32 is sufficient for motion detection)
      const int compareSize = 32;

      // Resize both images to the same size
      img.Image currentResized = img.copyResize(
        currentImage,
        width: compareSize,
        height: compareSize,
        interpolation: img.Interpolation.linear,
      );

      img.Image previousResized = img.copyResize(
        previousImage,
        width: compareSize,
        height: compareSize,
        interpolation: img.Interpolation.linear,
      );

      // Calculate pixel-wise difference
      int totalPixelDiff = 0;
      int totalPixels = compareSize * compareSize;

      for (int y = 0; y < compareSize; y++) {
        for (int x = 0; x < compareSize; x++) {
          final currentPixel = currentResized.getPixel(x, y);
          final previousPixel = previousResized.getPixel(x, y);

          // Extract RGB components from Pixel object
          final currentR = currentPixel.r.toInt();
          final currentG = currentPixel.g.toInt();
          final currentB = currentPixel.b.toInt();

          final previousR = previousPixel.r.toInt();
          final previousG = previousPixel.g.toInt();
          final previousB = previousPixel.b.toInt();

          // Calculate absolute difference for each channel
          final rDiff = (currentR - previousR).abs();
          final gDiff = (currentG - previousG).abs();
          final bDiff = (currentB - previousB).abs();

          // Sum differences
          totalPixelDiff += rDiff + gDiff + bDiff;
        }
      }

      // Normalize: maximum possible difference is 255 * 3 channels per pixel
      final maxPossibleDiff = totalPixels * 255 * 3;
      final normalizedDiff = totalPixelDiff / maxPossibleDiff;

      AppLogger.d('Frame difference: ${normalizedDiff.toStringAsFixed(4)}',
          'CameraService');
      return normalizedDiff.clamp(0.0, 1.0);
    } catch (e) {
      AppLogger.e('Error calculating frame difference', 'CameraService', e);
      return 1.0; // Return maximum difference on error
    }
  }

  /// Set flash mode.
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null) {
      AppLogger.w(
          'Cannot set flash mode: camera not initialized', 'CameraService');
      return;
    }

    try {
      await _controller!.setFlashMode(mode);
      _flashMode = mode;
      AppLogger.i('Flash mode set to $mode', 'CameraService');
      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to set flash mode', 'CameraService', e);
      rethrow;
    }
  }

  /// Take a photo and save to storage service.
  Future<PhotoMetadata?> takePhoto(
    PhotoStorageService storageService, {
    AnalysisResult? analysisResult,
  }) async {
    if (!_isInitialized || _controller == null) {
      return null;
    }

    try {
      AppLogger.i('Taking photo...', 'CameraService');
      final photo = await _controller!.takePicture();
      AppLogger.i('Photo captured: ${photo.path}', 'CameraService');

      // Save photo using storage service
      final metadata = await storageService.savePhoto(
        photo,
        analysisResult,
        cameraSettings: {
          'flash_mode': _flashMode.toString(),
        },
      );

      return metadata;
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
