import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

import '../theme/high_contrast.dart';

/// Frosted-glass card used across the app. Sizes itself to its child
/// unless [width] or [height] is given.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 18,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // K-42: solid panel with a bright edge instead of see-through glass.
    if (HighContrastScope.of(context)) {
      return Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1238),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: const Color(0xCCFFFFFF), width: 1.5),
        ),
        // A Material layer so tiles and buttons inside still show their
        // ink ripples on top of the solid color.
        child: Material(type: MaterialType.transparency, child: child),
      );
    }
    return GlassmorphicContainer(
      width: width,
      height: height,
      borderRadius: borderRadius,
      blur: 14,
      border: 1,
      padding: padding,
      linearGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x26FFFFFF), Color(0x0DFFFFFF)],
      ),
      borderGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x55FFFFFF), Color(0x14FFFFFF)],
      ),
      child: child,
    );
  }
}
