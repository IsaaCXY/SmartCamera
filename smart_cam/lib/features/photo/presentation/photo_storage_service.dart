/// Photo storage service for managing photo persistence and metadata.
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../../analysis/domain/analysis_result.dart';
import '../domain/photo_metadata.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/logger.dart';

class PhotoStorageService extends ChangeNotifier {
  List<PhotoMetadata> _photos = [];
  Directory? _appDocDir;
  Directory? _photosDir;
  Directory? _thumbnailsDir;
  File? _metadataFile;

  /// Get all photos sorted by capture time (newest first)
  List<PhotoMetadata> get photos => List.unmodifiable(_photos);

  /// Initialize storage directories and load metadata
  Future<void> initialize() async {
    try {
      AppLogger.i('Initializing photo storage...', 'PhotoStorageService');

      // Get application documents directory
      _appDocDir = await getApplicationDocumentsDirectory();

      // Create photos directory
      _photosDir = Directory(path.join(_appDocDir!.path, AppConfig.photosDirName));
      if (!await _photosDir!.exists()) {
        await _photosDir!.create(recursive: true);
        AppLogger.i('Created photos directory: ${_photosDir!.path}', 'PhotoStorageService');
      }

      // Create thumbnails directory
      _thumbnailsDir = Directory(path.join(_appDocDir!.path, AppConfig.thumbnailsDirName));
      if (!await _thumbnailsDir!.exists()) {
        await _thumbnailsDir!.create(recursive: true);
        AppLogger.i('Created thumbnails directory: ${_thumbnailsDir!.path}', 'PhotoStorageService');
      }

      // Get metadata file
      _metadataFile = File(path.join(_appDocDir!.path, AppConfig.metadataFileName));

      // Load existing metadata
      await _loadMetadata();

      AppLogger.i('Photo storage initialized successfully. Found ${_photos.length} photos.',
          'PhotoStorageService');
      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to initialize photo storage', 'PhotoStorageService', e);
      rethrow;
    }
  }

  /// Save photo and return metadata
  Future<PhotoMetadata> savePhoto(
    XFile photo,
    AnalysisResult? analysisResult, {
    Map<String, dynamic>? cameraSettings,
  }) async {
    try {
      AppLogger.i('Saving photo...', 'PhotoStorageService');

      // Generate photo ID
      final timestamp = DateTime.now();
      final photoId = _generatePhotoId(timestamp);

      // Copy photo to app storage
      final originalPath = await _copyPhotoToStorage(photo, photoId);

      // Generate thumbnail
      final thumbnailPath = await _generateThumbnail(originalPath, photoId);

      // Create metadata
      final metadata = PhotoMetadata(
        id: photoId,
        originalPath: originalPath,
        thumbnailPath: thumbnailPath,
        capturedAt: timestamp,
        analysisResult: analysisResult,
        cameraSettings: cameraSettings,
      );

      // Add to list and save metadata
      _photos.insert(0, metadata); // Insert at beginning (newest first)
      await _saveMetadata();

      AppLogger.i('Photo saved successfully: $photoId', 'PhotoStorageService');
      notifyListeners();

      return metadata;
    } catch (e) {
      AppLogger.e('Failed to save photo', 'PhotoStorageService', e);
      rethrow;
    }
  }

