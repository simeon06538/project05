import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/completed_delivery_screen.dart';
import 'package:campus_delivery/screens/courier/my_deliveries_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

const _courier = 'courier-a';

Future<(MockCourierService, Order)> _pickedUp() async {
  final service = MockCourierService(latency: Duration.zero);
  final order = (await service.fetchAvailableRequests()).first;
  await service.acceptRequest(order.id, _courier);
  await service.updateStatus(order.id, OrderStatus.pickedUp);
  return (service, order);
}

void main() {
  test('the mock saves a trimmed note on delivery', () async {
    final (service, order) = await _pickedUp();

    final delivered = await service.updateStatus(
      order.id,
      OrderStatus.delivered,
      dropoffNote: '  Left with the front desk ',
    );

    expect(delivered.dropoffNote, 'Left with the front desk');
  });

  test('a blank note is not saved', () async {
    final (service, order) = await _pickedUp();

    final delivered = await service.updateStatus(
      order.id,
      OrderStatus.delivered,
      dropoffNote: '   ',
    );

    expect(delivered.dropoffNote, isNull);
  });

  testWidgets('a note typed when delivering is saved with the order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (service, _) = await _pickedUp();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyDeliveriesTab(service: service, courierId: _courier),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.textContaining('Mark as delivered'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Handed to Jordan');
    await tester.tap(find.text('Yes, delivered'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final earnings = await service.fetchEarnings(_courier);
    expect(earnings.completedDeliveries.single.dropoffNote, 'Handed to Jordan');
  });

  testWidgets('the delivery summary shows the note', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (service, order) = await _pickedUp();
    final delivered = await service.updateStatus(
      order.id,
      OrderStatus.delivered,
      dropoffNote: 'Left at room 214',
    );
    await tester.pumpWidget(
      MaterialApp(home: CompletedDeliveryScreen(order: delivered)),
    );

    expect(find.text('Drop-off note'), findsOneWidget);
    expect(find.text('Left at room 214'), findsOneWidget);
  });
}
