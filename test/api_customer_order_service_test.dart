import 'dart:convert';

import 'package:campus_delivery/constants/campus_locations.dart';
import 'package:campus_delivery/models/delivery_request_draft.dart';
import 'package:campus_delivery/services/api_customer_order_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('create/list/delete use the server user ID and correct API payload; ID survives reload', () async {
    final prefs = await SharedPreferences.getInstance();
    var registrations = 0;
    final orders = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      if (request.url.path == '/users' && request.method == 'POST') {
        registrations++;
        expect(jsonDecode(request.body), {
          'name': 'taylor',
          'role': 'customer',
        });
        return http.Response(
          jsonEncode({'id': 6, 'name': 'taylor', 'role': 'customer'}),
          201,
        );
      }
      if (request.url.path == '/users/6') {
        return http.Response(
          jsonEncode({'id': 6, 'name': 'taylor', 'role': 'customer'}),
          200,
        );
      }
      if (request.url.path == '/orders' && request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {
          'customerId': 6,
          'pickupLocation': 'union',
          'dropoffLocation': 'middleton-library',
          'tip': 1.15,
          'pawPointsOrderNumber': 'PP-123',
          'isMobileOrder': true,
          'orderName': 'Taylor',
          'pickupRestaurant': 'Sonic',
        });
        orders.add({
          ...body,
          'id': 11,
          'courierId': null,
          'pickupLocationName': 'LSU Student Union',
          'dropoffLocationName': 'Middleton Library',
          'distanceMiles': 0.2,
          'deliveryFee': 2.5,
          'totalPay': 3.65,
          'status': 'requested',
          'createdAt': '2026-10-20T14:00:00Z',
          'updatedAt': '2026-10-20T14:00:00Z',
        });
        return http.Response(jsonEncode(orders.last), 201);
      }
      if (request.method == 'DELETE') {
        expect(request.url.path, '/orders/11');
        expect(jsonDecode(request.body), {'customerId': 6});
        orders.clear();
        return http.Response('', 204);
      }
      expect(request.url.queryParameters['customerId'], '6');
      return http.Response(jsonEncode(orders), 200);
    });
    ApiCustomerOrderService service() => ApiCustomerOrderService(
      preferences: prefs,
      client: client,
      baseUrl: 'http://test',
    );
    final api = service();
    final order = await api.createOrder(
      'demo-customer:taylor',
      DeliveryRequestDraft(
        orderName: 'Taylor',
        restaurant: 'Sonic',
        orderNumber: 'PP-123',
        pickup: campusLocations[0],
        dropoff: campusLocations[1],
        tipCents: 115,
      ),
    );
    expect(order.customerId, '6');
    expect(order.pickupRestaurant, 'Sonic');
    expect(order.totalPayCents, 365);
    final reloaded = service();
    expect(
      (await reloaded.fetchOrders('demo-customer:taylor')).single.id,
      '11',
    );
    expect(registrations, 1);
    await reloaded.deleteOrder('demo-customer:taylor', '11');
    expect(await reloaded.fetchOrders('demo-customer:taylor'), isEmpty);
  });

  test(
    'a reused ID after database reset cannot attach to another customer',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('customer.apiUser.v1:http://test:taylor', 6);
      final client = MockClient((request) async {
        if (request.url.path == '/users/6') {
          return http.Response('{"id":6,"name":"Sam","role":"customer"}', 200);
        }
        if (request.url.path == '/users') {
          return http.Response(
            '{"id":7,"name":"taylor","role":"customer"}',
            201,
          );
        }
        expect(request.url.queryParameters['customerId'], '7');
        return http.Response('[]', 200);
      });
      final api = ApiCustomerOrderService(
        preferences: prefs,
        client: client,
        baseUrl: 'http://test',
      );
      expect(await api.fetchOrders('demo-customer:taylor'), isEmpty);
      expect(prefs.getInt('customer.apiUser.v1:http://test:taylor'), 7);
    },
  );

  test(
    'network errors are reported and a retry can resolve the user again',
    () async {
      final prefs = await SharedPreferences.getInstance();
      var fail = true;
      final client = MockClient((request) async {
        if (fail) throw http.ClientException('offline');
        if (request.url.path == '/users') {
          return http.Response(
            '{"id":8,"name":"taylor","role":"customer"}',
            201,
          );
        }
        return http.Response('[]', 200);
      });
      final api = ApiCustomerOrderService(
        preferences: prefs,
        client: client,
        baseUrl: 'http://test',
      );
      await expectLater(
        api.fetchOrders('demo-customer:taylor'),
        throwsA(isA<CustomerApiException>()),
      );
      fail = false;
      expect(await api.fetchOrders('demo-customer:taylor'), isEmpty);
    },
  );

  test('deletion reports the server status conflict without pretending it succeeded', () async {
    final prefs = await SharedPreferences.getInstance();
    final client = MockClient((request) async {
      if (request.url.path == '/users') {
        return http.Response('{"id":6,"name":"taylor","role":"customer"}', 201);
      }
      return http.Response(
        '{"error":{"code":"invalid_transition","message":"Only waiting requests can be deleted"}}',
        409,
      );
    });
    final api = ApiCustomerOrderService(
      preferences: prefs,
      client: client,
      baseUrl: 'http://test',
    );
    await expectLater(
      api.deleteOrder('demo-customer:taylor', '11'),
      throwsA(
        isA<CustomerApiException>().having(
          (error) => error.statusCode,
          'status',
          409,
        ),
      ),
    );
  });
}
