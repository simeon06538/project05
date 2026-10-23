import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/services/api_courier_service.dart';
import 'package:campus_delivery/services/courier_service.dart';

const _alex = 'demo-courier:Alex';

/// A small in-memory copy of Person 3's server rules (docs/api.md):
/// users, atomic accept, ordered status changes and courier earnings.
class _FakeServer {
  final users = <int, Map<String, dynamic>>{
    4: {'id': 4, 'name': 'Taylor Courier', 'role': 'courier', 'earnings': 0},
  };
  final orders = <int, Map<String, dynamic>>{};
  final calls = <String>[];
  int _nextUserId = 6;

  void addOrder(
    int id, {
    String restaurant = 'Popeyes',
    double fee = 3.5,
    double tip = 1,
  }) {
    orders[id] = {
      'id': id,
      'customerId': 1,
      'courierId': null,
      'pickupLocation': 'the-5',
      'pickupLocationName': 'The 5',
      'dropoffLocation': 'spruce-hall',
      'dropoffLocationName': 'Spruce Hall',
      'distanceMiles': 0.6,
      'deliveryFee': fee,
      'tip': tip,
      'totalPay': fee + tip,
      'status': 'requested',
      'pawPointsOrderNumber': 'PP-$id',
      'orderName': 'Taylor',
      'pickupRestaurant': restaurant,
      'createdAt': '2026-10-20T14:00:00.000Z',
      'updatedAt': '2026-10-20T14:00:00.000Z',
    };
  }

  http.Response _json(Object? body, [int status = 200]) =>
      http.Response(jsonEncode(body), status);

  http.Response _error(int status, String code, String message) => _json({
    'error': {'code': code, 'message': message},
  }, status);

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    final body = request.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    calls.add('${request.method} ${request.url.path}');
    final parts = path.split('/')..removeAt(0);

    if (request.method == 'POST' && path == '/users') {
      final id = _nextUserId++;
      users[id] = {
        'id': id,
        'name': body['name'],
        'role': body['role'],
        'earnings': 0,
      };
      return _json(users[id], 201);
    }
    if (request.method == 'GET' && parts.first == 'users') {
      final user = users[int.parse(parts[1])];
      return user == null
          ? _error(404, 'not_found', 'User ${parts[1]} not found')
          : _json(user);
    }
    if (request.method == 'GET' && path == '/orders') {
      final query = request.url.queryParameters;
      final statuses = query['status']?.split(',');
      final courier = int.tryParse(query['courierId'] ?? '');
      return _json([
        for (final o in orders.values)
          if ((statuses == null || statuses.contains(o['status'])) &&
              (courier == null || o['courierId'] == courier))
            o,
      ]);
    }
    if (parts.first == 'orders') {
      final id = int.parse(parts[1]);
      final order = orders[id];
      if (order == null) return _error(404, 'not_found', 'Order $id not found');
      if (parts.length == 2) return _json(order);
      final courierId = body['courierId'] as int;
      if (parts[2] == 'accept') {
        if (users[courierId]?['role'] != 'courier') {
          return _error(404, 'not_found', 'Courier $courierId not found');
        }
        final busy = orders.values.any(
          (o) =>
              o['courierId'] == courierId &&
              ['accepted', 'picked_up'].contains(o['status']),
        );
        if (busy) return _error(409, 'courier_busy', 'Courier is busy');
        if (order['status'] != 'requested') {
          return _error(409, 'already_accepted', 'Order $id is taken');
        }
        order['status'] = 'accepted';
        order['courierId'] = courierId;
        order['updatedAt'] = '2026-10-20T14:05:00.000Z';
        return _json(order);
      }
      final next = {'accepted': 'picked_up', 'picked_up': 'delivered'};
      if (next[order['status']] != body['status']) {
        return _error(409, 'invalid_transition', 'Cannot change order $id');
      }
      if (order['courierId'] != courierId) {
        return _error(403, 'forbidden', 'Courier $courierId is not on $id');
      }
      order['status'] = body['status'];
      order['updatedAt'] = body['status'] == 'delivered'
          ? '2026-10-20T14:20:00.000Z'
          : '2026-10-20T14:10:00.000Z';
      if (body['status'] == 'delivered') {
        users[courierId]!['earnings'] += order['totalPay'] as num;
      }
      return _json(order);
    }
    if (request.method == 'GET' && parts.first == 'couriers') {
      final id = int.parse(parts[1]);
      final courier = users[id];
      if (courier?['role'] != 'courier') {
        return _error(404, 'not_found', 'Courier $id not found');
      }
      return _json({'courierId': id, 'earnings': courier!['earnings']});
    }
    return _error(404, 'not_found', 'No route for $path');
  }
}

