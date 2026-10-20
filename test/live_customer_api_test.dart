import 'dart:convert';
import 'dart:io';

import 'package:campus_delivery/constants/campus_locations.dart';
import 'package:campus_delivery/models/delivery_request_draft.dart';
import 'package:campus_delivery/services/api_customer_order_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _NetworkTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

void main() {
  _NetworkTestBinding();
  test(
    'real Flutter client creates, reloads and deletes an order on the Node API',
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
      final service = ApiCustomerOrderService(
        preferences: preferences,
        client: client,
        baseUrl: base,
      );
      final draft = DeliveryRequestDraft(
        orderName: 'Taylor',
        restaurant: 'Popeyes',
        orderNumber: 'PP-LIVE',
        pickup: campusLocations.firstWhere(
          (location) => location.id == 'the-5',
        ),
        dropoff: campusLocations.firstWhere(
          (location) => location.id == 'spruce-hall',
        ),
        tipCents: 100,
      );
      final order = await service.createOrder('demo-customer:taylor', draft);
      expect(order.pickupRestaurant, 'Popeyes');
      expect(order.orderName, 'Taylor');
      expect(order.distanceMiles, draft.distanceMiles);
      expect(order.totalPayCents, draft.totalCents);
      final reopened = ApiCustomerOrderService(
        preferences: preferences,
        client: client,
        baseUrl: base,
      );
      expect(
        (await reopened.fetchOrders('demo-customer:taylor')).single.id,
        order.id,
      );
      await reopened.deleteOrder('demo-customer:taylor', order.id);
      expect(await reopened.fetchOrders('demo-customer:taylor'), isEmpty);
    },
    skip: !const bool.fromEnvironment('RUN_LIVE_CUSTOMER_API'),
  );
}
