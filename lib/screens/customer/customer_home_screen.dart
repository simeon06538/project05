import 'package:flutter/material.dart';

import '../../models/order.dart';
import 'request_delivery_screen.dart';
import 'order_tracking_screen.dart';
import '../../services/customer_order_service.dart';
import '../../services/api_customer_order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_tab_bar.dart';
import '../../widgets/primary_button.dart';

/// C-03: customer landing screen. Data is injected for mock/API integration.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    required this.name,
    required this.onSwitchRole,
    required this.orders,
    this.isSampleData = false,
    this.onRequestDelivery,
    this.orderService,
    this.customerId = 'customer-demo',
  });
  final String name;
  final VoidCallback onSwitchRole;
  final List<Order> orders;
  final bool isSampleData;
  final VoidCallback? onRequestDelivery;
  final CustomerOrderService? orderService;
  final String customerId;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _tab = 0;

  List<Order> _savedOrders = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.orderService != null) _reload();
  }

  Future<void> _reload() async {
    if (_loading || widget.orderService == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await widget.orderService!.fetchOrders(widget.customerId);
      if (mounted) setState(() => _savedOrders = orders);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is CustomerApiException
              ? error.message
              : 'Could not load saved demo orders.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRequest() async {
    final order = await Navigator.of(context).push<Order>(
      MaterialPageRoute(
        builder: (_) => RequestDeliveryScreen(
          orderName: widget.name,
          orderService: widget.orderService,
          customerId: widget.customerId,
        ),
      ),
    );
    if (mounted && order != null && widget.orderService != null) {
      setState(() => _tab = 0);
      await _reload();
    }
  }

  Future<void> _track(Order order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(
          order: order,
          customerId: widget.customerId,
          orderService: widget.orderService,
        ),
      ),
    );
    if (!mounted || widget.orderService == null) return;
    await _reload();
    if (!mounted) return;
    final updated = _savedOrders
        .where((entry) => entry.id == order.id)
        .firstOrNull;
    if (updated?.status == OrderStatus.delivered ||
        updated?.status == OrderStatus.cancelled) {
      setState(() => _tab = 1);
    }
  }

  Future<void> _delete(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this request?'),
        content: const Text(
          'It will be removed entirely and will not appear in Past deliveries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep request'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.orderService!.deleteOrder(widget.customerId, order.id);
      if (mounted) await _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not delete this request. It may no longer be waiting for a courier.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders =
        (widget.orderService == null ? widget.orders : _savedOrders).where((
          order,
        ) {
          final past =
              order.status == OrderStatus.delivered ||
              order.status == OrderStatus.cancelled;
          return _tab == 1 ? past : !past;
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: widget.onSwitchRole,
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Switch role'),
                    ),
                  ),
                  Text('Customer mode', style: text.bodySmall),
                  const SizedBox(height: 4),
                  Text('Welcome, ${widget.name}', style: text.headlineSmall),
                  const SizedBox(height: 20),
                  GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 36,
                          color: AppColors.accentSoft,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your food. Delivered across campus.',
                          style: text.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Order and pay in LSU Dining with Paw Points.\n2. Request delivery here with your order details.\n3. A courier picks it up and brings it to you.',
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Request a Delivery',
                          onPressed: widget.onRequestDelivery ?? _openRequest,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Delivery fee + optional tip only. Food is paid separately.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Your deliveries', style: text.titleLarge),
                  if (widget.isSampleData) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Sample orders · Preview only, not sent to couriers',
                      style: TextStyle(color: AppColors.accentSoft),
                    ),
                  ],
                  if (widget.orderService != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.orderService!.isServerBacked
                          ? 'Server mode · Demo payments only'
                          : 'Demo orders · Saved on this device, not sent to couriers',
                    ),
                    TextButton.icon(
                      onPressed: _loading ? null : _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh deliveries'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  GlassTabBar(
                    labels: const ['Active', 'Past'],
                    selectedIndex: _tab,
                    onSelected: (index) => setState(() => _tab = index),
                  ),
                  const SizedBox(height: 16),
                  if (_loading) ...[
                    const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading deliveries',
                      ),
                    ),
                    const Center(child: Text('Loading deliveries…')),
                    const SizedBox(height: 12),
                  ],
                  if (_error != null)
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 28),
                          const SizedBox(height: 8),
                          Semantics(
                            liveRegion: true,
                            child: Text(_error!, textAlign: TextAlign.center),
                          ),
                          if (_savedOrders.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Showing your last loaded deliveries. Status may be out of date.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                          TextButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  if (_error != null) const SizedBox(height: 16),
                  if (!_loading && _error == null && orders.isEmpty)
                    EmptyState(
                      icon: _tab == 0
                          ? Icons.delivery_dining_outlined
                          : Icons.history,
                      title: _tab == 0
                          ? 'No active deliveries'
                          : 'No past deliveries',
                      subtitle: _tab == 0
                          ? 'Tap Request a Delivery to arrange pickup of food you have already ordered.'
                          : 'Your delivery history will appear here. Deleted requests are not saved to history.',
                    ),
                  if (orders.isNotEmpty)
                    for (final order in orders) ...[
                      _CustomerOrderCard(
                        order: order,
                        onTrack: () => _track(order),
                        onDelete:
                            widget.orderService != null &&
                                order.status == OrderStatus.requested
                            ? () => _delete(order)
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 12),
                  Text(
                    'Class prototype · No money is transferred',
                    style: text.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  const _CustomerOrderCard({
    required this.order,
    required this.onTrack,
    this.onDelete,
  });
  final Order order;
  final VoidCallback onTrack;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final status = switch (order.status) {
      OrderStatus.requested => 'Waiting for a courier',
      OrderStatus.accepted => 'Courier accepted',
      OrderStatus.pickedUp => 'On the way',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
    };
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTrack,
        borderRadius: BorderRadius.circular(18),
        child: GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (order.id.contains(':sample-')) const Text('Sample order'),
              Text(
                status,
                style: const TextStyle(
                  color: AppColors.accentSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Tap to track delivery'),
              const SizedBox(height: 12),
              if (order.orderName != null)
                Text('Order name: ${order.orderName}'),
              if (order.pickupRestaurant != null)
                Text('Restaurant: ${order.pickupRestaurant}'),
              Text(
                'Pickup: ${order.pickupLocationName ?? order.pickupLocation}',
              ),
              const SizedBox(height: 6),
              Text(
                'Deliver to: ${order.dropoffLocationName ?? order.dropoffLocation}',
              ),
              const SizedBox(height: 8),
              Text(
                order.pawPointsOrderNumber.isEmpty
                    ? 'No order number provided'
                    : 'Paw Points order: ${order.pawPointsOrderNumber}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 24),
              Text(
                'Delivery fee ${formatCents(order.deliveryFeeCents)}  +  Tip ${formatCents(order.tipCents)}',
              ),
              const SizedBox(height: 6),
              Text(
                'Delivery total ${formatCents(order.totalPayCents)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (onDelete != null)
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete request'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
