import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';

/// K-32: shown when a refresh brings in requests that weren't there
/// before. "View" opens the newest one; the X dismisses the banner.
class NewRequestsBanner extends StatelessWidget {
  const NewRequestsBanner({
    super.key,
    required this.newRequests,
    required this.onView,
    required this.onDismiss,
  });

  final List<Order> newRequests;
  final ValueChanged<Order> onView;
  final VoidCallback onDismiss;

  static const _freshGreen = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    final newest = newRequests.last;
    final count = newRequests.length;
    return Semantics(
      liveRegion: true,
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _freshGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1 ? '1 new request' : '$count new requests',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${newest.pickupLocation} · ${formatCents(newest.totalPayCents)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => onView(newest),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text(
                'View',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss',
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
