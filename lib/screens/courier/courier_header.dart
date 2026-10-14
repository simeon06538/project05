import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// "AM" for "Alex Morgan", "C" for "Cher", "?" when there's no name.
String initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

/// Good morning / afternoon / evening for the given time.
String greetingFor(DateTime time) {
  if (time.hour < 12) return 'Good morning';
  if (time.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// K-17: avatar with initials, a time-of-day greeting and the courier's
/// name, shown above the tabs.
class CourierHeader extends StatelessWidget {
  const CourierHeader({super.key, required this.name, this.now});

  final String name;

  /// Overridable clock so tests get a stable greeting.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accentSoft, AppColors.accent],
            ),
            border: Border.all(color: const Color(0x55FFFFFF)),
          ),
          child: Text(
            initialsFor(name),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingFor(now ?? DateTime.now()),
                style: textTheme.bodySmall,
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(70),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delivery_dining,
                size: 14,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 4),
              Text(
                'Courier',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
