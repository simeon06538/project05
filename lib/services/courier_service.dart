import '../models/order.dart';

/// Everything the courier screens need from the backend.
///
/// [MockCourierService] implements this with fake data for now; K-12 adds
/// a real implementation that calls Person 3's API, and the screens don't
/// have to change.
abstract class CourierService {
  /// Open requests no courier has accepted yet (status == requested).
  Future<List<Order>> fetchAvailableRequests();

  /// The courier's current accepted or picked-up order, if any.
  Future<Order?> fetchActiveDelivery(String courierId);

  /// Assigns the order to this courier.
  ///
  /// Throws [OrderAlreadyTakenException] if someone else got it first, and
  /// [ActiveDeliveryException] if this courier already has an active job.
  Future<Order> acceptRequest(String orderId, String courierId);

  /// Moves the order to its next status (accepted -> pickedUp -> delivered).
  ///
  /// Throws [InvalidStatusChangeException] for any other transition.
  Future<Order> updateStatus(String orderId, OrderStatus newStatus);

  /// Demo balance plus completed deliveries, newest first.
  Future<CourierEarnings> fetchEarnings(String courierId);
}

class CourierEarnings {
  const CourierEarnings({
    required this.balanceCents,
    required this.completedDeliveries,
  });

  final int balanceCents;
  final List<Order> completedDeliveries;
}

class OrderNotFoundException implements Exception {
  const OrderNotFoundException(this.orderId);
  final String orderId;

  @override
  String toString() => 'Order $orderId was not found.';
}

class OrderAlreadyTakenException implements Exception {
  const OrderAlreadyTakenException(this.orderId);
  final String orderId;

  @override
  String toString() => 'This request was already accepted by another courier.';
}

class ActiveDeliveryException implements Exception {
  const ActiveDeliveryException();

  @override
  String toString() => 'Finish your current delivery before accepting another.';
}

class InvalidStatusChangeException implements Exception {
  const InvalidStatusChangeException(this.from, this.to);
  final OrderStatus from;
  final OrderStatus to;

  @override
  String toString() => 'Cannot change status from ${from.name} to ${to.name}.';
}
