
import 'dart:convert';
import 'dart:io';

import 'package:campus_delivery/constants/campus_locations.dart';
import 'package:campus_delivery/models/delivery_request_draft.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/services/api_customer_order_service.dart';
import 'package:campus_delivery/services/api_courier_service.dart';
import 'package:campus_delivery/services/courier_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _NetworkTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

void main() {
  _NetworkTestBinding();

  test('D-07 to D-10: customer and courier integration', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final process = await Process.start('node', [
      'tools/customer_api_test_server.js',
    ]);

    addTearDown(() async {
      process.kill();
      await process.exitCode.timeout(const Duration(seconds: 5));
    });

    final baseUrl = await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first
        .timeout(const Duration(seconds: 15));

    final client = http.Client();
    addTearDown(client.close);

    final customer = ApiCustomerOrderService(
      preferences: preferences,
      client: client,
      baseUrl: baseUrl,
    );

    final courier = ApiCourierService(
      preferences: preferences,
      client: client,
      baseUrl: baseUrl,
    );

    final draft = DeliveryRequestDraft(
      orderName: 'Integration Test',
      restaurant: 'Popeyes',
      orderNumber: 'D-07-TEST',
      pickup: campusLocations.firstWhere(
        (location) => location.id == 'the-5',
      ),
      dropoff: campusLocations.firstWhere(
        (location) => location.id == 'spruce-hall',
      ),
      tipCents: 100,
    );

    // D-07: Customer creates an order visible to couriers.
    final created = await customer.createOrder(
      'demo-customer:integration-test',
      draft,
    );

    final available = await courier.fetchAvailableRequests();
    expect(available.any((order) => order.id == created.id), isTrue);

    // D-08: Courier accepts and customer sees accepted.
    final accepted = await courier.acceptRequest(
      created.id,
      'demo-courier:alex',
    );
    expect(accepted.status, OrderStatus.accepted);

    final customerOrders = await customer.fetchOrders(
      'demo-customer:integration-test',
    );
    expect(
      customerOrders.single.status,
      OrderStatus.accepted,
    );

    // D-10: A second courier cannot accept the same order.
    await expectLater(
      courier.acceptRequest(created.id, 'demo-courier:sam'),
      throwsA(isA<OrderAlreadyTakenException>()),
    );

    // D-09: Completing delivery increases courier earnings.
    final before = await courier.fetchEarnings('demo-courier:alex');

    await courier.updateStatus(created.id, OrderStatus.pickedUp);
    await courier.updateStatus(created.id, OrderStatus.delivered);

    final after = await courier.fetchEarnings('demo-courier:alex');

    expect(
      after.balanceCents,
      before.balanceCents + created.totalPayCents,
    );
  });
}
