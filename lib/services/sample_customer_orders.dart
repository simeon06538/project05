import '../models/order.dart';

/// C-03 preview fixtures, not orders submitted to the server or couriers.
List<Order> sampleCustomerOrders() {
  final now = DateTime.now();
  return [
    Order(
      id: 'sample-active',
      customerId: 'customer-demo',
      pickupLocation: 'union',
      pickupLocationName: 'Student Union · Grill',
      dropoffLocation: 'middleton-library',
      dropoffLocationName: 'Library · Main entrance',
      distanceMiles: 0.2,
      deliveryFeeCents: 250,
      tipCents: 100,
      status: OrderStatus.requested,
      pawPointsOrderNumber: 'PP-4810',
      createdAt: now.subtract(const Duration(minutes: 5)),
      updatedAt: now.subtract(const Duration(minutes: 5)),
    ),
    Order(
      id: 'sample-past',
      customerId: 'customer-demo',
      courierId: 'courier-demo',
      pickupLocation: 'union',
      pickupLocationName: 'Student Union · Chick-fil-A',
      dropoffLocation: 'west-campus-apts',
      dropoffLocationName: 'West Campus Apartments',
      distanceMiles: 1,
      deliveryFeeCents: 400,
      tipCents: 200,
      status: OrderStatus.delivered,
      pawPointsOrderNumber: 'PP-4792',
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(hours: 23)),
    ),
  ];
}
