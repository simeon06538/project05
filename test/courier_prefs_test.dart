import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glassmorphism/glassmorphism.dart';
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
  // Intro already seen (K-44), so the app opens on the home screen.
  SharedPreferences.setMockInitialValues({
    'courier.onboardingDone': true,
    ...saved,
  });
  final prefs = await CourierPrefs.load();
  await tester.pumpWidget(
    CampusDeliveryApp(
      showWelcome: false,
      courierService: MockCourierService(latency: Duration.zero),
      prefs: prefs,
    ),
  );
  await tester.pump();
  await tester.pump();
  return prefs;
}

void main() {
  test('nothing saved means defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await CourierPrefs.load();

    expect(prefs.name, isNull);
    expect(prefs.dailyGoalCents, isNull);
    expect(prefs.online, isNull);
    expect(prefs.highContrast, isNull);
  });

  testWidgets('saved name, offline status and high contrast load at start', (
    tester,
  ) async {
    await _pumpApp(tester, {
      'courier.name': 'Sam Lee',
      'courier.online': false,
      'courier.highContrast': true,
    });

    expect(find.text('Sam Lee'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.byType(GlassmorphicContainer), findsNothing);
  });

  testWidgets('going offline is remembered', (tester) async {
    final prefs = await _pumpApp(tester, {});

    await tester.tap(find.text('Online'));
    await tester.pump();

    expect(prefs.online, isFalse);
  });

  testWidgets('a saved goal shows on Earnings', (tester) async {
    await _pumpApp(tester, {'courier.dailyGoalCents': 3000});

    await tester.tap(find.text('Earnings').first);
    await tester.pump();
    await tester.pump();

    expect(find.text(r'$0.00 of $30.00'), findsOneWidget);
  });
}
