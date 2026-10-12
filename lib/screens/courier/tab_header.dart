import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Title plus a small purple pill, matching the customer screens.
class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title, required this.pill});

  final String title;
  final String pill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(90),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            pill,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
