import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/courier_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';
import 'delivered_dialog.dart';
import 'order_widgets.dart';
import 'status_stepper.dart';
import 'tab_header.dart';

/// K-07: the courier's current delivery - progress, where to go next,
/// route, pay and the Paw Points order number.
/// K-08: one button for the next valid status (Picked up, then Delivered).
class MyDeliveriesTab extends StatefulWidget {
  const MyDeliveriesTab({
    super.key,
    required this.service,
    required this.courierId,
    this.isVisible = true,
  });

  final CourierService service;
  final String courierId;

  /// Reloads each time the tab is shown, so a just-accepted delivery
  /// appears without a manual refresh.
  final bool isVisible;

  @override
  State<MyDeliveriesTab> createState() => _MyDeliveriesTabState();
}

class _MyDeliveriesTabState extends State<MyDeliveriesTab> {
  Order? _order;
  bool _loading = true;
  bool _loadFailed = false;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MyDeliveriesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final order = await widget.service.fetchActiveDelivery(widget.courierId);
      if (mounted) setState(() => _order = order);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// K-08: moves the delivery to its next status. Delivering asks first,
  /// since it pays out and can't be undone.
  Future<void> _advance(Order order) async {
    final next = order.status.next;
    if (next == null) return;
    if (next == OrderStatus.delivered &&
        !await confirmDelivered(context, order)) {
      return;
    }
    if (!mounted) return;

    setState(() => _updating = true);
    try {
      final updated = await widget.service.updateStatus(order.id, next);
      if (!mounted) return;
      final delivered = updated.status == OrderStatus.delivered;
      setState(() => _order = delivered ? null : updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            delivered
                ? 'Delivered! ${formatCents(updated.totalPayCents)} added to '
                      'your earnings'
                : 'Picked up · now head to ${updated.dropoffLocation}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return ListView(
      children: [
        const TabHeader(
          title: 'My deliveries',
          pill: 'One active delivery at a time',
        ),
        const SizedBox(height: 20),
        if (_loading && order == null)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else if (_loadFailed)
          Text(
            "Couldn't load your delivery.",
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else if (order == null)
          const GlassPanel(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            child: EmptyState(
              icon: Icons.route,
              title: 'No active delivery',
              subtitle: 'Accept a request to start delivering.',
            ),
          )
        else
          _ActiveDelivery(
            order: order,
            updating: _updating,
            onAdvance: () => _advance(order),
          ),
      ],
    );
  }
}

class _ActiveDelivery extends StatelessWidget {
  const _ActiveDelivery({
    required this.order,
    required this.updating,
    required this.onAdvance,
  });

  final Order order;
  final bool updating;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pickedUp = order.status == OrderStatus.pickedUp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusStepper(status: order.status),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0x33FFFFFF)),
              ),
              Text('Next step', style: textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                pickedUp
                    ? 'Drop off at ${order.dropoffLocation}'
                    : 'Pick up at ${order.pickupLocation}',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                pickedUp
                    ? 'Hand the food to the customer.'
                    : 'Show order ${order.pawPointsOrderNumber} at the counter.',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RouteStops(order: order),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  InfoChip(
                    icon: Icons.straighten,
                    text: '${order.distanceMiles.toStringAsFixed(1)} mi',
                  ),
                  InfoChip(
                    icon: Icons.receipt_long_outlined,
                    text: order.pawPointsOrderNumber,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassPanel(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("You'll earn", style: textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${formatCents(order.deliveryFeeCents)} fee + '
                      '${formatCents(order.tipCents)} tip',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                formatCents(order.totalPayCents),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: pickedUp
              ? 'Mark as delivered · ${formatCents(order.totalPayCents)}'
              : 'Mark as picked up',
          loading: updating,
          onPressed: onAdvance,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
