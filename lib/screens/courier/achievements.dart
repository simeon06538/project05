import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';

/// K-46: one badge and whether the courier has earned it.
class Achievement {
  const Achievement({
    required this.title,
    required this.hint,
    required this.icon,
    required this.unlocked,
  });

  final String title;

  /// How to earn it, shown while it's locked.
  final String hint;
  final IconData icon;
  final bool unlocked;
}

/// Works out every badge from the courier's completed deliveries.
List<Achievement> achievementsFor(List<Order> completed) {
  final count = completed.length;
  final totalCents = completed.fold(0, (sum, o) => sum + o.totalPayCents);
  return [
    Achievement(
      title: 'First delivery',
      hint: 'Complete a delivery',
      icon: Icons.flag_rounded,
      unlocked: count >= 1,
    ),
    Achievement(
      title: '5 deliveries',
      hint: '${count.clamp(0, 5)} of 5 done',
      icon: Icons.looks_5_rounded,
      unlocked: count >= 5,
    ),
    Achievement(
      title: '10 deliveries',
      hint: '${count.clamp(0, 10)} of 10 done',
      icon: Icons.military_tech_rounded,
      unlocked: count >= 10,
    ),
    Achievement(
      title: r'$50 earned',
      hint: '${formatCents(totalCents.clamp(0, 5000))} of \$50.00',
      icon: Icons.savings_rounded,
      unlocked: totalCents >= 5000,
    ),
    Achievement(
      title: 'Big tip',
      hint: r'Get a $3+ tip',
      icon: Icons.volunteer_activism_rounded,
      unlocked: completed.any((o) => o.tipCents >= 300),
    ),
    Achievement(
      title: 'Long haul',
      hint: 'Deliver over 1 mile',
      icon: Icons.route_rounded,
      unlocked: completed.any((o) => o.distanceMiles > 1),
    ),
  ];
}

/// Glass panel with a grid of badges and how many are unlocked.
class AchievementsPanel extends StatelessWidget {
  const AchievementsPanel({super.key, required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.unlocked).length;
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements · $unlocked of ${achievements.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Three per row on a phone.
              final width = (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  for (final a in achievements)
                    SizedBox(
                      width: width,
                      child: _Badge(achievement: a),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Semantics(
      label: a.unlocked
          ? '${a.title}, unlocked'
          : '${a.title}, locked. ${a.hint}',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: a.unlocked
                  ? AppColors.accentStrong
                  : const Color(0x14FFFFFF),
              border: Border.all(
                color: a.unlocked
                    ? AppColors.accentSoft
                    : const Color(0x33FFFFFF),
              ),
            ),
            child: Icon(
              a.unlocked ? a.icon : Icons.lock_outline_rounded,
              size: 22,
              color: a.unlocked ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            a.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: a.unlocked
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          if (!a.unlocked)
            Text(
              a.hint,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
