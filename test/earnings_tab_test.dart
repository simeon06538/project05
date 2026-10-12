import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/earnings_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

const _courier = 'courier-a';

/// Accepts, picks up and delivers [order] for [courierId].
Future<void> _deliver(
  MockCourierService service,
  Order order, [
  String courierId = _courier,
]) async {
  await service.acceptRequest(order.id, courierId);
  await service.updateStatus(order.id, OrderStatus.pickedUp);
  await service.updateStatus(order.id, OrderStatus.delivered);
}

Future<void> _pumpTab(WidgetTester tester, MockCourierService service) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EarningsTab(service: service, courierId: _courier),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('starts at a zero balance with the empty state', (tester) async {
    await _pumpTab(tester, MockCourierService(latency: Duration.zero));

    expect(find.text(r'$0.00'), findsNWidgets(2)); // balance and tips
    expect(find.text('No completed deliveries yet'), findsOneWidget);
  });

  testWidgets('shows balance, tips and each completed delivery', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    final requests = await service.fetchAvailableRequests();
    // Grill ($3.00 + $1.00 tip) and Starbucks ($3.50 + $2.00 tip).
    await _deliver(service, requests[0]);
    await _deliver(service, requests[1]);
    await _pumpTab(tester, service);

    expect(find.text(r'$9.50'), findsOneWidget);
    expect(find.text(r'$3.00'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text(requests[0].dropoffLocation), findsOneWidget);
    expect(find.text(requests[1].dropoffLocation), findsOneWidget);
    expect(find.text(r'+$4.00'), findsOneWidget);
    expect(find.text(r'+$5.50'), findsOneWidget);
    expect(find.text('No completed deliveries yet'), findsNothing);
  });

  testWidgets("other couriers' deliveries don't count", (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    await _deliver(service, order, 'someone-else');
    await _pumpTab(tester, service);

    expect(find.text('No completed deliveries yet'), findsOneWidget);
  });

  testWidgets('a delivery finished on My Deliveries shows up on Earnings', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    await tester.pumpWidget(CampusDeliveryApp(courierService: service));
    await tester.pump();

    await tester.tap(find.text('Earnings'));
    await tester.pump();
    await tester.pump();
    expect(find.text('No completed deliveries yet'), findsOneWidget);

    await _deliver(service, order, demoCourierId);
    await tester.tap(find.text('Available'));
    await tester.pump();
    await tester.tap(find.text('Earnings'));
    await tester.pump();
    await tester.pump();

    expect(find.text('+${formatCents(order.totalPayCents)}'), findsOneWidget);
  });
}
