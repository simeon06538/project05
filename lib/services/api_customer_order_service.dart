import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/delivery_request_draft.dart';
import '../models/order.dart';
import 'api_config.dart';
import 'customer_order_service.dart';

class CustomerApiException implements Exception {
  const CustomerApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;
  @override
  String toString() => message;
}

/// C-13: real customer endpoints. Demo names map to unique server user IDs
/// on this device. This is a class-demo identity, not password authentication.
class ApiCustomerOrderService implements CustomerOrderService {
  ApiCustomerOrderService({
    required this.preferences,
    http.Client? client,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? ApiConfig.baseUrl;
  final SharedPreferences preferences;
  final http.Client _client;
  final String _baseUrl;
  final Map<String, Future<int>> _users = {};

  @override
  bool get isServerBacked => true;

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = http.Request(method, Uri.parse('$_baseUrl$path'));
      request.headers['Content-Type'] = 'application/json';
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 12)),
      ).timeout(const Duration(seconds: 12));
      final dynamic data = response.body.isEmpty
          ? null
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = data is Map ? data['error'] : null;
        throw CustomerApiException(
          error is Map ? error['message'] as String : 'Server request failed.',
          statusCode: response.statusCode,
          code: error is Map ? error['code'] as String? : null,
        );
      }
      return data;
    } on CustomerApiException {
      rethrow;
    } on FormatException {
      throw const CustomerApiException(
        'The server returned an unreadable response.',
      );
    } catch (_) {
      throw const CustomerApiException(
        'Could not reach the delivery server. Check that it is running and refresh deliveries before retrying.',
      );
    }
  }

  Future<int> _customerId(String identity) async {
    final existing = _users[identity];
    if (existing != null) return existing;
    final pending = _resolveCustomer(identity);
    _users[identity] = pending;
    try {
      return await pending;
    } catch (_) {
      _users.remove(identity);
      rethrow;
    }
  }

  Future<int> _resolveCustomer(String identity) async {
    final name = identity.startsWith('demo-customer:')
        ? identity.substring('demo-customer:'.length)
        : identity;
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw const CustomerApiException('Enter your name first.');
    }
    final key = 'customer.apiUser.v1:$_baseUrl:$normalized';
    final savedId = preferences.getInt(key);
    if (savedId != null) {
      try {
        final user =
            await _request('GET', '/users/$savedId') as Map<String, dynamic>;
        if (user['role'] == 'customer' &&
            (user['name'] as String).trim().toLowerCase() == normalized) {
          return savedId;
        }
      } on CustomerApiException catch (error) {
        if (error.statusCode != 404) rethrow;
      }
    }
    final user = await _request(
      'POST',
      '/users',
      body: {'name': name.trim(), 'role': 'customer'},
    ) as Map<String, dynamic>;
    final id = user['id'] as int;
    if (!await preferences.setInt(key, id)) {
      throw const CustomerApiException('Could not remember your demo user ID.');
    }
    return id;
  }

  @override
  Future<List<Order>> fetchOrders(String customerId) async {
    final id = await _customerId(customerId);
    final data = await _request('GET', '/orders?customerId=$id') as List;
    return data
        .map((json) => Order.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  @override
  Future<Order> createOrder(
    String customerId,
    DeliveryRequestDraft draft,
  ) async {
    final id = await _customerId(customerId);
    final data = await _request(
      'POST',
      '/orders',
      body: {
        'customerId': id,
        'pickupLocation': draft.pickup.id,
        'dropoffLocation': draft.dropoff.id,
        'tip': draft.tipCents / 100,
        'pawPointsOrderNumber': draft.orderNumber.trim(),
        'isMobileOrder': draft.isMobileOrder,
        'orderName': draft.orderName.trim(),
        'pickupRestaurant': draft.restaurant.trim(),
      },
    );
    return Order.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteOrder(String customerId, String orderId) async {
    final id = await _customerId(customerId);
    await _request(
      'DELETE',
      '/orders/${int.parse(orderId)}',
      body: {'customerId': id},
    );
  }
}
