/// Photo detail page showing full photo with metadata and AI analysis results.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../photo_storage_service.dart';
import '../../../photo/domain/photo_metadata.dart';

class PhotoDetailPage extends StatelessWidget {
  const PhotoDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final photoId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Photo Details'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Delete button
          Consumer<PhotoStorageService>(
            builder: (context, storageService, child) {
              return IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteDialog(context, storageService, photoId),
              );
            },
          ),
          // Share button (placeholder)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<PhotoMetadata?>(
        future: _loadPhoto(context, photoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load photo',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final photo = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo image
                Center(
                  child: InteractiveViewer(
                    child: Image.file(
                      File(photo.originalPath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Photo info
                _buildPhotoInfo(context, photo),

                // AI Analysis results
                if (photo.analysisResult != null)
                  _buildAnalysisResults(context, photo),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<PhotoMetadata?> _loadPhoto(BuildContext context, String photoId) async {
    final storageService = context.read<PhotoStorageService>();
    return storageService.getPhotoById(photoId);
  }

  Widget _buildPhotoInfo(BuildContext context, PhotoMetadata photo) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'Captured: ${_formatDateTime(photo.capturedAt)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.photo_camera, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ID: ${photo.id}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (photo.cameraSettings != null && photo.cameraSettings!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.settings, size: 20, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Flash: ${_formatFlashMode(photo.cameraSettings!['flash_mode'])}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisResults(BuildContext context, PhotoMetadata photo) {
    final result = photo.analysisResult!;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Shooting advice
          _buildSection(
            '💡 Shooting Advice',
            result.shootingAdvice,
            Icons.lightbulb_outline,
          ),
          const SizedBox(height: 16),

          // Camera parameters
          if (result.cameraParams.isNotEmpty)
            _buildSection(
              '📷 Camera Parameters',
              _formatParams(result.cameraParams),
              Icons.camera_alt,
            ),
          const SizedBox(height: 16),

          // Filter suggestions
          if (result.filterSuggestions.isNotEmpty)
            _buildSection(
              '🎨 Filter Suggestions',
              result.filterSuggestions.join('\n'),
              Icons.palette,
            ),
          const SizedBox(height: 16),

          // Edit parameters
          if (result.editParams.isNotEmpty)
            _buildSection(
              '🔧 Edit Parameters',
              _formatParams(result.editParams),
              Icons.edit,
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  String _formatFlashMode(dynamic flashMode) {
    if (flashMode == null) return 'Unknown';
    final modeStr = flashMode.toString();
    if (modeStr.contains('off')) return 'Off';
    if (modeStr.contains('auto')) return 'Auto';
    if (modeStr.contains('always')) return 'On';
    return modeStr;
  }

  String _formatParams(Map<String, dynamic> params) {
    return params.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  void _showDeleteDialog(
    BuildContext context,
    PhotoStorageService storageService,
    String photoId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await storageService.deletePhoto(photoId);
              if (context.mounted) {
                Navigator.pop(context); // Go back to gallery
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
