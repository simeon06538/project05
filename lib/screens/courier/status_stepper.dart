import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';

/// Accepted -> Picked up -> Delivered progress, with the current step lit.
class StatusStepper extends StatelessWidget {
  const StatusStepper({super.key, required this.status});

  final OrderStatus status;

  static const _steps = [
    (OrderStatus.accepted, 'Accepted', Icons.check),
    (OrderStatus.pickedUp, 'Picked up', Icons.shopping_bag_outlined),
    (OrderStatus.delivered, 'Delivered', Icons.home_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexWhere((s) => s.$1 == status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(top: 17),
                color: i <= current
                    ? AppColors.accentSoft
                    : const Color(0x33FFFFFF),
              ),
            ),
          _Step(
            label: _steps[i].$2,
            icon: _steps[i].$3,
            done: i <= current,
            isCurrent: i == current,
          ),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.icon,
    required this.done,
    required this.isCurrent,
  });

  final String label;
  final IconData icon;
  final bool done;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label${isCurrent ? ', current step' : ''}',
      // The visible text is already in the label, so don't read it twice.
      excludeSemantics: true,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.accent : const Color(0x1AFFFFFF),
              border: Border.all(
                color: isCurrent ? AppColors.accentSoft : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: done ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: done ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
