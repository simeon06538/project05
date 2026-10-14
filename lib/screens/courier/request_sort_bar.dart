import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'request_filters.dart';

/// K-10: sort chips (Oldest / Highest pay / Closest) plus a "With tip"
/// filter for the Available list.
class RequestSortBar extends StatelessWidget {
  const RequestSortBar({
    super.key,
    required this.sort,
    required this.tipsOnly,
    required this.onSortChanged,
    required this.onTipsOnlyChanged,
  });

  final RequestSort sort;
  final bool tipsOnly;
  final ValueChanged<RequestSort> onSortChanged;
  final ValueChanged<bool> onTipsOnlyChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      // Each chip carries its own 48px-tall hit area (K-30), which also
      // spaces the rows.
      runSpacing: 0,
      children: [
        for (final option in RequestSort.values)
          _Pill(
            label: option.label,
            selected: option == sort,
            onTap: () => onSortChanged(option),
          ),
        _Pill(
          label: 'With tip',
          icon: Icons.volunteer_activism_outlined,
          selected: tipsOnly,
          onTap: () => onTipsOnlyChanged(!tipsOnly),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // 48px-tall hit area around a chip that keeps its own width.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withAlpha(200)
                    : const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.accentSoft
                      : const Color(0x33FFFFFF),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
