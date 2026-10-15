import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';

/// K-44: three quick slides explaining the courier flow, shown on first
/// launch (and from Settings > Replay intro). [onDone] runs on "Get
/// started" or "Skip".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide(this.animation, this.icon, this.title, this.body);

  final String animation;
  final IconData? icon;
  final String title;
  final String body;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _slides = [
    _Slide(
      'assets/lottie/pulse.json',
      Icons.delivery_dining,
      'Pick a request',
      'See the pickup, drop-off, walking time and pay before you accept. '
          'Filter by restaurant, distance or tips.',
    ),
    _Slide(
      'assets/lottie/pulse.json',
      Icons.shopping_bag_outlined,
      'Pick up and deliver',
      'Show the Paw Points order number at the counter, tick the checklist, '
          'then mark it picked up and delivered.',
    ),
    _Slide(
      'assets/lottie/success.json',
      null,
      'Get paid',
      'The delivery fee and tip go to your demo balance. Set a daily goal '
          'in Settings and watch your week add up.',
    ),
  ];

  final _pages = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: widget.onDone,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pages,
                        onPageChanged: (page) => setState(() => _page = page),
                        children: [
                          for (final slide in _slides)
                            Center(
                              child: SingleChildScrollView(
                                child: GlassPanel(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    28,
                                    20,
                                    28,
                                  ),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: 160,
                                        height: 160,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Lottie.asset(slide.animation),
                                            if (slide.icon != null)
                                              Icon(
                                                slide.icon,
                                                size: 44,
                                                color: AppColors.textPrimary,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        slide.title,
                                        textAlign: TextAlign.center,
                                        style: textTheme.headlineSmall,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        slide.body,
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Slide ${_page + 1} of ${_slides.length}',
                      excludeSemantics: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _slides.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _page ? 22 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _page
                                    ? AppColors.accentSoft
                                    : const Color(0x55FFFFFF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: _isLast ? 'Get started' : 'Next',
                      onPressed: _next,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
