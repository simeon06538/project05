import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Future<MockCourierService> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = MockCourierService(latency: Duration.zero);
  await tester.pumpWidget(CampusDeliveryApp(courierService: service));
  await tester.pump();
  return service;
}

Future<void> _toggle(WidgetTester tester, String label) async {
  // "Go online" sits under the offline panel, below the test screen's fold.
  await tester.scrollUntilVisible(
    find.text(label),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(); // let a reload finish when coming back online
}

void main() {
  testWidgets('starts online with requests showing', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Online'), findsOneWidget);
    expect(find.text('5 open requests'), findsOneWidget);
  });

  testWidgets('going offline hides the requests', (tester) async {
    await _pumpApp(tester);

    await _toggle(tester, 'Online');

    expect(find.text('Offline'), findsOneWidget);
    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('5 open requests'), findsNothing);
  });

  testWidgets('"Go online" brings fresh requests back', (tester) async {
    final service = await _pumpApp(tester);
    await _toggle(tester, 'Online');

    service.addDemoRequest();
    await _toggle(tester, 'Go online');

    expect(find.text('Online'), findsOneWidget);
    expect(find.text('6 open requests'), findsOneWidget);
  });

  testWidgets('tapping Offline in the header also goes back online', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _toggle(tester, 'Online');

    await _toggle(tester, 'Offline');

    expect(find.text("You're offline"), findsNothing);
    expect(find.text('5 open requests'), findsOneWidget);
  });

  testWidgets('the switch is announced with its state', (tester) async {
    await _pumpApp(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Online, tap to go offline')),
      isSemantics(isToggled: true, isButton: true),
    );
  });
}
