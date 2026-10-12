import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Future<void> _pumpTab(
  WidgetTester tester,
  MockCourierService service, {
  bool isVisible = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AvailableTab(
          service: service,
          courierId: 'courier-a',
          isVisible: isVisible,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the refresh button picks up new requests', (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    await _pumpTab(tester, service);
    expect(find.text('5 open requests'), findsOneWidget);

    service.addDemoRequest();
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    await tester.pump(); // let the reload finish and rebuild

    expect(find.text('6 open requests'), findsOneWidget);
  });

  testWidgets('pulling down refreshes the list', (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    await _pumpTab(tester, service);

    service.addDemoRequest();
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('6 open requests'), findsOneWidget);
  });

  testWidgets('auto-refreshes every 15 seconds while visible', (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    await _pumpTab(tester, service);

    service.addDemoRequest();
    await tester.pump(const Duration(seconds: 14));
    expect(find.text('5 open requests'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('6 open requests'), findsOneWidget);
  });

  testWidgets('does not auto-refresh while hidden', (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    await _pumpTab(tester, service, isVisible: false);

    service.addDemoRequest();
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();

    expect(find.text('5 open requests'), findsOneWidget);
  });

  testWidgets('refreshing keeps the current list instead of a spinner', (
    tester,
  ) async {
    final service = MockCourierService(
      latency: const Duration(milliseconds: 400),
    );
    await _pumpTab(tester, service);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('5 open requests'), findsOneWidget);

    service.addDemoRequest();
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('5 open requests'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('6 open requests'), findsOneWidget);
  });
}
