import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/delivery_request_draft.dart';
import '../models/order.dart';
import 'customer_order_service.dart';
import 'sample_customer_orders.dart';

/// C-12: local demo storage. This service never contacts the server/couriers.
/// Customer IDs are demo identities, not authenticated accounts.
class MockCustomerOrderService implements CustomerOrderService {
  @override
  bool get isServerBacked => false;
  MockCustomerOrderService({
    this.preferences,
    this.seedExamples = true,
    List<Order> initialOrders = const [],
  }) {
    final saved = preferences?.getString(storageKey);
    if (saved == null) {
      _orders = List.of(initialOrders);
    } else {
      final json = jsonDecode(saved) as Map<String, dynamic>;
      _orders = (json['orders'] as List)
          .map((value) => _decode(Map<String, dynamic>.from(value as Map)))
          .toList();
      _seededOwners.addAll((json['seededOwners'] as List).cast<String>());
      for (final entry in (json['details'] as Map<String, dynamic>).entries) {
        _details[entry.key] = Map<String, dynamic>.from(entry.value as Map);
      }
    }
  }

  static const storageKey = 'customer.mockOrders.v1';
  final SharedPreferences? preferences;
  final bool seedExamples;
  late List<Order> _orders;
  final Set<String> _seededOwners = {};
  final Map<String, Map<String, dynamic>> _details = {};
  Future<void> _pending = Future.value();
  int _sequence = 0;

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<void> _save(
    List<Order> orders,
    Set<String> owners,
    Map<String, Map<String, dynamic>> details,
  ) async {
    final saved = await preferences?.setString(
      storageKey,
      jsonEncode({
        'orders': orders.map(_encode).toList(),
        'seededOwners': owners.toList(),
        'details': details,
      }),
    );
    if (saved == false) {
      throw StateError('Could not save demo orders. Try again.');
    }
    _orders = orders;
    _seededOwners
      ..clear()
      ..addAll(owners);
    _details
      ..clear()
      ..addAll(details);
  }

  @override
  Future<List<Order>> fetchOrders(String customerId) => _serial(() async {
    if (seedExamples && !_seededOwners.contains(customerId)) {
      final examples = sampleCustomerOrders().map((order) {
        final json = _encode(order)..['customerId'] = customerId;
        json['id'] = '$customerId:${order.id}';
        return _decode(json);
      });
      await _save(
        [..._orders, ...examples],
        {..._seededOwners, customerId},
        Map.of(_details),
      );
    }
    return _orders.where((order) => order.customerId == customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<Order> createOrder(String customerId, DeliveryRequestDraft draft) =>
      _serial(() async {
        if (customerId.trim().isEmpty ||
            draft.orderName.trim().isEmpty ||
            draft.restaurant.trim().isEmpty ||
            draft.orderNumber.trim().isEmpty ||
            draft.orderNumber.trim().length > 40 ||
            draft.pickup.id == draft.dropoff.id ||
            draft.tipCents < 0 ||
            draft.tipCents > 5000) {
          throw ArgumentError('Invalid delivery request details.');
        }
        final now = DateTime.now().toUtc();
        final order = Order(
          id: 'demo-${now.microsecondsSinceEpoch}-${_sequence++}',
          customerId: customerId,
          orderName: draft.orderName.trim(),
          pickupRestaurant: draft.restaurant.trim(),
          pickupLocation: draft.pickup.id,
          pickupLocationName:
              '${draft.pickup.name} · ${draft.restaurant.trim()}',
          dropoffLocation: draft.dropoff.id,
          dropoffLocationName: draft.dropoff.name,
          distanceMiles: draft.distanceMiles,
          deliveryFeeCents: draft.feeCents,
          tipCents: draft.tipCents,
          status: OrderStatus.requested,
          pawPointsOrderNumber: draft.orderNumber.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await _save(
          [..._orders, order],
          Set.of(_seededOwners),
          {
            ..._details,
            order.id: {
              'orderName': draft.orderName.trim(),
              'restaurant': draft.restaurant.trim(),
            },
          },
        );
        return order;
      });

  @override
  Future<void> deleteOrder(String customerId, String orderId) => _serial(
    () async {
      final order = _orders.where((order) => order.id == orderId).firstOrNull;
      if (order == null || order.customerId != customerId) {
        throw StateError('This request does not belong to this customer.');
      }
      if (order.status != OrderStatus.requested) {
        throw StateError('Only requests waiting for a courier can be deleted.');
      }
      final details = Map.of(_details)..remove(orderId);
      await _save(
        _orders.where((order) => order.id != orderId).toList(),
        Set.of(_seededOwners),
        details,
      );
    },
  );

  // Local format preserves demo string IDs without changing the server model.
  static Map<String, dynamic> _encode(Order order) => {
    'orderName': order.orderName,
    'pickupRestaurant': order.pickupRestaurant,
    'id': order.id,
    'customerId': order.customerId,
    'courierId': order.courierId,
    'pickupLocation': order.pickupLocation,
    'pickupLocationName': order.pickupLocationName,
    'dropoffLocation': order.dropoffLocation,
    'dropoffLocationName': order.dropoffLocationName,
    'distanceMiles': order.distanceMiles,
    'deliveryFeeCents': order.deliveryFeeCents,
    'tipCents': order.tipCents,
    'status': order.status.toJson(),
    'pawPointsOrderNumber': order.pawPointsOrderNumber,
    'createdAt': order.createdAt.toUtc().toIso8601String(),
    'updatedAt': order.updatedAt.toUtc().toIso8601String(),
  };

  static Order _decode(Map<String, dynamic> json) => Order(
    orderName: json['orderName'] as String?,
    pickupRestaurant: json['pickupRestaurant'] as String?,
    id: json['id'] as String,
    customerId: json['customerId'] as String,
    courierId: json['courierId'] as String?,
    pickupLocation: json['pickupLocation'] as String,
    pickupLocationName: json['pickupLocationName'] as String?,
    dropoffLocation: json['dropoffLocation'] as String,
    dropoffLocationName: json['dropoffLocationName'] as String?,
    distanceMiles: (json['distanceMiles'] as num).toDouble(),
    deliveryFeeCents: json['deliveryFeeCents'] as int,
    tipCents: json['tipCents'] as int,
    status: OrderStatus.fromJson(json['status'] as String),
    pawPointsOrderNumber: json['pawPointsOrderNumber'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
