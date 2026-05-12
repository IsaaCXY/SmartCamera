import 'package:flutter_test/flutter_test.dart';
import 'package:smart_cam/features/analysis/presentation/stability/stability_engine.dart';

void main() {
  group('StabilityEngine', () {
    test('starts unstable', () {
      final engine = StabilityEngine();

      expect(engine.score, 0.0);
      expect(engine.isStable, isFalse);
    });

    test('requires three consecutive stable frames', () {
      final engine = StabilityEngine();

      engine.update(0.02);
      expect(engine.isStable, isFalse);

      engine.update(0.03);
      expect(engine.isStable, isFalse);

      engine.update(0.04);
      expect(engine.isStable, isTrue);
      expect(engine.score, greaterThanOrEqualTo(0.8));
    });

    test('drops below stable threshold immediately when motion appears', () {
      final engine = StabilityEngine();

      engine.update(0.02);
      engine.update(0.02);
      engine.update(0.02);
      expect(engine.isStable, isTrue);

      engine.update(0.20);

      expect(engine.isStable, isFalse);
      expect(engine.score, lessThan(0.8));
    });

    test('does not stay stable during repeated borderline motion', () {
      final engine = StabilityEngine();

      engine.update(0.02);
      engine.update(0.02);
      engine.update(0.02);
      expect(engine.isStable, isTrue);

      engine.update(0.10);
      engine.update(0.10);

      expect(engine.isStable, isFalse);
      expect(engine.score, lessThan(0.8));
    });
  });
}