Future<(ApiCourierService, _FakeServer)> _service({_FakeServer? server}) async {
  final fake = server ?? _FakeServer();
  final service = ApiCourierService(
    preferences: await SharedPreferences.getInstance(),
    client: MockClient((request) => fake.handle(request)),
    baseUrl: 'http://test',
  );
  return (service, fake);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('open requests read as "Building · Restaurant" in cents', () async {
    final (service, server) = await _service();
    server.addOrder(7);

    final order = (await service.fetchAvailableRequests()).single;

    expect(service.isServerBacked, isTrue);
    expect(order.id, '7');
    expect(order.pickupLocation, 'The 5 · Popeyes');
    expect(order.dropoffLocation, 'Spruce Hall');
    expect(order.deliveryFeeCents, 350);
    expect(order.tipCents, 100);
    expect(order.status, OrderStatus.requested);
    expect(order.createdAt.isUtc, isFalse);
    expect(
      order.createdAt,
      DateTime.parse('2026-10-20T14:00:00.000Z').toLocal(),
    );
  });

  test(
    'a courier name is registered once and reused after a restart',
    () async {
      final server = _FakeServer();
      final (first, _) = await _service(server: server);
      expect(await first.fetchActiveDelivery(_alex), isNull);
      expect(server.users[6], containsPair('name', 'Alex'));
      expect(server.users[6], containsPair('role', 'courier'));

      final (reopened, _) = await _service(server: server);
      await reopened.fetchActiveDelivery('demo-courier:alex');

      expect(server.calls.where((c) => c == 'POST /users'), hasLength(1));
      expect(server.calls, contains('GET /users/6'));
    },
  );

  test('accept, pick up and deliver; the pay reaches earnings', () async {
    final (service, server) = await _service();
    server.addOrder(7);

    final accepted = await service.acceptRequest('7', _alex);
    expect(accepted.status, OrderStatus.accepted);
    expect(accepted.courierId, '6');
    expect(accepted.acceptedAt, isNotNull);
    expect((await service.fetchActiveDelivery(_alex))?.id, '7');

    final pickedUp = await service.updateStatus('7', OrderStatus.pickedUp);
    expect(pickedUp.status, OrderStatus.pickedUp);
    expect(pickedUp.acceptedAt, accepted.acceptedAt);
    expect(pickedUp.pickedUpAt, isNotNull);

    final delivered = await service.updateStatus(
      '7',
      OrderStatus.delivered,
      dropoffNote: '  Left with the front desk ',
    );
    expect(delivered.deliveredAt, isNotNull);
    expect(delivered.dropoffNote, 'Left with the front desk');
    expect(await service.fetchActiveDelivery(_alex), isNull);

    final earnings = await service.fetchEarnings(_alex);
    expect(earnings.balanceCents, 450);
    expect(earnings.completedDeliveries.single.id, '7');
    expect(
      earnings.completedDeliveries.single.dropoffNote,
      'Left with the front desk',
    );
  });

  test('accept errors become the exceptions the screens handle', () async {
    final (service, server) = await _service();
    server
      ..addOrder(7)
      ..addOrder(8)
      ..addOrder(9);
    await service.acceptRequest('7', 'demo-courier:Riley');

    await expectLater(
      service.acceptRequest('7', _alex),
      throwsA(isA<OrderAlreadyTakenException>()),
    );
    await expectLater(
      service.acceptRequest('99', _alex),
      throwsA(isA<OrderNotFoundException>()),
    );
    await service.acceptRequest('8', _alex);
    await expectLater(
      service.acceptRequest('9', _alex),
      throwsA(isA<ActiveDeliveryException>()),
    );
  });

  test('status errors become the exceptions the screens handle', () async {
    final (service, server) = await _service();
    server.addOrder(7);
    await expectLater(
      service.updateStatus('7', OrderStatus.pickedUp),
      throwsA(isA<NotYourDeliveryException>()),
    );

    await service.acceptRequest('7', _alex);
    await expectLater(
      service.updateStatus('7', OrderStatus.delivered),
      throwsA(
        isA<InvalidStatusChangeException>()
            .having((e) => e.from, 'from', OrderStatus.accepted)
            .having((e) => e.to, 'to', OrderStatus.delivered),
      ),
    );
  });

  test('a courier removed by a demo reset is registered again', () async {
    final (service, server) = await _service();
    server.addOrder(7);
    await service.fetchActiveDelivery(_alex);
    server.users.remove(6);

    final accepted = await service.acceptRequest('7', _alex);

    expect(accepted.courierId, '7');
    expect(server.users[7], containsPair('name', 'Alex'));
  });

  test('an unreachable server is a ServiceUnavailableException', () async {
    final service = ApiCourierService(
      preferences: await SharedPreferences.getInstance(),
      client: MockClient((_) => throw const _DroppedConnection()),
      baseUrl: 'http://test',
    );

    await expectLater(
      service.fetchAvailableRequests(),
      throwsA(isA<ServiceUnavailableException>()),
    );
  });

  test('release and problem reports are not on the server yet', () async {
    final (service, _) = await _service();

    await expectLater(
      service.releaseDelivery('7', _alex),
      throwsUnsupportedError,
    );
    await expectLater(
      service.reportProblem('7', _alex, DeliveryProblem.other),
      throwsUnsupportedError,
    );
  });
}

/// What a dropped connection looks like to the client.
class _DroppedConnection implements Exception {
  const _DroppedConnection();
}
