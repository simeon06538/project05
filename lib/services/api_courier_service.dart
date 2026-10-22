import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';
import 'api_config.dart';
import 'courier_service.dart';

/// K-12: the courier screens on Person 3's server (docs/api.md).
///
/// Each demo name is its own server courier, like customers (C-13): the
/// first time a name is used a courier user is created, and its ID is
/// remembered on this device. This is a class-demo identity, not a login.
class ApiCourierService implements CourierService {
  ApiCourierService({
    required this.preferences,
    http.Client? client,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Courier IDs the app passes in look like "demo-courier:alex".
  static const idPrefix = 'demo-courier:';

  static const _timeout = Duration(seconds: 12);

  final SharedPreferences preferences;
  final http.Client _client;
  final String _baseUrl;
  final Map<String, Future<int>> _couriers = {};

  /// Which server courier is on each order this device has accepted or
  /// loaded, since PATCH /orders/:id/status needs it.
  final Map<String, int> _courierOf = {};

  // The server only stores when an order was created, last updated and
  // delivered, so step times and drop-off notes from this device are kept
  // here for the timeline (K-24) and summary (K-34).
  final Map<String, DateTime> _acceptedAt = {};
  final Map<String, DateTime> _pickedUpAt = {};
  final Map<String, String> _dropoffNotes = {};

  @override
  bool get isServerBacked => true;

  @override
  Future<List<Order>> fetchAvailableRequests() async {
    final data = await _request('GET', '/orders?status=requested') as List;
    return [for (final json in data) _toOrder(json)]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<Order?> fetchActiveDelivery(String courierId) async {
    final id = await _serverId(courierId);
    final data = await _request(
      'GET',
      '/orders?courierId=$id&status=accepted,picked_up',
    ) as List;
    if (data.isEmpty) return null;
    final order = _toOrder(data.first);
    _courierOf[order.id] = id;
    return order;
  }

  @override
  Future<Order> acceptRequest(String orderId, String courierId) async {
    final number = _orderNumber(orderId);
    try {
      return await _asCourier(courierId, (id) async {
        final order = _toOrder(
          await _request(
            'PATCH',
            '/orders/$number/accept',
            body: {'courierId': id},
          ),
        );
        _courierOf[order.id] = id;
        return order;
      });
    } on _ApiError catch (e) {
      throw switch (e.code) {
        'already_accepted' => OrderAlreadyTakenException(orderId),
        'courier_busy' => const ActiveDeliveryException(),
        'not_found' => OrderNotFoundException(orderId),
        _ => e,
      };
    }
  }

  @override
  Future<Order> updateStatus(
    String orderId,
    OrderStatus newStatus, {
    String? dropoffNote,
  }) async {
    final number = _orderNumber(orderId);
    // Accepting has its own endpoint, and couriers can't cancel.
    if (newStatus != OrderStatus.pickedUp &&
        newStatus != OrderStatus.delivered) {
      throw InvalidStatusChangeException(
        (await _fetchOrder(number)).status,
        newStatus,
      );
    }
    final courier = _courierOf[orderId];
    if (courier == null) throw NotYourDeliveryException(orderId);
    try {
      final data = await _request(
        'PATCH',
        '/orders/$number/status',
        body: {'status': newStatus.toJson(), 'courierId': courier},
      );
      final note = dropoffNote?.trim() ?? '';
      if (newStatus == OrderStatus.delivered && note.isNotEmpty) {
        _dropoffNotes[orderId] = note;
      }
      return _toOrder(data);
    } on _ApiError catch (e) {
      throw switch (e.code) {
        'invalid_transition' => InvalidStatusChangeException(
          (await _fetchOrder(number)).status,
          newStatus,
        ),
        'forbidden' => NotYourDeliveryException(orderId),
        'not_found' => OrderNotFoundException(orderId),
        _ => e,
      };
    }
  }

  @override
  Future<CourierEarnings> fetchEarnings(String courierId) {
    return _asCourier(courierId, (id) async {
      final earnings = await _request(
        'GET',
        '/couriers/$id/earnings',
      ) as Map<String, dynamic>;
      // The full orders, for distance and order numbers on the history.
      final delivered = await _request(
        'GET',
        '/orders?courierId=$id&status=delivered',
      ) as List;
      return CourierEarnings(
        balanceCents: ((earnings['earnings'] as num) * 100).round(),
        completedDeliveries: [for (final json in delivered) _toOrder(json)]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      );
    });
  }

  @override
  Future<Order> releaseDelivery(String orderId, String courierId) async =>
      throw UnsupportedError(
        "The server can't take a delivery back yet. Finish it instead.",
      );

  @override
  Future<Order> reportProblem(
    String orderId,
    String courierId,
    DeliveryProblem problem, {
    String? details,
  }) async =>
      throw UnsupportedError("The server can't take problem reports yet.");

  Future<Order> _fetchOrder(int number) async =>
      _toOrder(await _request('GET', '/orders/$number'));

  /// Server order IDs are numbers; anything else can't be on the server.
  int _orderNumber(String orderId) =>
      int.tryParse(orderId) ?? (throw OrderNotFoundException(orderId));

  /// A server order as the courier screens show it: "Building · Restaurant"
  /// names, local times, and the step times this device saw.
  Order _toOrder(Object? json) {
    final o = Order.fromJson(Map<String, dynamic>.from(json as Map));
    final updatedAt = o.updatedAt.toLocal();
    if (o.status == OrderStatus.accepted) {
      _acceptedAt.putIfAbsent(o.id, () => updatedAt);
    } else if (o.status == OrderStatus.pickedUp) {
      _pickedUpAt.putIfAbsent(o.id, () => updatedAt);
    }
    final restaurant = o.pickupRestaurant?.trim() ?? '';
    return Order(
      id: o.id,
      customerId: o.customerId,
      courierId: o.courierId,
      pickupLocation: [
        o.pickupLocationName ?? o.pickupLocation,
        if (restaurant.isNotEmpty) restaurant,
      ].join(' · '),
      dropoffLocation: o.dropoffLocationName ?? o.dropoffLocation,
      orderName: o.orderName,
      pickupRestaurant: o.pickupRestaurant,
      pickupLocationName: o.pickupLocationName,
      dropoffLocationName: o.dropoffLocationName,
      distanceMiles: o.distanceMiles,
      deliveryFeeCents: o.deliveryFeeCents,
      tipCents: o.tipCents,
      status: o.status,
      pawPointsOrderNumber: o.pawPointsOrderNumber,
      createdAt: o.createdAt.toLocal(),
      updatedAt: updatedAt,
      acceptedAt: _acceptedAt[o.id],
      pickedUpAt: _pickedUpAt[o.id],
      deliveredAt: o.status == OrderStatus.delivered ? updatedAt : null,
      dropoffNote: _dropoffNotes[o.id],
    );
  }

  /// Runs [action] as the server courier for [courierId]. A demo reset
  /// can delete that courier mid-session, so on "Courier ... not found"
  /// it looks the courier up again and retries once.
  Future<T> _asCourier<T>(
    String courierId,
    Future<T> Function(int id) action,
  ) async {
    try {
      return await action(await _serverId(courierId));
    } on _ApiError catch (e) {
      if (e.code != 'not_found' || !e.message.startsWith('Courier')) rethrow;
      _couriers.remove(courierId);
      return action(await _serverId(courierId));
    }
  }

  Future<int> _serverId(String courierId) async {
    final pending = _couriers[courierId] ??= _resolveCourier(courierId);
    try {
      return await pending;
    } catch (_) {
      _couriers.remove(courierId);
      rethrow;
    }
  }

  Future<int> _resolveCourier(String courierId) async {
    final name = courierId.startsWith(idPrefix)
        ? courierId.substring(idPrefix.length).trim()
        : courierId.trim();
    final normalized = name.toLowerCase();
    final key = 'courier.apiUser.v1:$_baseUrl:$normalized';
    final savedId = preferences.getInt(key);
    if (savedId != null) {
      try {
        final user =
            await _request('GET', '/users/$savedId') as Map<String, dynamic>;
        // A demo reset restarts IDs, so make sure it's still this courier.
        if (user['role'] == 'courier' &&
            (user['name'] as String).trim().toLowerCase() == normalized) {
          return savedId;
        }
      } on _ApiError catch (e) {
        if (e.code != 'not_found') rethrow;
      }
    }
    final user = await _request(
      'POST',
      '/users',
      body: {'name': name, 'role': 'courier'},
    ) as Map<String, dynamic>;
    final id = user['id'] as int;
    await preferences.setInt(key, id);
    return id;
  }

  /// Sends one request. Network failures, timeouts, unreadable replies and
  /// 5xx errors become [ServiceUnavailableException] so screens can offer
  /// "Try again"; other errors become an [_ApiError] for the caller to map.
  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final http.Response response;
    try {
      final request = http.Request(method, Uri.parse('$_baseUrl$path'));
      request.headers['Content-Type'] = 'application/json';
      if (body != null) request.body = jsonEncode(body);
      response = await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      ).timeout(_timeout);
    } catch (_) {
      throw const ServiceUnavailableException();
    }
    if (response.statusCode >= 500) throw const ServiceUnavailableException();
    final data = _decode(response.body);
    if (response.statusCode >= 400) {
      final error = data is Map ? data['error'] : null;
      throw _ApiError(
        error is Map ? error['code'] as String? ?? '' : '',
        error is Map ? error['message'] as String? ?? '' : '',
      );
    }
    return data;
  }

  static dynamic _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const ServiceUnavailableException();
    }
  }
}

/// An error reply from the server: `{ "error": { "code", "message" } }`.
class _ApiError implements Exception {
  const _ApiError(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      message.isEmpty ? 'The server rejected the request.' : message;
}
