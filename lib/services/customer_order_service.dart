import '../models/delivery_request_draft.dart';
import '../models/order.dart';

abstract class CustomerOrderService {
  Future<List<Order>> fetchOrders(String customerId);
  Future<Order> createOrder(String customerId, DeliveryRequestDraft draft);
  Future<void> deleteOrder(String customerId, String orderId);
}
