import 'package:flutter/services.dart';

/// K-21: the app's vibration patterns in one place, so every screen feels
/// the same. These do nothing on web and desktop.
abstract final class Haptics {
  /// A delivery was accepted.
  static Future<void> success() => HapticFeedback.mediumImpact();

  /// Moved a delivery to its next step (e.g. picked up).
  static Future<void> step() => HapticFeedback.lightImpact();

  /// Delivery finished and paid out.
  static Future<void> delivered() => HapticFeedback.heavyImpact();

  /// Something went wrong or the request was taken.
  static Future<void> problem() => HapticFeedback.vibrate();

  /// Flipped a switch, like going online or offline.
  static Future<void> toggle() => HapticFeedback.selectionClick();
}
