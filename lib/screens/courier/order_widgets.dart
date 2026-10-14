import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';

/// Short relative time, e.g. "Just now", "12 min ago", "3 h ago", "2 d ago".
String timeAgo(DateTime time, {DateTime? now}) {
  final minutes = (now ?? DateTime.now()).difference(time).inMinutes;
  if (minutes < 1) return 'Just now';
  if (minutes < 60) return '$minutes min ago';
  if (minutes < 60 * 24) return '${minutes ~/ 60} h ago';
  return '${minutes ~/ (60 * 24)} d ago';
}

/// Pickup -> drop-off with a connecting line. Shared by the request card
/// and the request detail screen.
class RouteStops extends StatelessWidget {
  const RouteStops({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Stop(
          icon: Icons.storefront_outlined,
          label: 'Pickup',
          place: order.pickupLocation,
        ),
        const Padding(
          padding: EdgeInsets.only(left: 11),
          child: SizedBox(
            height: 14,
            child: VerticalDivider(width: 2, color: Color(0x55FFFFFF)),
          ),
        ),
        _Stop(
          icon: Icons.place_outlined,
          label: 'Drop-off',
          place: order.dropoffLocation,
        ),
      ],
    );
  }
}

/// Small purple pill with an icon, e.g. "0.4 mi" or "$1.00 tip".
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(70),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          // Flexible + ellipsis so a chip never overflows a narrow card
          // when the phone uses large text.
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.icon, required this.label, required this.place});

  final IconData icon;
  final String label;
  final String place;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: AppColors.accentSoft),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                place,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
