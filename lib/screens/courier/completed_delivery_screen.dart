import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_panel.dart';
import 'customer_rating.dart';
import 'delivery_timeline.dart';
import 'detail_widgets.dart';
import 'order_widgets.dart';

/// "Today, 3:05 PM", "Yesterday, 9:30 AM" or "Mon Oct 12, 1:15 PM".
String formatDayTime(DateTime time, {DateTime? now}) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final daysAgo = today.difference(DateUtils.dateOnly(time)).inDays;
  final day = switch (daysAgo) {
    0 => 'Today',
    1 => 'Yesterday',
    _ => '${days[time.weekday - 1]} ${months[time.month - 1]} ${time.day}',
  };
  return '$day, ${formatClock(time)}';
}

/// K-27: what a finished delivery paid and how it went, opened from the
/// Earnings history.
class CompletedDeliveryScreen extends StatelessWidget {
  const CompletedDeliveryScreen({super.key, required this.order, this.now});

  final Order order;

  /// Overridable clock so tests get stable "Today" / "Yesterday" labels.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final delivered = order.deliveredAt ?? order.updatedAt;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        GlassBackButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Delivery summary',
                            style: textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        GlassPanel(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('You earned', style: textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                '+${formatCents(order.totalPayCents)}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Delivered ${formatDayTime(delivered, now: now)}',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SectionLabel('Pay breakdown'),
                        GlassPanel(
                          child: Column(
                            children: [
                              MoneyRow(
                                label: 'Delivery fee',
                                cents: order.deliveryFeeCents,
                              ),
                              const SizedBox(height: 10),
                              MoneyRow(label: 'Tip', cents: order.tipCents),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  height: 1,
                                  color: Color(0x33FFFFFF),
                                ),
                              ),
                              MoneyRow(
                                label: 'Total pay',
                                cents: order.totalPayCents,
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (order.customerRating case final rating?) ...[
                          const SectionLabel('Customer rating'),
                          CustomerRatingPanel(
                            rating: rating,
                            note: order.customerNote,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (order.dropoffNote case final note?) ...[
                          const SectionLabel('Drop-off note'),
                          GlassPanel(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.sticky_note_2_outlined,
                                  color: AppColors.accentSoft,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SectionLabel('Route'),
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
                                    text:
                                        '${order.distanceMiles.toStringAsFixed(1)} mi',
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
                        const SectionLabel('Timeline'),
                        GlassPanel(child: DeliveryTimeline(order: order)),
                      ],
                    ),
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
