import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import 'order_widgets.dart';

/// One open request in the Available list: pickup, drop-off, distance and
/// the total the courier will be paid.
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.order, this.onTap});

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RouteStops(order: order),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0x33FFFFFF)),
            ),
            Row(
              children: [
                // Wrap so the chips drop to a second line on narrow phones.
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      InfoChip(
                        icon: Icons.straighten,
                        text: '${order.distanceMiles.toStringAsFixed(1)} mi',
                      ),
                      if (order.tipCents > 0)
                        InfoChip(
                          icon: Icons.volunteer_activism_outlined,
                          text: '${formatCents(order.tipCents)} tip',
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCents(order.totalPayCents),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'total pay',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
