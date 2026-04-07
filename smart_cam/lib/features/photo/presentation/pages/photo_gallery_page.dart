/// Photo gallery page displaying all saved photos in a grid layout.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../photo_storage_service.dart';
import '../../../photo/domain/photo_metadata.dart';

class PhotoGalleryPage extends StatelessWidget {
  const PhotoGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PhotoStorageService>(
        builder: (context, storageService, child) {
          final photos = storageService.photos;

          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No photos yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take some photos to see them here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _PhotoGridItem(photo: photo);
            },
          );
        },
      ),
    );
  }
}

class _PhotoGridItem extends StatelessWidget {
  final PhotoMetadata photo;

  const _PhotoGridItem({required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/photo-detail',
          arguments: photo.id,
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image
          ClipRect(
            child: Image.file(
              File(photo.thumbnailPath),
              fit: BoxFit.cover,
            ),
          ),

          // Date overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                _formatDate(photo.capturedAt),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // AI analysis indicator
          if (photo.analysisResult != null)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today: show time
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
