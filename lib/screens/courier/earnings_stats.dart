import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';

/// K-26: summary numbers for a courier's completed deliveries.
class EarningsStats {
  const EarningsStats({
    required this.count,
    required this.totalCents,
    required this.tipsCents,
    required this.best,
  });

  factory EarningsStats.from(List<Order> completed) {
    Order? best;
    var total = 0;
    var tips = 0;
    for (final order in completed) {
      total += order.totalPayCents;
      tips += order.tipCents;
      if (best == null || order.totalPayCents > best.totalPayCents) {
        best = order;
      }
    }
    return EarningsStats(
      count: completed.length,
      totalCents: total,
      tipsCents: tips,
      best: best,
    );
  }

  final int count;
  final int totalCents;
  final int tipsCents;

  /// The highest-paying delivery (first one wins a tie), or null if none.
  final Order? best;

  /// Average pay per delivery, rounded to the nearest cent; null if none.
  int? get averageCents => count == 0 ? null : (totalCents / count).round();
}

/// Three glass stat tiles: average pay, total tips and the best delivery.
class EarningsStatsRow extends StatelessWidget {
  const EarningsStatsRow({super.key, required this.stats});

  final EarningsStats stats;

  @override
  Widget build(BuildContext context) {
    final average = stats.averageCents;
    final best = stats.best;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StatTile(
            label: 'Avg per delivery',
            value: average == null ? '—' : formatCents(average),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Total tips',
            value: formatCents(stats.tipsCents),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Best delivery',
            value: best == null ? '—' : formatCents(best.totalPayCents),
            detail: best?.dropoffLocation,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, $value${detail == null ? '' : ', $detail'}',
      excludeSemantics: true,
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// K-39: which deliveries the Earnings stats and history cover.
enum EarningsRange {
  today('Today'),
  week('This week'),
  all('All time');

  const EarningsRange(this.label);

  final String label;
}

/// Deliveries finished in [range]: today, the last 7 days (same window as
/// the weekly chart) or everything.
List<Order> filterByRange(
  List<Order> completed,
  EarningsRange range,
  DateTime now,
) {
  if (range == EarningsRange.all) return completed;
  final today = DateUtils.dateOnly(now);
  return [
    for (final o in completed)
      if (today
              .difference(DateUtils.dateOnly(o.deliveredAt ?? o.updatedAt))
              .inDays
          case final daysAgo
          when daysAgo >= 0 && daysAgo < (range == EarningsRange.today ? 1 : 7))
        o,
  ];
}