  /// Get photo by ID
  PhotoMetadata? getPhotoById(String id) {
    try {
      return _photos.firstWhere((photo) => photo.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Delete photo by ID
  Future<void> deletePhoto(String id) async {
    try {
      final photo = getPhotoById(id);
      if (photo == null) {
        AppLogger.w('Photo not found: $id', 'PhotoStorageService');
        return;
      }

      // Delete original file
      final originalFile = File(photo.originalPath);
      if (await originalFile.exists()) {
        await originalFile.delete();
      }

      // Delete thumbnail file
      final thumbnailFile = File(photo.thumbnailPath);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }

      // Remove from list and save metadata
      _photos.removeWhere((p) => p.id == id);
      await _saveMetadata();

      AppLogger.i('Photo deleted: $id', 'PhotoStorageService');
      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to delete photo: $id', 'PhotoStorageService', e);
      rethrow;
    }
  }

  /// Copy photo to app storage directory
  Future<String> _copyPhotoToStorage(XFile photo, String photoId) async {
    if (_photosDir == null) {
      throw Exception('Photos directory not initialized');
    }

    // Generate file path
    final extension = path.extension(photo.path);
    final fileName = '$photoId$extension';
    final targetPath = path.join(_photosDir!.path, fileName);

    // Copy file
    await photo.saveTo(targetPath);

    AppLogger.d('Photo copied to: $targetPath', 'PhotoStorageService');
    return targetPath;
  }

  /// Generate thumbnail for photo
  Future<String> _generateThumbnail(String originalPath, String photoId) async {
    if (_thumbnailsDir == null) {
      throw Exception('Thumbnails directory not initialized');
    }

    try {
      // Read original image
      final originalFile = File(originalPath);
      final bytes = await originalFile.readAsBytes();

      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to thumbnail size (maintain aspect ratio)
      img.Image thumbnail = img.copyResize(
        image,
        width: AppConfig.thumbnailSize,
        height: AppConfig.thumbnailSize,
        interpolation: img.Interpolation.linear,
      );

      // Generate thumbnail file path
      final fileName = '${photoId}_thumb.jpg';
      final thumbnailPath = path.join(_thumbnailsDir!.path, fileName);

      // Encode and save thumbnail
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(
        img.encodeJpg(thumbnail, quality: AppConfig.thumbnailQuality),
      );

      AppLogger.d('Thumbnail generated: $thumbnailPath', 'PhotoStorageService');
      return thumbnailPath;
    } catch (e) {
      AppLogger.e('Failed to generate thumbnail', 'PhotoStorageService', e);
      rethrow;
    }
  }

  /// Load metadata from JSON file
  Future<void> _loadMetadata() async {
    if (_metadataFile == null || !await _metadataFile!.exists()) {
      AppLogger.i('No existing metadata file found', 'PhotoStorageService');
      _photos = [];
      return;
    }

    try {
      final jsonString = await _metadataFile!.readAsString();
      final jsonList = json.decode(jsonString) as List;

      _photos = jsonList
          .map((json) => PhotoMetadata.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by capture time (newest first)
      _photos.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

      AppLogger.i('Loaded ${_photos.length} photo metadata entries', 'PhotoStorageService');
    } catch (e) {
      AppLogger.e('Failed to load metadata', 'PhotoStorageService', e);
      _photos = [];
    }
  }

  /// Save metadata to JSON file
  Future<void> _saveMetadata() async {
    if (_metadataFile == null) {
      throw Exception('Metadata file not initialized');
    }

    try {
      final jsonList = _photos.map((photo) => photo.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await _metadataFile!.writeAsString(jsonString);

      AppLogger.d('Metadata saved (${_photos.length} entries)', 'PhotoStorageService');
    } catch (e) {
      AppLogger.e('Failed to save metadata', 'PhotoStorageService', e);
      rethrow;
    }
  }

  /// Generate unique photo ID based on timestamp
  String _generatePhotoId(DateTime timestamp) {
    final dateStr = timestamp.toIso8601String().replaceAll('-', '').replaceAll(':', '').replaceAll('.', '').split('T').join('_');
    final sequence = _photos.length + 1;
    return '${AppConfig.photoIdPrefix}_${dateStr}_${sequence.toString().padLeft(3, '0')}';
  }

  /// Get total storage size used by photos (in bytes)
  Future<int> getTotalStorageSize() async {
    int totalSize = 0;

    for (final photo in _photos) {
      try {
        final file = File(photo.originalPath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      } catch (e) {
        AppLogger.w('Failed to get file size for ${photo.id}', 'PhotoStorageService');
      }
    }

    return totalSize;
  }

  /// Clear all photos (use with caution)
  Future<void> clearAllPhotos() async {
    try {
      // Delete all photo files
      for (final photo in _photos) {
        try {
          await File(photo.originalPath).delete();
          await File(photo.thumbnailPath).delete();
        } catch (e) {
          AppLogger.w('Failed to delete file for ${photo.id}', 'PhotoStorageService');
        }
      }

      // Clear list and metadata
      _photos.clear();
      await _saveMetadata();

      AppLogger.i('All photos cleared', 'PhotoStorageService');
      notifyListeners();
    } catch (e) {
      AppLogger.e('Failed to clear photos', 'PhotoStorageService', e);
      rethrow;
    }
  }
}
