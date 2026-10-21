import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// K-25: pay per day for the last 7 days, oldest first and today last.
/// A delivery counts on the day it was delivered.
List<int> dailyTotalsCents(List<Order> completed, DateTime now) {
  final today = DateUtils.dateOnly(now);
  final totals = List.filled(7, 0);
  for (final order in completed) {
    final day = DateUtils.dateOnly(order.deliveredAt ?? order.updatedAt);
    final daysAgo = today.difference(day).inDays;
    if (daysAgo >= 0 && daysAgo < 7) {
      totals[6 - daysAgo] += order.totalPayCents;
    }
  }
  return totals;
}

/// K-25: bar chart of the last 7 days' earnings. One series, so one hue;
/// the selected day (today by default) is drawn solid and labelled above
/// the bars. Tap a bar to see that day.
class WeeklyEarningsChart extends StatefulWidget {
  const WeeklyEarningsChart({super.key, required this.completed, this.now});

  final List<Order> completed;

  /// Overridable clock so tests get stable days.
  final DateTime? now;

  @override
  State<WeeklyEarningsChart> createState() => _WeeklyEarningsChartState();
}

class _WeeklyEarningsChartState extends State<WeeklyEarningsChart> {
  static const _barAreaHeight = 96.0;

  int _selected = 6; // today

  @override
  Widget build(BuildContext context) {
    final now = widget.now ?? DateTime.now();
    final totals = dailyTotalsCents(widget.completed, now);
    final weekTotal = totals.fold(0, (a, b) => a + b);
    final maxCents = totals.fold(0, (a, b) => a > b ? a : b);
    final days = [
      for (var i = 0; i < 7; i++) now.subtract(Duration(days: 6 - i)),
    ];
    String dayName(int i) => i == 6 ? 'Today' : _dayNames[days[i].weekday - 1];
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Last 7 days', style: textTheme.bodySmall)),
            Text(formatCents(weekTotal), style: textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 2),
        // Direct label for the selected bar only, never one per bar.
        Text(
          '${dayName(_selected)} · ${formatCents(totals[_selected])}',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _barAreaHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == _selected,
                    label: '${dayName(i)}, ${formatCents(totals[i])}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      // The whole column is the hit target, not just the bar.
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selected = i),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          // 2px gap between neighbouring bars.
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: maxCents == 0 || totals[i] == 0
                              ? 0
                              : (_barAreaHeight * totals[i] / maxCents).clamp(
                                  4,
                                  _barAreaHeight,
                                ),
                          decoration: BoxDecoration(
                            color: i == _selected
                                ? AppColors.accent
                                : AppColors.accentSoft.withAlpha(90),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Recessive baseline.
        Container(height: 1, color: const Color(0x33FFFFFF)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  i == 6 ? 'Today' : _dayNames[days[i].weekday - 1],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 11,
                    color: i == _selected
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight: i == _selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
