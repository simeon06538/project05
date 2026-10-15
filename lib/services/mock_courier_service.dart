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
  int _failuresLeft = 0;
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
    final now = DateTime.now();
    return _orders[orderId] = order.copyWith(
      courierId: courierId,
      status: OrderStatus.accepted,
      updatedAt: now,
      acceptedAt: now,
    );
  }

  @override
  Future<Order> updateStatus(
    String orderId,
    OrderStatus newStatus, {
    String? dropoffNote,
  }) async {
    await _delay();
    final order = _find(orderId);
    if (order.status.next != newStatus) {
      throw InvalidStatusChangeException(order.status, newStatus);
    }
    final now = DateTime.now();
    final updated = _orders[orderId] = order.copyWith(
      status: newStatus,
      updatedAt: now,
      pickedUpAt: newStatus == OrderStatus.pickedUp ? now : null,
      deliveredAt: newStatus == OrderStatus.delivered ? now : null,
      // K-47 demo: the customer rates the delivery straight away.
      customerRating: newStatus == OrderStatus.delivered
          ? _demoRating(order)
          : null,
      customerNote: newStatus == OrderStatus.delivered
          ? _demoNote(order)
          : null,
      dropoffNote:
          newStatus == OrderStatus.delivered &&
              (dropoffNote?.trim().isNotEmpty ?? false)
          ? dropoffNote!.trim()
          : null,
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
  Future<Order> reportProblem(
    String orderId,
    String courierId,
    DeliveryProblem problem, {
    String? details,
  }) async {
    await _delay();
    final order = _find(orderId);
    if (order.courierId != courierId) {
      throw NotYourDeliveryException(orderId);
    }
    if (!DeliveryProblem.optionsFor(order.status).contains(problem)) {
      throw InvalidStatusChangeException(order.status, OrderStatus.cancelled);
    }
    final trimmed = details?.trim();
    return _orders[orderId] = order.copyWith(
      status: problem.cancelsOrder ? OrderStatus.cancelled : null,
      updatedAt: DateTime.now(),
      problem: problem,
      problemDetails: (trimmed?.isEmpty ?? true) ? null : trimmed,
    );
  }

  @override
  Future<Order> releaseDelivery(String orderId, String courierId) async {
    await _delay();
    final order = _find(orderId);
    if (order.courierId != courierId) {
      throw NotYourDeliveryException(orderId);
    }
    if (order.status != OrderStatus.accepted) {
      throw InvalidStatusChangeException(order.status, OrderStatus.requested);
    }
    return _orders[orderId] = order.reopened(DateTime.now());
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

  /// Makes the next [count] service calls throw
  /// [ServiceUnavailableException], to test and demo error states (K-14).
  void failNextCalls([int count = 1]) => _failuresLeft = count;

  Future<void> _delay() async {
    if (latency != Duration.zero) await Future<void>.delayed(latency);
    if (_failuresLeft > 0) {
      _failuresLeft--;
      throw const ServiceUnavailableException();
    }
  }

  static const _thankYouNotes = [
    'Thanks for the quick delivery!',
    'Still hot - thank you!',
    null,
    'Super friendly, thanks!',
    'Right on time, appreciate it.',
  ];

  /// Same order, same rating, so demos and tests are predictable.
  int _demoSeed(Order order) => order.id.codeUnits.fold(0, (a, b) => a + b);
  int _demoRating(Order order) => _demoSeed(order) % 4 == 0 ? 4 : 5;
  String? _demoNote(Order order) =>
      _thankYouNotes[_demoSeed(order) % _thankYouNotes.length];

  /// K-31: puts everything back to how the demo started - the five open
  /// requests, no active deliveries and zero balances - plus a week of
  /// history for [withHistoryFor] if given.
  void resetDemo({String? withHistoryFor}) {
    final now = DateTime.now();
    _orders.clear();
    _balances.clear();
    _nextDemo = 0;
    _failuresLeft = 0;
    _lastNewRequest = now;
    _seed(now);
    if (withHistoryFor != null) seedHistory(withHistoryFor, now: now);
  }

  void _seed(DateTime now) {
    // Fees follow the TASKS.txt rule: $2.00 + $0.50 per started 0.25 mi
    // from the Union, capped at $6.00.
    final seed = [
      ('Student Union · Grill', 'Library · Main entrance', 0.4, 300, 100, 18),
      ('Student Union · Starbucks', 'Engineering Hall', 0.7, 350, 200, 9),
      ('Student Union · Chick-fil-A', 'North Residence Hall', 1.1, 450, 0, 6),
      ('Student Union · Panda Express', 'Rec Center', 0.9, 400, 300, 4),
      (
        'Student Union · Subway',
        'Science Building · Room 120',
        0.3,
        300,
        150,
        1,
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

  /// K-25 demo data: a week of past deliveries for [courierId], so the
  /// earnings chart has something to show. Adds their pay to the balance.
  void seedHistory(String courierId, {DateTime? now}) {
    const history = [
      // (days ago, pickup, drop-off, miles, fee, tip)
      (1, 'Student Union · Starbucks', 'Music Building', 0.5, 300, 200),
      (1, 'Student Union · Grill', 'Rec Center', 0.9, 400, 100),
      (2, 'Student Union · Subway', 'Business Building', 0.6, 350, 0),
      (
        3,
        'Student Union · Panda Express',
        'North Residence Hall',
        1.1,
        450,
        300,
      ),
      (
        3,
        'Student Union · Taco Bell',
        'Library · Main entrance',
        0.4,
        300,
        150,
      ),
      (3, 'Student Union · Grill', 'Engineering Hall', 0.7, 350, 100),
      (5, 'Student Union · Chick-fil-A', 'Stadium · Gate 4', 1.4, 500, 250),
      (
        6,
        'Student Union · Starbucks',
        'Science Building · Room 120',
        0.3,
        300,
        0,
      ),
    ];
    final today = now ?? DateTime.now();
    for (final (daysAgo, pickup, dropoff, miles, fee, tip) in history) {
      // Lunchtime on that calendar day, so it always lands on the right
      // day even when "now" is just after midnight.
      final delivered = DateTime(
        today.year,
        today.month,
        today.day - daysAgo,
        12,
        30,
      );
      final created = delivered.subtract(const Duration(minutes: 25));
      final order = _add(pickup, dropoff, miles, fee, tip, created);
      _orders[order.id] = order.copyWith(
        courierId: courierId,
        status: OrderStatus.delivered,
        updatedAt: delivered,
        acceptedAt: created.add(const Duration(minutes: 3)),
        pickedUpAt: created.add(const Duration(minutes: 12)),
        deliveredAt: delivered,
        // K-34 demo: yesterday's deliveries came with a drop-off note.
        dropoffNote: daysAgo == 1 ? 'Left with the front desk' : null,
        customerRating: _demoRating(order),
        customerNote: _demoNote(order),
      );
      _balances.update(
        courierId,
        (cents) => cents + order.totalPayCents,
        ifAbsent: () => order.totalPayCents,
      );
    }
  }

  /// Simulates a different courier accepting [orderId], so the "someone
  /// else got it first" path (K-13) can be tested and demoed. Does nothing
  /// if the order is no longer open.
  void takeByOtherCourier(String orderId) {
    final order = _orders[orderId];
    if (order == null || order.status != OrderStatus.requested) return;
    _orders[orderId] = order.copyWith(
      courierId: 'other-courier',
      status: OrderStatus.accepted,
      updatedAt: DateTime.now(),
    );
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
