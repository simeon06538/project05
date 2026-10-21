import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// "0.25", "0.5", "1" - miles without trailing zeros.
String formatMiles(double miles) {
  final text = miles.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// K-37: one-line slider for the furthest a courier wants to go, in
/// quarter miles. The right end means "Any distance" (null).
class DistanceFilter extends StatelessWidget {
  const DistanceFilter({
    super.key,
    required this.maxMiles,
    required this.onChanged,
  });

  final double? maxMiles;
  final ValueChanged<double?> onChanged;

  static const _min = 0.25;
  static const _anyStop = 1.75; // one step past 1.5 mi

  @override
  Widget build(BuildContext context) {
    final label = maxMiles == null
        ? 'Any distance'
        : 'Within ${formatMiles(maxMiles!)} mi';
    return Row(
      children: [
        const Icon(Icons.straighten, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: maxMiles ?? _anyStop,
            min: _min,
            max: _anyStop,
            divisions: 6,
            label: label,
            semanticFormatterCallback: (_) => label,
            activeColor: AppColors.accentStrong,
            inactiveColor: AppColors.accentSoft.withAlpha(70),
            onChanged: (v) => onChanged(v >= _anyStop ? null : v),
          ),
        ),
      ],
    );
  }
}
