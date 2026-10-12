import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/services/courier_service.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

void main() {
  late MockCourierService service;

  setUp(() => service = MockCourierService(latency: Duration.zero));

  test('starts with open requests, oldest first', () async {
    final requests = await service.fetchAvailableRequests();
    expect(requests, hasLength(5));
    expect(requests.every((o) => o.status == OrderStatus.requested), isTrue);
    for (var i = 1; i < requests.length; i++) {
      expect(requests[i - 1].createdAt.isBefore(requests[i].createdAt), isTrue);
    }
  });

  test('total pay is delivery fee plus tip', () async {
    final order = (await service.fetchAvailableRequests()).first;
    expect(order.totalPayCents, order.deliveryFeeCents + order.tipCents);
  });

  test(
    'accepting removes the order from available and makes it active',
    () async {
      final order = (await service.fetchAvailableRequests()).first;
      final accepted = await service.acceptRequest(order.id, 'courier-a');

      expect(accepted.status, OrderStatus.accepted);
      expect(accepted.courierId, 'courier-a');
      expect(await service.fetchAvailableRequests(), hasLength(4));
      expect((await service.fetchActiveDelivery('courier-a'))?.id, order.id);
    },
  );

  test('a second courier cannot accept a taken order', () async {
    final order = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(order.id, 'courier-a');

    expect(
      () => service.acceptRequest(order.id, 'courier-b'),
      throwsA(isA<OrderAlreadyTakenException>()),
    );
  });

  test('a courier cannot accept two deliveries at once', () async {
    final requests = await service.fetchAvailableRequests();
    await service.acceptRequest(requests[0].id, 'courier-a');

    expect(
      () => service.acceptRequest(requests[1].id, 'courier-a'),
      throwsA(isA<ActiveDeliveryException>()),
    );
  });

  test('status must go accepted -> pickedUp -> delivered in order', () async {
    final order = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(order.id, 'courier-a');

    expect(
      () => service.updateStatus(order.id, OrderStatus.delivered),
      throwsA(isA<InvalidStatusChangeException>()),
    );
    await service.updateStatus(order.id, OrderStatus.pickedUp);
    final done = await service.updateStatus(order.id, OrderStatus.delivered);
    expect(done.status, OrderStatus.delivered);
    expect(await service.fetchActiveDelivery('courier-a'), isNull);
  });

  test('delivering adds total pay to the courier balance', () async {
    final order = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(order.id, 'courier-a');
    await service.updateStatus(order.id, OrderStatus.pickedUp);
    await service.updateStatus(order.id, OrderStatus.delivered);

    final earnings = await service.fetchEarnings('courier-a');
    expect(earnings.balanceCents, order.totalPayCents);
    expect(earnings.completedDeliveries.single.id, order.id);
    expect((await service.fetchEarnings('courier-b')).balanceCents, 0);
  });

  test('unknown order ids throw OrderNotFoundException', () {
    expect(
      () => service.acceptRequest('nope', 'courier-a'),
      throwsA(isA<OrderNotFoundException>()),
    );
  });

  test('formatCents shows dollars with two decimals', () {
    expect(formatCents(350), r'$3.50');
    expect(formatCents(0), r'$0.00');
  });

  demoRequestTests();
}

void demoRequestTests() {
  test('takeByOtherCourier removes the order and blocks accepting', () async {
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;

    service.takeByOtherCourier(order.id);

    expect(await service.fetchAvailableRequests(), hasLength(4));
    expect(
      () => service.acceptRequest(order.id, 'courier-a'),
      throwsA(isA<OrderAlreadyTakenException>()),
    );
  });

  test('failNextCalls fails only the given number of calls', () async {
    final service = MockCourierService(latency: Duration.zero)
      ..failNextCalls(2);

    await expectLater(
      service.fetchAvailableRequests(),
      throwsA(isA<ServiceUnavailableException>()),
    );
    await expectLater(
      service.fetchEarnings('courier-a'),
      throwsA(isA<ServiceUnavailableException>()),
    );
    expect(await service.fetchAvailableRequests(), hasLength(5));
  });

  test('addDemoRequest adds a new open request', () async {
    final service = MockCourierService(latency: Duration.zero);
    final added = service.addDemoRequest();

    final requests = await service.fetchAvailableRequests();
    expect(requests, hasLength(6));
    expect(requests.last.id, added.id);
    expect(added.status, OrderStatus.requested);
    // Same fee rule as the seed data: $2.00 + $0.50 per 0.25 mi.
    expect(added.deliveryFeeCents, 350);
  });

  test('newRequestEvery adds a request once the interval has passed', () async {
    final service = MockCourierService(
      latency: Duration.zero,
      newRequestEvery: const Duration(minutes: 1),
      now: DateTime.now().subtract(const Duration(minutes: 2)),
    );

    expect(await service.fetchAvailableRequests(), hasLength(6));
    // The timer restarts, so an immediate second fetch adds nothing.
    expect(await service.fetchAvailableRequests(), hasLength(6));
  });
}
