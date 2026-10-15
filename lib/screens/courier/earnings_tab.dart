import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/order.dart';
import '../../services/courier_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/status_views.dart';
import 'order_widgets.dart';
import 'achievements.dart';
import 'completed_delivery_screen.dart';
import 'daily_goal_ring.dart';
import 'earnings_stats.dart';
import 'request_sort_bar.dart';
import 'tab_header.dart';
import 'weekly_earnings_chart.dart';

/// K-09: demo earnings balance plus every completed delivery and its pay.
class EarningsTab extends StatefulWidget {
  const EarningsTab({
    super.key,
    required this.service,
    required this.courierId,
    this.isVisible = true,
    this.now,
    this.dailyGoalCents,
  });

  final CourierService service;
  final String courierId;

  /// Reloads each time the tab is shown, so a just-finished delivery's
  /// pay appears straight away.
  final bool isVisible;

  /// Overridable clock so tests get stable Today / This week ranges.
  final DateTime? now;

  /// K-41: today's target in cents; no ring when null.
  final int? dailyGoalCents;

  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  late Future<CourierEarnings> _earnings;
  EarningsRange _range = EarningsRange.all;

  @override
  void initState() {
    super.initState();
    _earnings = widget.service.fetchEarnings(widget.courierId);
  }

  @override
  void didUpdateWidget(EarningsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _earnings = widget.service.fetchEarnings(widget.courierId);
    }
  }

  void _reload() {
    setState(() {
      _earnings = widget.service.fetchEarnings(widget.courierId);
    });
  }

  Future<void> _copySummary(List<Order> inRange, int balanceCents) async {
    await Clipboard.setData(
      ClipboardData(
        text: earningsSummaryText(
          range: _range,
          inRange: inRange,
          balanceCents: balanceCents,
        ),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Earnings summary copied')));
  }

  /// K-39: Today / This week / All time chips, then the stats and history
  /// for that range.
  List<Widget> _rangeSection(CourierEarnings earnings) {
    final all = earnings.completedDeliveries;
    final inRange = filterByRange(all, _range, widget.now ?? DateTime.now());
    return [
      Wrap(
        spacing: 8,
        children: [
          for (final range in EarningsRange.values)
            FilterPill(
              label: range.label,
              selected: range == _range,
              onTap: () => setState(() => _range = range),
            ),
        ],
      ),
      const SizedBox(height: 4),
      EarningsStatsRow(stats: EarningsStats.from(inRange)),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Completed deliveries · ${inRange.length}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // K-40: copy this range's summary to the clipboard.
            TextButton.icon(
              onPressed: inRange.isEmpty
                  ? null
                  : () => _copySummary(inRange, earnings.balanceCents),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy summary'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
          ],
        ),
      ),
      if (all.isEmpty)
        const GlassPanel(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          child: EmptyState(
            icon: Icons.savings_outlined,
            title: 'No completed deliveries yet',
            subtitle: 'Pay from each delivery is added here.',
          ),
        )
      else if (inRange.isEmpty)
        GlassPanel(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _range == EarningsRange.today
                      ? 'No deliveries today yet.'
                      : 'No deliveries in the last 7 days.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _range = EarningsRange.all),
                child: const Text('See all time'),
              ),
            ],
          ),
        )
      else
        for (final order in inRange) ...[
          _HistoryItem(order: order),
          const SizedBox(height: 10),
        ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CourierEarnings>(
      future: _earnings,
      builder: (context, snapshot) {
        final earnings = snapshot.data;
        return ListView(
          children: [
            const TabHeader(
              title: 'Earnings',
              pill: 'Demo balance · delivery fee + tips',
            ),
            const SizedBox(height: 20),
            if (snapshot.connectionState != ConnectionState.done)
              const LoadingState(label: 'Loading earnings…')
            else if (snapshot.hasError || earnings == null)
              ErrorState(title: "Couldn't load your earnings", onRetry: _reload)
            else ...[
              _BalancePanel(earnings: earnings),
              if (widget.dailyGoalCents case final goal?) ...[
                const SizedBox(height: 16),
                DailyGoalRing(
                  goalCents: goal,
                  earnedTodayCents: filterByRange(
                    earnings.completedDeliveries,
                    EarningsRange.today,
                    widget.now ?? DateTime.now(),
                  ).fold(0, (sum, o) => sum + o.totalPayCents),
                ),
              ],
              const SizedBox(height: 16),
              GlassPanel(
                child: WeeklyEarningsChart(
                  completed: earnings.completedDeliveries,
                ),
              ),
              const SizedBox(height: 16),
              // K-46: badges for milestones, from all-time deliveries.
              AchievementsPanel(
                achievements: achievementsFor(earnings.completedDeliveries),
              ),
              const SizedBox(height: 12),
              ..._rangeSection(earnings),
            ],
          ],
        );
      },
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({required this.earnings});

  final CourierEarnings earnings;

  @override
  Widget build(BuildContext context) {
    final completed = earnings.completedDeliveries;
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Demo balance',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            formatCents(earnings.balanceCents),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0x33FFFFFF)),
          ),
          _SummaryRow(
            label: 'Completed deliveries',
            value: '${completed.length}',
          ),
        ],
      ),
    );
  }
}

/// One finished delivery: where it went, when, and what it paid.
class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    // K-27: tap for the full breakdown.
    return Semantics(
      button: true,
      label:
          'Delivery to ${order.dropoffLocation}, '
          '${formatCents(order.totalPayCents)}, view details',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CompletedDeliveryScreen(order: order),
          ),
        ),
        child: _card(),
      ),
    );
  }

  Widget _card() {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.accentSoft,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.dropoffLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'From ${order.pickupLocation} · ${timeAgo(order.updatedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${formatCents(order.totalPayCents)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (order.tipCents > 0)
                Text(
                  'incl. ${formatCents(order.tipCents)} tip',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
