import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// K-33: ticks both pickup checks so "Mark as picked up" is enabled.
Future<void> completePickupChecklist(WidgetTester tester) async {
  final boxes = find.byType(Checkbox);
  for (var i = 0; i < 2; i++) {
    await tester.ensureVisible(boxes.at(i));
    await tester.pump();
    await tester.tap(boxes.at(i));
    await tester.pump();
  }
}
