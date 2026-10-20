import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';

/// "3:05 PM" style clock time, without pulling in a date package.
String formatClock(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
}

/// K-24: when the order was requested, accepted, picked up and delivered.
/// Steps that haven't happened yet show as "Next" / "Pending".
class DeliveryTimeline extends StatelessWidget {
  const DeliveryTimeline({super.key, required this.order});

  final Order order;

  static const _steps = [
    (OrderStatus.requested, 'Requested', Icons.receipt_long_outlined),
    (OrderStatus.accepted, 'Accepted', Icons.check),
    (OrderStatus.pickedUp, 'Picked up', Icons.shopping_bag_outlined),
    (OrderStatus.delivered, 'Delivered', Icons.home_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final firstPending = _steps.indexWhere((s) => order.timeOf(s.$1) == null);
    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          _TimelineRow(
            label: _steps[i].$2,
            icon: _steps[i].$3,
            time: order.timeOf(_steps[i].$1),
            isNext: i == firstPending,
            isLast: i == _steps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.icon,
    required this.time,
    required this.isNext,
    required this.isLast,
  });

  final String label;
  final IconData icon;
  final DateTime? time;
  final bool isNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final done = time != null;
    final status = done ? formatClock(time!) : (isNext ? 'Next' : 'Pending');
    return Semantics(
      label: '$label, $status',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.accent : const Color(0x1AFFFFFF),
                    border: Border.all(
                      color: isNext ? AppColors.accentSoft : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 15,
                    color: done ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: done
                          ? AppColors.accentSoft
                          : const Color(0x33FFFFFF),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: done
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: done ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: done
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
