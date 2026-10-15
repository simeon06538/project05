import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/my_deliveries_tab.dart';
import 'package:campus_delivery/services/courier_service.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

const _courier = 'courier-a';

Future<(MockCourierService, Order)> _accepted() async {
  final service = MockCourierService(latency: Duration.zero);
  final order = (await service.fetchAvailableRequests()).first;
  await service.acceptRequest(order.id, _courier);
  return (service, order);
}

Future<void> _pumpTab(WidgetTester tester, MockCourierService service) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MyDeliveriesTab(service: service, courierId: _courier),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _report(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text('Report a problem'));
  await tester.tap(find.text('Report a problem'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  test('only problems that fit the status are offered', () {
    expect(DeliveryProblem.optionsFor(OrderStatus.accepted), [
      DeliveryProblem.restaurantClosed,
      DeliveryProblem.orderNotReady,
      DeliveryProblem.other,
    ]);
    expect(DeliveryProblem.optionsFor(OrderStatus.pickedUp), [
      DeliveryProblem.cantFindCustomer,
      DeliveryProblem.other,
    ]);
  });

  test('a closed restaurant cancels the order without pay', () async {
    final (service, order) = await _accepted();

    final cancelled = await service.reportProblem(
      order.id,
      _courier,
      DeliveryProblem.restaurantClosed,
    );

    expect(cancelled.status, OrderStatus.cancelled);
    expect(await service.fetchActiveDelivery(_courier), isNull);
    expect((await service.fetchEarnings(_courier)).balanceCents, 0);
  });

  test('other problems flag the order and keep it going', () async {
    final (service, order) = await _accepted();
    await service.updateStatus(order.id, OrderStatus.pickedUp);

    final flagged = await service.reportProblem(
      order.id,
      _courier,
      DeliveryProblem.cantFindCustomer,
      details: '  No answer at the door ',
    );

    expect(flagged.status, OrderStatus.pickedUp);
    expect(flagged.problem, DeliveryProblem.cantFindCustomer);
    expect(flagged.problemDetails, 'No answer at the door');
  });

  test('a problem that does not fit the status is refused', () async {
    final (service, order) = await _accepted();
    await service.updateStatus(order.id, OrderStatus.pickedUp);

    expect(
      () => service.reportProblem(
        order.id,
        _courier,
        DeliveryProblem.restaurantClosed,
      ),
      throwsA(isA<InvalidStatusChangeException>()),
    );
  });

  testWidgets('reporting a closed restaurant clears My Deliveries', (
    tester,
  ) async {
    final (service, _) = await _accepted();
    await _pumpTab(tester, service);

    await _report(tester, 'Restaurant is closed');
    expect(find.text('Cancel order'), findsOneWidget);
    await tester.tap(find.text('Cancel order'));
    // The empty state's Lottie loops, so don't wait to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('No active delivery'), findsOneWidget);
    expect(find.textContaining('Order cancelled'), findsOneWidget);
  });

  testWidgets('a flagged problem shows on the active delivery', (tester) async {
    final (service, _) = await _accepted();
    await _pumpTab(tester, service);

    await _report(tester, "Order isn't ready (long wait)");
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Reported: Order isn't ready"), findsOneWidget);
    expect(
      find.text('Problem reported. Support has been notified.'),
      findsOneWidget,
    );
  });
}
