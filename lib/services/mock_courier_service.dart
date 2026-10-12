import '../models/order.dart';
import 'courier_service.dart';

/// In-memory [CourierService] with fake campus orders, so the courier
/// screens can be built and demoed before the real server exists.
///
/// Follows the same rules the server will enforce: one courier per order,
/// one active delivery per courier, and status changes only in order.
class MockCourierService implements CourierService {
  MockCourierService({
    this.latency = const Duration(milliseconds: 400),
    DateTime? now,
  }) {
    _seed(now ?? DateTime.now());
  }

  /// Fake network delay so loading spinners can be seen. Use
  /// [Duration.zero] in tests.
  final Duration latency;

  final Map<String, Order> _orders = {};
  final Map<String, int> _balances = {};

  @override
  Future<List<Order>> fetchAvailableRequests() async {
    await _delay();
    return _orders.values
        .where((o) => o.status == OrderStatus.requested)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<Order?> fetchActiveDelivery(String courierId) async {
    await _delay();
    return _activeFor(courierId);
  }

  @override
  Future<Order> acceptRequest(String orderId, String courierId) async {
    await _delay();
    final order = _find(orderId);
    if (order.status != OrderStatus.requested) {
      throw OrderAlreadyTakenException(orderId);
    }
    if (_activeFor(courierId) != null) {
      throw const ActiveDeliveryException();
    }
    return _orders[orderId] = order.copyWith(
      courierId: courierId,
      status: OrderStatus.accepted,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Order> updateStatus(String orderId, OrderStatus newStatus) async {
    await _delay();
    final order = _find(orderId);
    if (order.status.next != newStatus) {
      throw InvalidStatusChangeException(order.status, newStatus);
    }
    final updated = _orders[orderId] = order.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    if (newStatus == OrderStatus.delivered) {
      _balances.update(
        updated.courierId!,
        (cents) => cents + updated.totalPayCents,
        ifAbsent: () => updated.totalPayCents,
      );
    }
    return updated;
  }

  @override
  Future<CourierEarnings> fetchEarnings(String courierId) async {
    await _delay();
    final completed =
        _orders.values
            .where(
              (o) =>
                  o.courierId == courierId && o.status == OrderStatus.delivered,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return CourierEarnings(
      balanceCents: _balances[courierId] ?? 0,
      completedDeliveries: completed,
    );
  }

  Order _find(String orderId) {
    final order = _orders[orderId];
    if (order == null) throw OrderNotFoundException(orderId);
    return order;
  }

  Order? _activeFor(String courierId) {
    for (final o in _orders.values) {
      if (o.courierId == courierId &&
          (o.status == OrderStatus.accepted ||
              o.status == OrderStatus.pickedUp)) {
        return o;
      }
    }
    return null;
  }

  Future<void> _delay() =>
      latency == Duration.zero ? Future.value() : Future.delayed(latency);

  void _seed(DateTime now) {
    // Fees follow the TASKS.txt rule: $2.00 + $0.50 per started 0.25 mi
    // from the Union, capped at $6.00.
    final seed = [
      ('Student Union · Grill', 'Library · Main entrance', 0.4, 300, 100, 12),
      ('Student Union · Starbucks', 'Engineering Hall', 0.7, 350, 200, 9),
      ('Student Union · Chick-fil-A', 'North Residence Hall', 1.1, 450, 0, 6),
      ('Student Union · Panda Express', 'Rec Center', 0.9, 400, 300, 4),
      (
        'Student Union · Subway',
        'Science Building · Room 120',
        0.3,
        300,
        150,
        2,
      ),
    ];
    for (var i = 0; i < seed.length; i++) {
      final (pickup, dropoff, miles, fee, tip, minutesAgo) = seed[i];
      final created = now.subtract(Duration(minutes: minutesAgo));
      final id = 'order-${i + 1}';
      _orders[id] = Order(
        id: id,
        customerId: 'customer-${i + 1}',
        pickupLocation: pickup,
        dropoffLocation: dropoff,
        distanceMiles: miles,
        deliveryFeeCents: fee,
        tipCents: tip,
        status: OrderStatus.requested,
        pawPointsOrderNumber: 'PP-${4810 + i * 7}',
        createdAt: created,
        updatedAt: created,
      );
    }
  }
}
