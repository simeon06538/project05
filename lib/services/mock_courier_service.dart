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
    this.newRequestEvery,
    DateTime? now,
  }) {
    final start = now ?? DateTime.now();
    _lastNewRequest = start;
    _seed(start);
  }

  /// Fake network delay so loading spinners can be seen. Use
  /// [Duration.zero] in tests.
  final Duration latency;

  /// When set, a new demo request shows up roughly this often (checked on
  /// each fetch), so refreshing the Available list has something to show.
  final Duration? newRequestEvery;

  late DateTime _lastNewRequest;
  int _nextDemo = 0;

  final Map<String, Order> _orders = {};
  final Map<String, int> _balances = {};

  @override
  Future<List<Order>> fetchAvailableRequests() async {
    await _delay();
    final every = newRequestEvery;
    if (every != null && DateTime.now().difference(_lastNewRequest) >= every) {
      addDemoRequest();
    }
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
    for (final (pickup, dropoff, miles, fee, tip, minutesAgo) in seed) {
      _add(
        pickup,
        dropoff,
        miles,
        fee,
        tip,
        now.subtract(Duration(minutes: minutesAgo)),
      );
    }
  }

  /// Adds a new open request from a small rotating list of campus spots,
  /// as if a customer just ordered. Returns the new order.
  Order addDemoRequest({DateTime? now}) {
    const pool = [
      ('Student Union · Taco Bell', 'Business Building', 0.6, 350, 100),
      ('Student Union · Grill', 'South Residence Hall', 1.0, 400, 0),
      ('Student Union · Starbucks', 'Music Building', 0.5, 300, 250),
      ('Student Union · Subway', 'Stadium · Gate 4', 1.4, 500, 200),
    ];
    final (pickup, dropoff, miles, fee, tip) = pool[_nextDemo % pool.length];
    _nextDemo++;
    final created = now ?? DateTime.now();
    _lastNewRequest = created;
    return _add(pickup, dropoff, miles, fee, tip, created);
  }

  Order _add(
    String pickup,
    String dropoff,
    double miles,
    int feeCents,
    int tipCents,
    DateTime created,
  ) {
    final n = _orders.length + 1;
    final id = 'order-$n';
    return _orders[id] = Order(
      id: id,
      customerId: 'customer-$n',
      pickupLocation: pickup,
      dropoffLocation: dropoff,
      distanceMiles: miles,
      deliveryFeeCents: feeCents,
      tipCents: tipCents,
      status: OrderStatus.requested,
      pawPointsOrderNumber: 'PP-${4803 + n * 7}',
      createdAt: created,
      updatedAt: created,
    );
  }
}
