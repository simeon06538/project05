/// Delivery status flow: requested -> accepted -> pickedUp -> delivered.
/// An order can only be cancelled while it is still requested.
enum OrderStatus {
  requested,
  accepted,
  pickedUp,
  delivered,
  cancelled;

  String toJson() => this == pickedUp ? 'picked_up' : name;

  static OrderStatus fromJson(String value) =>
      value == 'picked_up' ? pickedUp : OrderStatus.values.byName(value);

  /// The status a courier can move this order to next, or null if none.
  OrderStatus? get next => switch (this) {
    OrderStatus.accepted => OrderStatus.pickedUp,
    OrderStatus.pickedUp => OrderStatus.delivered,
    _ => null,
  };
}

/// K-51: problems a courier can report on an active delivery. Only
/// [restaurantClosed] cancels the order; the rest flag it for support.
enum DeliveryProblem {
  restaurantClosed('Restaurant is closed', cancelsOrder: true),
  orderNotReady("Order isn't ready (long wait)"),
  cantFindCustomer("Can't find the customer"),
  other('Something else');

  const DeliveryProblem(this.label, {this.cancelsOrder = false});

  final String label;
  final bool cancelsOrder;

  /// The problems that make sense at [status].
  static List<DeliveryProblem> optionsFor(OrderStatus status) =>
      switch (status) {
        OrderStatus.accepted => [restaurantClosed, orderNotReady, other],
        OrderStatus.pickedUp => [cantFindCustomer, other],
        _ => const [],
      };
}

/// A delivery request. Money is stored in cents to avoid rounding errors.
///
/// Shared with the customer side. API money uses dollars; the app uses cents.
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
    this.pickupLocationName,
    this.dropoffLocationName,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.dropoffNote,
    this.customerRating,
    this.customerNote,
    this.problem,
    this.problemDetails,
  });

  /// Reads the server response described in docs/api.md.
  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: (json['id'] as int).toString(),
    customerId: (json['customerId'] as int).toString(),
    courierId: (json['courierId'] as int?)?.toString(),
    pickupLocation: json['pickupLocation'] as String,
    dropoffLocation: json['dropoffLocation'] as String,
    pickupLocationName: json['pickupLocationName'] as String?,
    dropoffLocationName: json['dropoffLocationName'] as String?,
    distanceMiles: (json['distanceMiles'] as num).toDouble(),
    deliveryFeeCents: ((json['deliveryFee'] as num) * 100).round(),
    tipCents: ((json['tip'] as num) * 100).round(),
    status: OrderStatus.fromJson(json['status'] as String),
    pawPointsOrderNumber: json['pawPointsOrderNumber'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  /// Serializes the API model, not a POST /orders request body.
  /// Demo-only string IDs cannot be sent to the real server.
  Map<String, dynamic> toJson() => {
    'id': int.parse(id),
    'customerId': int.parse(customerId),
    'courierId': courierId == null ? null : int.parse(courierId!),
    'pickupLocation': pickupLocation,
    'pickupLocationName': pickupLocationName,
    'dropoffLocation': dropoffLocation,
    'dropoffLocationName': dropoffLocationName,
    'distanceMiles': distanceMiles,
    'deliveryFee': deliveryFeeCents / 100,
    'tip': tipCents / 100,
    'totalPay': totalPayCents / 100,
    'status': status.toJson(),
    'pawPointsOrderNumber': pawPointsOrderNumber,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  final String id;
  final String customerId;
  final String? courierId;
  final String pickupLocation;
  final String dropoffLocation;
  final String? pickupLocationName;
  final String? dropoffLocationName;
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

  /// K-51: a problem the courier reported, and any extra details.
  final DeliveryProblem? problem;
  final String? problemDetails;

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
    pickupLocationName: pickupLocationName,
    dropoffLocationName: dropoffLocationName,
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
    DeliveryProblem? problem,
    String? problemDetails,
  }) {
    return Order(
      id: id,
      customerId: customerId,
      courierId: courierId ?? this.courierId,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      pickupLocationName: pickupLocationName,
      dropoffLocationName: dropoffLocationName,
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
      problem: problem ?? this.problem,
      problemDetails: problemDetails ?? this.problemDetails,
    );
  }
}

/// Formats cents as dollars, e.g. 350 -> "$3.50".
String formatCents(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
