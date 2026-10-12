import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/screens/courier/earnings_tab.dart';
import 'package:campus_delivery/screens/courier/my_deliveries_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

const _courier = 'courier-a';

Future<void> _pump(WidgetTester tester, Widget tab) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: tab)));
  await tester.pump();
}

/// Taps "Try again" and waits for the reload to show.
Future<void> _retry(WidgetTester tester) async {
  await tester.tap(find.text('Try again'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows a labelled spinner while loading', (tester) async {
    await _pump(
      tester,
      AvailableTab(
        service: MockCourierService(latency: const Duration(milliseconds: 400)),
        courierId: _courier,
        refreshEvery: null,
      ),
    );

    expect(find.text('Loading requests…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Loading requests…'), findsNothing);
  });

  testWidgets('Available: error with Try again that recovers', (tester) async {
    final service = MockCourierService(latency: Duration.zero)..failNextCalls();
    await _pump(
      tester,
      AvailableTab(service: service, courierId: _courier, refreshEvery: null),
    );

    expect(find.text("Couldn't load requests"), findsOneWidget);
    await _retry(tester);
    expect(find.text("Couldn't load requests"), findsNothing);
    expect(find.text('5 open requests'), findsOneWidget);
  });

  testWidgets('My Deliveries: error with Try again that recovers', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero)..failNextCalls();
    await _pump(tester, MyDeliveriesTab(service: service, courierId: _courier));

    expect(find.text("Couldn't load your delivery"), findsOneWidget);
    await _retry(tester);
    expect(find.text('No active delivery'), findsOneWidget);
  });

  testWidgets('Earnings: error with Try again that recovers', (tester) async {
    final service = MockCourierService(latency: Duration.zero)..failNextCalls();
    await _pump(tester, EarningsTab(service: service, courierId: _courier));

    expect(find.text("Couldn't load your earnings"), findsOneWidget);
    await _retry(tester);
    expect(find.text('Demo balance'), findsOneWidget);
  });

  testWidgets('a failed status update explains the network problem', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(order.id, _courier);
    await _pump(tester, MyDeliveriesTab(service: service, courierId: _courier));

    service.failNextCalls();
    await tester.scrollUntilVisible(find.text('Mark as picked up'), 200);
    await tester.tap(find.text('Mark as picked up'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining("Couldn't reach the server"), findsOneWidget);
    // Still on the same step, so the courier can simply try again.
    expect(find.text('Mark as picked up'), findsOneWidget);
  });
}
