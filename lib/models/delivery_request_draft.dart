import '../constants/campus_restaurants.dart';
import '../constants/campus_locations.dart';
import '../services/pricing.dart';

/// Validated customer input for review. This is not a saved server Order.
class DeliveryRequestDraft {
  const DeliveryRequestDraft({
    required this.orderName,
    required this.restaurant,
    required this.orderNumber,
    required this.pickup,
    required this.dropoff,
    required this.tipCents,
  });

  final String orderName;
  final String restaurant;
  final String orderNumber;
  final CampusLocation pickup;
  final CampusLocation dropoff;
  final int tipCents;

  bool get isMobileOrder => usesMobileOrdering(restaurant);

  double get distanceMiles => routeDistanceMiles(pickup, dropoff);
  int get feeCents => deliveryFeeCents(distanceMiles);
  int get totalCents => feeCents + tipCents;
}
