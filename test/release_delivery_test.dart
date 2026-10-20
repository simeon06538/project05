import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/my_deliveries_tab.dart';
import 'package:campus_delivery/services/courier_service.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

const _courier = 'courier-a';
const _releaseLabel = "Can't make it? Release delivery";

Future<(MockCourierService, Order)> _accepted() async {
  final service = MockCourierService(latency: Duration.zero);
  final order = (await service.fetchAvailableRequests()).first;
  await service.acceptRequest(order.id, _courier);
  return (service, order);
}

Future<void> _pumpTab(WidgetTester tester, MockCourierService service) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        // Fresh key so each pump builds (and loads) a new tab.
        body: MyDeliveriesTab(
          key: UniqueKey(),
          service: service,
          courierId: _courier,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('releaseDelivery', () {
    test('puts an accepted order back on the open list', () async {
      final (service, order) = await _accepted();

      final released = await service.releaseDelivery(order.id, _courier);

      expect(released.status, OrderStatus.requested);
      expect(released.courierId, isNull);
      expect(released.acceptedAt, isNull);
      expect(await service.fetchActiveDelivery(_courier), isNull);
      expect(
        (await service.fetchAvailableRequests()).map((o) => o.id),
        contains(order.id),
      );
    });

    test('is refused after pickup', () async {
      final (service, order) = await _accepted();
      await service.updateStatus(order.id, OrderStatus.pickedUp);

      expect(
        () => service.releaseDelivery(order.id, _courier),
        throwsA(isA<InvalidStatusChangeException>()),
      );
    });

    test("is refused for someone else's delivery", () async {
      final (service, order) = await _accepted();

      expect(
        () => service.releaseDelivery(order.id, 'courier-b'),
        throwsA(isA<NotYourDeliveryException>()),
      );
    });
  });

  testWidgets('release is offered before pickup only', (tester) async {
    final (service, order) = await _accepted();
    await _pumpTab(tester, service);
    expect(find.text(_releaseLabel), findsOneWidget);

    await service.updateStatus(order.id, OrderStatus.pickedUp);
    await _pumpTab(tester, service);
    expect(find.text(_releaseLabel), findsNothing);
  });

  testWidgets('"Keep delivery" cancels the release', (tester) async {
    final (service, _) = await _accepted();
    await _pumpTab(tester, service);

    await tester.tap(find.text(_releaseLabel));
    await tester.pumpAndSettle();
    expect(find.text('Release this delivery?'), findsOneWidget);
    await tester.tap(find.text('Keep delivery'));
    await tester.pumpAndSettle();

    expect(find.text('Release this delivery?'), findsNothing);
    expect(await service.fetchActiveDelivery(_courier), isNotNull);
  });

  testWidgets('confirming releases it and clears My Deliveries', (
    tester,
  ) async {
    final (service, order) = await _accepted();
    await _pumpTab(tester, service);

    await tester.tap(find.text(_releaseLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Release'));
    // The empty state's Lottie loops, so don't wait to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('No active delivery'), findsOneWidget);
    expect(find.textContaining('Delivery released'), findsOneWidget);
    expect(
      (await service.fetchAvailableRequests()).map((o) => o.id),
      contains(order.id),
    );
  });
}
