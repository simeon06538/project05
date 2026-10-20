import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/api_customer_order_service.dart';
import '../../services/customer_order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_panel.dart';

/// C-14: customer status view. C-15 adds automatic refresh separately.
class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({
    super.key,
    required this.order,
    required this.customerId,
    this.orderService,
  });
  final Order order;
  final String customerId;
  final CustomerOrderService? orderService;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Order _order = widget.order;
  bool _loading = false;
  bool _missing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.orderService != null) _refresh();
  }

  Future<void> _refresh() async {
    if (_loading || widget.orderService == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // The customer service filters by the resolved server owner ID.
      final orders = await widget.orderService!.fetchOrders(widget.customerId);
      final updated = orders
          .where((order) => order.id == widget.order.id)
          .firstOrNull;
      if (!mounted) return;
      setState(() {
        _missing = updated == null;
        if (updated != null) _order = updated;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is CustomerApiException
              ? error.message
              : 'Could not refresh this delivery. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final message = switch (_order.status) {
      OrderStatus.requested => 'Waiting for a courier to accept your request.',
      OrderStatus.accepted =>
        'A courier has accepted and is heading to pickup.',
      OrderStatus.pickedUp => 'Your food has been picked up and is on the way.',
      OrderStatus.delivered =>
        'Your delivery is complete. You can find it in Past deliveries.',
      OrderStatus.cancelled => 'This delivery was cancelled.',
    };
    Widget detail(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: text.bodySmall),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
    Widget price(String label, int cents) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(formatCents(cents)),
        ],
      ),
    );
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to deliveries'),
                      ),
                    ),
                    Text('Track delivery', style: text.headlineSmall),
                    const SizedBox(height: 12),
                    if (widget.orderService != null)
                      TextButton.icon(
                        onPressed: _loading ? null : _refresh,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(
                          _loading ? 'Refreshing status…' : 'Refresh status',
                        ),
                      )
                    else
                      const Text(
                        'Sample status · Not connected to the delivery server',
                      ),
                    if (_error != null) ...[
                      GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 8),
                            const Text(
                              'Your status may be out of date. Tap Refresh status to try again.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_missing)
                      const GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Request no longer available'),
                            SizedBox(height: 8),
                            Text(
                              'It may have been deleted. Return to deliveries to refresh your list.',
                            ),
                          ],
                        ),
                      )
                    else ...[
                      GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(message, style: text.titleMedium),
                            const SizedBox(height: 16),
                            if (_order.status != OrderStatus.cancelled)
                              _CustomerProgress(status: _order.status),
                            const SizedBox(height: 12),
                            Text(
                              'Order last updated: ${_order.updatedAt.toLocal().toString().split('.').first}',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_order.orderName != null)
                              detail(
                                'Name on the food order',
                                _order.orderName!,
                              ),
                            if (_order.pickupRestaurant != null)
                              detail(
                                'Pickup restaurant',
                                _order.pickupRestaurant!,
                              ),
                            detail(
                              'Pickup location',
                              _order.pickupLocationName ??
                                  _order.pickupLocation,
                            ),
                            detail(
                              'Drop-off location',
                              _order.dropoffLocationName ??
                                  _order.dropoffLocation,
                            ),
                            detail(
                              'Paw Points order number',
                              _order.pawPointsOrderNumber,
                            ),
                            detail(
                              'Distance',
                              'Approx. ${_order.distanceMiles.toStringAsFixed(2)} miles (demo estimate)',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            price('Delivery fee', _order.deliveryFeeCents),
                            price('Tip', _order.tipCents),
                            const Divider(),
                            price('Delivery total', _order.totalPayCents),
                            const SizedBox(height: 8),
                            const Text(
                              'Food is paid separately with Paw Points.',
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Class prototype · No money is transferred',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerProgress extends StatelessWidget {
  const _CustomerProgress({required this.status});
  final OrderStatus status;
  static const steps = [
    OrderStatus.requested,
    OrderStatus.accepted,
    OrderStatus.pickedUp,
    OrderStatus.delivered,
  ];
  static const labels = ['Requested', 'Accepted', 'Picked up', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final current = steps.indexOf(status);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Semantics(
            label:
                '${labels[i]}, ${i < current
                    ? 'complete'
                    : i == current
                    ? 'current step'
                    : 'upcoming'}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    i < current
                        ? Icons.check_circle
                        : i == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: i <= current
                        ? AppColors.accentSoft
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: i <= current
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: i == current
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (i == current)
                    const Text(
                      'Current',
                      style: TextStyle(color: AppColors.accentSoft),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
