import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glassmorphism/glassmorphism.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/screens/courier/settings_screen.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Future<ValueNotifier<bool>> _pumpApp(
  WidgetTester tester, {
  bool highContrast = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final contrast = ValueNotifier(highContrast);
  await tester.pumpWidget(
    CampusDeliveryApp(
      courierService: MockCourierService(latency: Duration.zero),
      highContrast: contrast,
    ),
  );
  await tester.pump();
  await tester.pump();
  return contrast;
}

bool _boldText(WidgetTester tester) =>
    MediaQuery.boldTextOf(tester.element(find.text('Alex Morgan')));

void main() {
  testWidgets('off by default: glass panels and normal text', (tester) async {
    await _pumpApp(tester);

    expect(find.byType(GlassmorphicContainer), findsWidgets);
    expect(_boldText(tester), isFalse);
  });

  testWidgets('on: solid panels and bold text everywhere', (tester) async {
    await _pumpApp(tester, highContrast: true);

    expect(find.byType(GlassmorphicContainer), findsNothing);
    expect(_boldText(tester), isTrue);
  });

  testWidgets('the Settings switch turns it on for the whole app', (
    tester,
  ) async {
    final contrast = await _pumpApp(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('High contrast'));
    await tester.pump();

    expect(contrast.value, isTrue);
    expect(
      find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(GlassmorphicContainer),
      ),
      findsNothing,
    );
  });

  testWidgets('high contrast still meets the contrast guideline', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpApp(tester, highContrast: true);

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
