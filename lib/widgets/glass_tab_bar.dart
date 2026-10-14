import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_panel.dart';

/// Segmented tab bar on a glass panel; the selected tab gets a purple pill.
/// Optional [icons] (one per label) are shown above each label.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.icons,
    this.badges,
  }) : assert(icons == null || icons.length == labels.length);

  final List<String> labels;
  final List<IconData>? icons;

  /// K-29: optional count per tab (null or 0 shows nothing).
  final List<int?>? badges;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(6),
      borderRadius: 16,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _TabButton(
                label: labels[i],
                icon: icons?[i],
                badge: badges?[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.badge,
  });

  final String label;
  final IconData? icon;
  final int? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: (badge ?? 0) > 0 ? '$label tab, $badge open' : '$label tab',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: icon == null ? 12 : 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withAlpha(200) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 20, color: color),
                    if ((badge ?? 0) > 0)
                      Positioned(
                        top: -6,
                        right: -14,
                        child: _CountBadge(count: badge!),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: icon == null ? null : 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small white pill with a count, e.g. open requests; "99+" past 99.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.backgroundTop, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.backgroundTop,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
