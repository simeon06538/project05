import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';

/// K-13: explains that a request can't be accepted any more - another
/// courier took it ([taken]) or it was cancelled/removed - instead of
/// showing a raw error.
Future<void> showRequestGone(BuildContext context, {required bool taken}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(110),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  taken ? Icons.directions_run : Icons.event_busy_outlined,
                  color: AppColors.textPrimary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                taken
                    ? 'Someone got there first'
                    : 'Request no longer available',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                taken
                    ? 'Another courier accepted this request a moment ago. '
                          "We'll refresh the list so you can pick another."
                    : 'This request was cancelled or removed. '
                          "We'll refresh the list so you can pick another.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Back to requests',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
