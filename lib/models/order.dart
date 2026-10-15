/// Delivery status flow: requested -> accepted -> pickedUp -> delivered.
/// An order can only be cancelled while it is still requested.
enum OrderStatus {
  requested,
  accepted,
  pickedUp,
  delivered,
  cancelled;

  /// The status a courier can move this order to next, or null if none.
  OrderStatus? get next => switch (this) {
    OrderStatus.accepted => OrderStatus.pickedUp,
    OrderStatus.pickedUp => OrderStatus.delivered,
    _ => null,
  };
}

/// A delivery request. Money is stored in cents to avoid rounding errors.
///
/// Shared with the customer side; JSON (fromJson/toJson) is added in C-01.
class Order {
  const Order({
    required this.id,
    required this.customerId,
    this.courierId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.distanceMiles,
    required this.deliveryFeeCents,
    required this.tipCents,
    required this.status,
    required this.pawPointsOrderNumber,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.dropoffNote,
    this.customerRating,
    this.customerNote,
  });

  final String id;
  final String customerId;
  final String? courierId;
  final String pickupLocation;
  final String dropoffLocation;
  final double distanceMiles;
  final int deliveryFeeCents;
  final int tipCents;
  final OrderStatus status;
  final String pawPointsOrderNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// K-24: when each delivery step happened; null until it does.
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  /// K-34: optional note left at drop-off, e.g. "Left with the front desk".
  final String? dropoffNote;

  /// K-47: the customer's 1-5 star rating and optional thank-you note,
  /// left after delivery.
  final int? customerRating;
  final String? customerNote;

  /// When the order reached [step], or null if it hasn't yet.
  DateTime? timeOf(OrderStatus step) => switch (step) {
    OrderStatus.requested => createdAt,
    OrderStatus.accepted => acceptedAt,
    OrderStatus.pickedUp => pickedUpAt,
    OrderStatus.delivered => deliveredAt,
    OrderStatus.cancelled => null,
  };

  /// What the courier earns for this delivery.
  int get totalPayCents => deliveryFeeCents + tipCents;

  /// K-38: total pay per mile, in cents. Very short trips count as 0.1 mi
  /// so the number stays sensible.
  int get payPerMileCents =>
      (totalPayCents / (distanceMiles < 0.1 ? 0.1 : distanceMiles)).round();

  /// K-28: the same order back on the open list - no courier, not
  /// accepted. (copyWith can't clear fields, so this builds it directly.)
  Order reopened(DateTime now) => Order(
    id: id,
    customerId: customerId,
    pickupLocation: pickupLocation,
    dropoffLocation: dropoffLocation,
    distanceMiles: distanceMiles,
    deliveryFeeCents: deliveryFeeCents,
    tipCents: tipCents,
    status: OrderStatus.requested,
    pawPointsOrderNumber: pawPointsOrderNumber,
    createdAt: createdAt,
    updatedAt: now,
  );

  Order copyWith({
    String? courierId,
    OrderStatus? status,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? dropoffNote,
    int? customerRating,
    String? customerNote,
  }) {
    return Order(
      id: id,
      customerId: customerId,
      courierId: courierId ?? this.courierId,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      distanceMiles: distanceMiles,
      deliveryFeeCents: deliveryFeeCents,
      tipCents: tipCents,
      status: status ?? this.status,
      pawPointsOrderNumber: pawPointsOrderNumber,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      dropoffNote: dropoffNote ?? this.dropoffNote,
      customerRating: customerRating ?? this.customerRating,
      customerNote: customerNote ?? this.customerNote,
    );
  }
}

/// Formats cents as dollars, e.g. 350 -> "$3.50".
String formatCents(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
