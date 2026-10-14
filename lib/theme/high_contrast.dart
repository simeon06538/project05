import 'package:flutter/widgets.dart';

/// K-42: app-wide high-contrast switch. Widgets that read [of] rebuild
/// when it changes; Settings flips it through [controllerOf].
class HighContrastScope extends InheritedNotifier<ValueNotifier<bool>> {
  const HighContrastScope({
    super.key,
    required ValueNotifier<bool> super.notifier,
    required super.child,
  });

  /// Whether high contrast is on (false if there's no scope above).
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HighContrastScope>()
          ?.notifier
          ?.value ??
      false;

  /// The switch itself, for Settings to turn on and off.
  static ValueNotifier<bool>? controllerOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<HighContrastScope>()?.notifier;
}
