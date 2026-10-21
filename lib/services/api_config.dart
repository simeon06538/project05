import 'package:flutter/foundation.dart';

/// The one place the app gets the server's base URL from (task B-13).
///
/// Defaults to the Android emulator host or localhost on other platforms. Override per
/// device without editing code:
///   Android emulator: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
///   Real phone:       flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:3000
class ApiConfig {
  static const String _override = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl => _override.isNotEmpty
      ? _override
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:3000'
      : 'http://localhost:3000';

  static Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);
}
