import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';

/// K-22: rough walking time for a delivery, at about 3 mph (20 min per
/// mile), rounded up and never less than a minute. The tiny offset stops
/// float noise (e.g. 22.000000000000004) from adding a whole minute.
int walkingMinutes(double miles) =>
    (miles * 20 - 1e-9).ceil().clamp(1, 1000).toInt();

/// "8 min walk", or "1 h 5 min walk" for long trips.
String walkingLabel(double miles) {
  final minutes = walkingMinutes(miles);
  if (minutes < 60) return '$minutes min walk';
  final rest = minutes % 60;
  return rest == 0
      ? '${minutes ~/ 60} h walk'
      : '${minutes ~/ 60} h $rest min walk';
}

/// K-23: how a request's age is flagged on its card.
enum RequestAge { fresh, normal, waiting }

/// Under 2 minutes old is "New"; over 15 minutes is "Waiting a while".
RequestAge requestAge(Order order, {DateTime? now}) {
  final age = (now ?? DateTime.now()).difference(order.createdAt);
  if (age < const Duration(minutes: 2)) return RequestAge.fresh;
  if (age > const Duration(minutes: 15)) return RequestAge.waiting;
  return RequestAge.normal;
}

/// Small pill for [RequestAge.fresh] and [RequestAge.waiting]; nothing for
/// a normal request.
class AgeBadge extends StatelessWidget {
  const AgeBadge({super.key, required this.age});

  final RequestAge age;

  static const _freshGreen = Color(0xFF4ADE80);
  static const _waitingAmber = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (age) {
      RequestAge.fresh => ('New', _freshGreen, Icons.fiber_new_rounded),
      RequestAge.waiting => (
        'Waiting a while',
        _waitingAmber,
        Icons.hourglass_bottom_rounded,
      ),
      RequestAge.normal => ('', Colors.transparent, Icons.circle),
    };
    if (age == RequestAge.normal) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(150)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
