import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/high_contrast.dart';

/// Dark purple gradient with two soft glows, so the glass panels on top
/// have something to blur.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
        ),
      ),
      child: Stack(
        children: [
          // K-42: no glows in high contrast, so text sits on plain dark.
          if (!HighContrastScope.of(context)) ...[
            const Positioned(
              top: -80,
              left: -60,
              child: _Glow(size: 260, color: Color(0x667B4DFF)),
            ),
            const Positioned(
              bottom: 40,
              right: -90,
              child: _Glow(size: 300, color: Color(0x44C04DFF)),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
      ),
    );
  }
}
