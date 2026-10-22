import 'dart:convert';

import 'package:campus_delivery/constants/campus_locations.dart';
import 'package:campus_delivery/models/delivery_request_draft.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/services/mock_customer_order_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DeliveryRequestDraft draft() => DeliveryRequestDraft(
  orderName: 'Taylor',
  restaurant: 'Sonic',
  orderNumber: 'PP-123',
  pickup: campusLocations[0],
  dropoff: campusLocations[1],
  tipCents: 100,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'confirmed requests and pickup metadata survive a new service instance',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final service = MockCustomerOrderService(
        preferences: prefs,
        seedExamples: false,
      );
      final order = await service.createOrder('taylor', draft());
      expect(order.totalPayCents, 350);
      final restored = MockCustomerOrderService(
        preferences: prefs,
        seedExamples: false,
      );
      final saved = await restored.fetchOrders('taylor');
      expect(saved.single.id, order.id);
      expect(saved.single.status, OrderStatus.requested);
      expect(saved.single.pickupLocationName, contains('Sonic'));
      expect(saved.single.pawPointsOrderNumber, 'PP-123');
      final json = jsonDecode(
        prefs.getString(MockCustomerOrderService.storageKey)!,
      ) as Map;
      expect(json['details'][order.id]['orderName'], 'Taylor');
    },
  );

  test(
    'owners see only their orders and cannot delete another customer request',
    () async {
      final service = MockCustomerOrderService(seedExamples: false);
      final order = await service.createOrder('taylor', draft());
      expect(await service.fetchOrders('sam'), isEmpty);
      await expectLater(service.deleteOrder('sam', order.id), throwsStateError);
      expect((await service.fetchOrders('taylor')).single.id, order.id);
    },
  );

  test(
    'deletion is permanent, not archived, and sample requests do not reappear',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final service = MockCustomerOrderService(preferences: prefs);
      final initial = await service.fetchOrders('taylor');
      final waiting = initial.singleWhere(
        (order) => order.status == OrderStatus.requested,
      );
      final created = await service.createOrder('taylor', draft());
      await service.deleteOrder('taylor', waiting.id);
      await service.deleteOrder('taylor', created.id);
      final restored = MockCustomerOrderService(preferences: prefs);
      final orders = await restored.fetchOrders('taylor');
      expect(orders.length, 1);
      expect(orders.single.status, OrderStatus.delivered);
      expect(
        orders.any((order) => order.id == waiting.id || order.id == created.id),
        isFalse,
      );
      await expectLater(
        restored.deleteOrder('taylor', orders.single.id),
        throwsStateError,
      );
    },
  );

  test(
    'accepted requests cannot be deleted and concurrent creates are preserved',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final service = MockCustomerOrderService(
        preferences: prefs,
        seedExamples: false,
      );
      final orders = await Future.wait(
        List.generate(3, (_) => service.createOrder('taylor', draft())),
      );
      expect(orders.map((order) => order.id).toSet().length, 3);
      expect((await service.fetchOrders('taylor')).length, 3);
      final accepted = orders.first.copyWith(status: OrderStatus.accepted);
      final withAccepted = MockCustomerOrderService(
        seedExamples: false,
        initialOrders: [accepted],
      );
      await expectLater(
        withAccepted.deleteOrder('taylor', accepted.id),
        throwsStateError,
      );
    },
  );
}
