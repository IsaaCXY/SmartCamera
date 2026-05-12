import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:smart_cam/core/config/app_config.dart';
import 'package:smart_cam/features/camera/presentation/image_preprocessor.dart';

void main() {
  group('ImagePreprocessor', () {
    test('resizes large images inside analysis bounds without changing aspect',
        () {
      final source = img.Image(width: 1600, height: 1200);
      final bytes = Uint8List.fromList(img.encodeJpg(source, quality: 95));

      final processed = ImagePreprocessor.preprocessForAnalysis(bytes);
      final decoded = img.decodeImage(processed)!;

      expect(decoded.width, lessThanOrEqualTo(AppConfig.analysisImageWidth));
      expect(decoded.height, lessThanOrEqualTo(AppConfig.analysisImageHeight));
      expect(decoded.width / decoded.height, closeTo(4 / 3, 0.02));
    });

    test('does not upscale small images', () {
      final source = img.Image(width: 200, height: 100);
      final bytes = Uint8List.fromList(img.encodeJpg(source, quality: 95));

      final processed = ImagePreprocessor.preprocessForAnalysis(bytes);
      final decoded = img.decodeImage(processed)!;

      expect(decoded.width, 200);
      expect(decoded.height, 100);
    });

    test('returns original bytes when image cannot be decoded', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final processed = ImagePreprocessor.preprocessForAnalysis(bytes);

      expect(processed, bytes);
    });
  });
}
