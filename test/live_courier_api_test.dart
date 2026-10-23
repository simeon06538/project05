import 'dart:convert';
import 'dart:io';

import 'package:campus_delivery/constants/campus_locations.dart';
import 'package:campus_delivery/models/delivery_request_draft.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/services/api_courier_service.dart';
import 'package:campus_delivery/services/api_customer_order_service.dart';
import 'package:campus_delivery/services/courier_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _NetworkTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

/// K-12: the courier flow against the real Node server, on an isolated
/// in-memory database (tools/customer_api_test_server.js).
void main() {
  _NetworkTestBinding();
  test(
    'a customer order is accepted, delivered and paid on the Node API',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final process = await Process.start('node', [
        'tools/customer_api_test_server.js',
      ]);
      addTearDown(() async {
        process.kill();
        await process.exitCode.timeout(const Duration(seconds: 5));
      });
      final base = await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 15));
      final client = http.Client();
      addTearDown(client.close);

      final customer = ApiCustomerOrderService(
        preferences: preferences,
        client: client,
        baseUrl: base,
      );
      final placed = await customer.createOrder(
        'demo-customer:taylor',
        DeliveryRequestDraft(
          orderName: 'Taylor',
          restaurant: 'Popeyes',
          orderNumber: 'PP-LIVE',
          pickup: campusLocations.firstWhere((l) => l.id == 'the-5'),
          dropoff: campusLocations.firstWhere((l) => l.id == 'spruce-hall'),
          tipCents: 200,
        ),
      );

      final courier = ApiCourierService(
        preferences: preferences,
        client: client,
        baseUrl: base,
      );
      const alex = '${ApiCourierService.idPrefix}Alex';
      final open = await courier.fetchAvailableRequests();
      final request = open.firstWhere((o) => o.id == placed.id);
      expect(request.pickupLocation, endsWith(' · Popeyes'));
      expect(request.totalPayCents, placed.totalPayCents);

      await courier.acceptRequest(request.id, alex);
      // A second courier loses the race (K-13).
      await expectLater(
        courier.acceptRequest(request.id, '${ApiCourierService.idPrefix}Riley'),
        throwsA(isA<OrderAlreadyTakenException>()),
      );
      expect((await courier.fetchActiveDelivery(alex))?.id, request.id);

      await courier.updateStatus(request.id, OrderStatus.pickedUp);
      final delivered = await courier.updateStatus(
        request.id,
        OrderStatus.delivered,
        dropoffNote: 'Left at the front desk',
      );
      expect(delivered.status, OrderStatus.delivered);

      final earnings = await courier.fetchEarnings(alex);
      expect(earnings.balanceCents, placed.totalPayCents);
      expect(earnings.completedDeliveries.single.id, request.id);
      // The customer sees it delivered too.
      expect(
        (await customer.fetchOrders('demo-customer:taylor')).single.status,
        OrderStatus.delivered,
      );
    },
    skip: !const bool.fromEnvironment('RUN_LIVE_COURIER_API'),
  );
}
