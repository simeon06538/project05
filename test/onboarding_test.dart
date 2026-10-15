import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/services/courier_prefs.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Future<CourierPrefs> _pumpApp(
  WidgetTester tester,
  Map<String, Object> saved,
) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await CourierPrefs.load();
  await tester.pumpWidget(
    CampusDeliveryApp(
      courierService: MockCourierService(latency: Duration.zero),
      prefs: prefs,
    ),
  );
  await tester.pump();
  return prefs;
}

/// Page turns and the Lottie loops never settle, so wait a fixed time.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('first launch shows the intro', (tester) async {
    await _pumpApp(tester, {});

    expect(find.text('Pick a request'), findsOneWidget);
    expect(find.bySemanticsLabel('Slide 1 of 3'), findsOneWidget);
    expect(find.text('Available requests'), findsNothing);
  });

  testWidgets('Next walks through all three slides to Get started', (
    tester,
  ) async {
    final prefs = await _pumpApp(tester, {});

    await tester.tap(find.text('Next'));
    await _settle(tester);
    expect(find.text('Pick up and deliver'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await _settle(tester);
    expect(find.text('Get paid'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await _settle(tester);
    expect(find.text('Available requests'), findsOneWidget);
    expect(prefs.onboardingDone, isTrue);
  });

  testWidgets('Skip goes straight to the app', (tester) async {
    final prefs = await _pumpApp(tester, {});

    await tester.tap(find.text('Skip'));
    await _settle(tester);

    expect(find.text('Available requests'), findsOneWidget);
    expect(prefs.onboardingDone, isTrue);
  });

  testWidgets('after the first time the app opens normally', (tester) async {
    await _pumpApp(tester, {'courier.onboardingDone': true});

    expect(find.text('Pick a request'), findsNothing);
    expect(find.text('Available requests'), findsOneWidget);
  });
}
