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

  Order copyWith({
    String? courierId,
    OrderStatus? status,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
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
    );
  }
}

/// Formats cents as dollars, e.g. 350 -> "$3.50".
String formatCents(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
