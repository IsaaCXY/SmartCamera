import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_cam/features/camera/presentation/pages/camera_page.dart';

void main() {
  testWidgets('rule of thirds grid renders when enabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RuleOfThirdsGridOverlay(),
        ),
      ),
    );

    expect(find.byKey(const Key('rule_of_thirds_grid')), findsOneWidget);
    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('rule_of_thirds_grid')),
    );
    expect(paint.painter, isNotNull);
  });
}
