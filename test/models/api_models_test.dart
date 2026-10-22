import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> orderJson() => {
    'id': 12,
    'customerId': 1,
    'courierId': null,
    'pickupLocation': 'union',
    'pickupLocationName': 'LSU Student Union',
    'dropoffLocation': 'west-campus-apts',
    'dropoffLocationName': 'West Campus Apartments',
    'distanceMiles': 1,
    'deliveryFee': 4,
    'tip': 1.15,
    'totalPay': 5.15,
    'status': 'requested',
    'pawPointsOrderNumber': 'PP-10442',
    'createdAt': '2026-10-16T18:04:11.123Z',
    'updatedAt': '2026-10-16T18:04:11.123Z',
  };

  test('server order round trip preserves IDs, location names and money', () {
    final json = orderJson();
    final order = Order.fromJson(json);
    expect(order.id, '12');
    expect(order.courierId, isNull);
    expect(order.tipCents, 115);
    expect(order.totalPayCents, 515);
    expect(order.toJson(), json);
    expect(order.copyWith().pickupLocationName, 'LSU Student Union');
    expect(
      order.reopened(DateTime.now()).dropoffLocationName,
      'West Campus Apartments',
    );
  });

  test('all server statuses round trip including picked_up', () {
    for (final status in [
      'requested',
      'accepted',
      'picked_up',
      'delivered',
      'cancelled',
    ]) {
      final json = orderJson()..['status'] = status;
      json['courierId'] = 4;
      final order = Order.fromJson(json);
      expect(order.courierId, '4');
      expect(order.toJson()['status'], status);
      expect(order.toJson()['courierId'], 4);
    }
    expect(OrderStatus.fromJson('picked_up'), OrderStatus.pickedUp);
    expect(() => OrderStatus.fromJson('unknown'), throwsArgumentError);
  });

  test('order supports missing optional display names and UTC timestamps', () {
    final json = orderJson()
      ..remove('pickupLocationName')
      ..remove('dropoffLocationName');
    json['createdAt'] = '2026-10-16T13:04:11.123-05:00';
    final order = Order.fromJson(json);
    expect(order.pickupLocationName, isNull);
    expect(order.toJson()['createdAt'], '2026-10-16T18:04:11.123Z');
  });

  test('both user roles round trip with nullable email and demo earnings', () {
    for (final role in ['customer', 'courier']) {
      final json = <String, dynamic>{
        'id': 4,
        'name': 'Alex',
        'email': role == 'customer' ? null : 'alex@example.edu',
        'role': role,
        'earnings': role == 'customer' ? 0 : 10.15,
      };
      final user = User.fromJson(json);
      expect(user.earningsCents, role == 'customer' ? 0 : 1015);
      expect(user.toJson(), json);
    }
    expect(
      () => User.fromJson({
        'id': 1,
        'name': 'Alex',
        'role': 'admin',
        'earnings': 0,
      }),
      throwsArgumentError,
    );
  });
}
