import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Future<void> _pumpTab(WidgetTester tester, MockCourierService service) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AvailableTab(service: service, courierId: 'courier-a'),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _refresh(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Refresh'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('no banner on the first load', (tester) async {
    await _pumpTab(tester, MockCourierService(latency: Duration.zero));

    expect(find.textContaining('new request'), findsNothing);
  });

  testWidgets('a refresh with a new request shows the banner', (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    await _pumpTab(tester, service);

    final added = service.addDemoRequest();
    await _refresh(tester);

    expect(find.text('1 new request'), findsOneWidget);
    expect(find.textContaining(added.pickupLocation), findsWidgets);
  });

  testWidgets('two new requests are counted together', (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    await _pumpTab(tester, service);

    service
      ..addDemoRequest()
      ..addDemoRequest();
    await _refresh(tester);

    expect(find.text('2 new requests'), findsOneWidget);
  });

  testWidgets('View opens the newest request', (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    await _pumpTab(tester, service);
    final added = service.addDemoRequest();
    await _refresh(tester);

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(find.text('Request details'), findsOneWidget);
    expect(find.text(added.pawPointsOrderNumber), findsOneWidget);
  });

  testWidgets('Dismiss hides the banner until something new arrives', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    await _pumpTab(tester, service);
    service.addDemoRequest();
    await _refresh(tester);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump();
    expect(find.text('1 new request'), findsNothing);

    await _refresh(tester);
    expect(find.text('1 new request'), findsNothing);
  });
}
