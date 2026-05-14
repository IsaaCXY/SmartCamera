import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_cam/features/camera/presentation/camera_service.dart';

void main() {
  test('normalizes tap position for camera focus point', () {
    final point = CameraService.normalizeFocusPoint(
      const Offset(120, 300),
      const Size(400, 600),
    );

    expect(point.dx, 0.3);
    expect(point.dy, 0.5);
  });

  test('clamps normalized focus point into camera range', () {
    final point = CameraService.normalizeFocusPoint(
      const Offset(500, -20),
      const Size(400, 600),
    );

    expect(point.dx, 1.0);
    expect(point.dy, 0.0);
  });
}
