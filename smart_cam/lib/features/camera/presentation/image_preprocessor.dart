import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../core/config/app_config.dart';
import '../../../core/utils/logger.dart';

class ImagePreprocessor {
  const ImagePreprocessor._();

  static Uint8List preprocessForAnalysis(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        return bytes;
      }

      final ratio = math.min(
        AppConfig.analysisImageWidth / image.width,
        AppConfig.analysisImageHeight / image.height,
      );
      final shouldResize = ratio < 1.0;
      final targetWidth = shouldResize
          ? (image.width * ratio).round().clamp(1, image.width)
          : image.width;
      final targetHeight = shouldResize
          ? (image.height * ratio).round().clamp(1, image.height)
          : image.height;

      final processed = shouldResize
          ? img.copyResize(
              image,
              width: targetWidth,
              height: targetHeight,
              interpolation: img.Interpolation.linear,
            )
          : image;

      return Uint8List.fromList(
        img.encodeJpg(processed, quality: AppConfig.analysisImageQuality),
      );
    } catch (e) {
      AppLogger.e('Image preprocessing failed', 'ImagePreprocessor', e);
      return bytes;
    }
  }
}
