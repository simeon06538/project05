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
/// name, shown above the tabs. K-18 adds the Online/Offline switch.
class CourierHeader extends StatelessWidget {
  const CourierHeader({
    super.key,
    required this.name,
    this.now,
    this.online = true,
    this.onOnlineChanged,
  });

  final String name;

  /// K-18: whether the courier is taking requests; tapping the pill
  /// calls [onOnlineChanged] with the opposite value.
  final bool online;
  final ValueChanged<bool>? onOnlineChanged;

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
              // K-30: deep enough for white initials to pass WCAG contrast.
              colors: [Color(0xFF7B5CE6), Color(0xFF5A3DC0)],
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
        _OnlinePill(online: online, onChanged: onOnlineChanged),
      ],
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill({required this.online, required this.onChanged});

  final bool online;
  final ValueChanged<bool>? onChanged;

  static const _onlineGreen = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: online,
      button: true,
      label: online ? 'Online, tap to go offline' : 'Offline, tap to go online',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!online),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: online
                ? AppColors.accent.withAlpha(150)
                : const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: online ? AppColors.accentSoft : const Color(0x33FFFFFF),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? _onlineGreen : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                online ? 'Online' : 'Offline',
                style: TextStyle(
                  color: online
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
