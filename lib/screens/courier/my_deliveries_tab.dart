import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/courier_service.dart';
import '../../services/haptics.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/status_views.dart';
import '../../widgets/primary_button.dart';
import 'delivered_dialog.dart';
import 'delivery_timeline.dart';
import 'order_widgets.dart';
import 'pickup_checklist.dart';
import 'problem_report_sheet.dart';
import 'release_dialog.dart';
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
  bool _pickupReady = false;
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
      if (mounted) {
        setState(() {
          if (order?.id != _order?.id) _pickupReady = false;
          _order = order;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// K-51: report a problem; a closed restaurant cancels the delivery.
  Future<void> _reportProblem(Order order) async {
    final report = await showProblemReportSheet(context, order);
    if (report == null || !mounted) return;
    setState(() => _updating = true);
    try {
      final updated = await widget.service.reportProblem(
        order.id,
        widget.courierId,
        report.problem,
        details: report.details,
      );
      if (!mounted) return;
      final cancelled = updated.status == OrderStatus.cancelled;
      setState(() => _order = cancelled ? null : updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cancelled
                ? 'Order cancelled: ${report.problem.label.toLowerCase()}. '
                      'No penalty for you.'
                : 'Problem reported. Support has been notified.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Haptics.problem();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  /// K-28: hands an accepted delivery back before pickup.
  Future<void> _release(Order order) async {
    if (!await confirmRelease(context, order) || !mounted) return;
    setState(() => _updating = true);
    try {
      await widget.service.releaseDelivery(order.id, widget.courierId);
      if (!mounted) return;
      Haptics.step();
      setState(() => _order = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery released. It is back on the open list.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Haptics.problem();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  /// K-08: moves the delivery to its next status. Delivering asks first,
  /// since it pays out and can't be undone.
  Future<void> _advance(Order order) async {
    final next = order.status.next;
    if (next == null) return;
    String? note;
    if (next == OrderStatus.delivered) {
      note = await confirmDelivered(context, order);
      if (note == null) return;
    }
    if (!mounted) return;

    setState(() => _updating = true);
    try {
      final updated = await widget.service.updateStatus(
        order.id,
        next,
        dropoffNote: note,
      );
      if (!mounted) return;
      final delivered = updated.status == OrderStatus.delivered;
      delivered ? Haptics.delivered() : Haptics.step();
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
      Haptics.problem();
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
          const LoadingState(label: 'Loading your delivery…')
        else if (_loadFailed)
          ErrorState(title: "Couldn't load your delivery", onRetry: _load)
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
            pickupReady: _pickupReady,
            onPickupReadyChanged: (ready) =>
                setState(() => _pickupReady = ready),
            onReportProblem: () => _reportProblem(order),
            onRelease: order.status == OrderStatus.accepted
                ? () => _release(order)
                : null,
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
    required this.pickupReady,
    required this.onPickupReadyChanged,
    required this.onReportProblem,
    this.onRelease,
  });

  final Order order;
  final bool updating;
  final VoidCallback onAdvance;

  /// K-33: both pickup checks ticked.
  final bool pickupReady;
  final ValueChanged<bool> onPickupReadyChanged;

  /// Only offered before pickup.
  final VoidCallback? onRelease;

  /// K-51: opens the problem report sheet.
  final VoidCallback onReportProblem;

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
              // K-51: a reported (non-cancelling) problem stays visible.
              if (order.problem case final problem?) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.report_problem_outlined,
                      size: 18,
                      color: Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reported: ${problem.label}. Support has been '
                        'notified.',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
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
        if (!pickedUp) ...[
          const SizedBox(height: 16),
          PickupChecklist(
            // New order, fresh checklist.
            key: ValueKey(order.id),
            order: order,
            onReadyChanged: onPickupReadyChanged,
          ),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: pickedUp
              ? 'Mark as delivered · ${formatCents(order.totalPayCents)}'
              : 'Mark as picked up',
          loading: updating,
          onPressed: pickedUp || pickupReady ? onAdvance : null,
        ),
        if (onRelease != null)
          TextButton.icon(
            onPressed: updating ? null : onRelease,
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text("Can't make it? Release delivery"),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        TextButton.icon(
          onPressed: updating ? null : onReportProblem,
          icon: const Icon(Icons.report_problem_outlined, size: 18),
          label: const Text('Report a problem'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size(48, 48),
          ),
        ),
        // K-24: history below the main action, so the button stays on screen.
        const SizedBox(height: 20),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Timeline', style: textTheme.bodySmall),
              const SizedBox(height: 10),
              DeliveryTimeline(order: order),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
