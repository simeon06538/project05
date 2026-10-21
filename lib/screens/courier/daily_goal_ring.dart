import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';

/// Goal choices offered in Settings, in cents.
const dailyGoalOptionsCents = [1000, 1500, 2000, 3000, 4000];

/// K-41: progress ring for today's earnings against the daily goal.
class DailyGoalRing extends StatelessWidget {
  const DailyGoalRing({
    super.key,
    required this.earnedTodayCents,
    required this.goalCents,
  });

  final int earnedTodayCents;
  final int goalCents;

  @override
  Widget build(BuildContext context) {
    final progress = (earnedTodayCents / goalCents).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final reached = earnedTodayCents >= goalCents;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label:
          "Today's goal, ${formatCents(earnedTodayCents)} of "
          '${formatCents(goalCents)}, $percent percent',
      excludeSemantics: true,
      child: GlassPanel(
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      color: AppColors.accentSoft,
                      backgroundColor: const Color(0x26FFFFFF),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's goal", style: textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    '${formatCents(earnedTodayCents)} of ${formatCents(goalCents)}',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reached
                        ? 'Goal reached - nice work!'
                        : '${formatCents(goalCents - earnedTodayCents)} to go',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
