import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/screens/courier/courier_home_screen.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: CourierHomeScreen(
        service: MockCourierService(latency: Duration.zero),
        courierId: 'courier-a',
        idleTimeout: const Duration(minutes: 1),
        stillThereGrace: const Duration(seconds: 10),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('asks "Still there?" after the idle time', (tester) async {
    await _pumpHome(tester);

    await tester.pump(const Duration(seconds: 59));
    expect(find.text('Still there?'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Still there?'), findsOneWidget);
  });

  testWidgets('no answer sets the courier offline', (tester) async {
    await _pumpHome(tester);
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    for (var i = 0; i < 11; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump();

    expect(find.text('Still there?'), findsNothing);
    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets("I'm here keeps the courier online", (tester) async {
    await _pumpHome(tester);
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    await tester.tap(find.text("I'm here"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Still there?'), findsNothing);
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('a tap restarts the idle countdown', (tester) async {
    await _pumpHome(tester);

    await tester.pump(const Duration(seconds: 50));
    await tester.tap(find.text('Available requests'));
    await tester.pump(const Duration(seconds: 50));

    expect(find.text('Still there?'), findsNothing);
  });

  testWidgets('no idle check while offline', (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Online'));
    await tester.pump();

    await tester.pump(const Duration(minutes: 5));

    expect(find.text('Still there?'), findsNothing);
  });
}
