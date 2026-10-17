/// The one place the app gets the server's base URL from (task B-13).
///
/// Defaults to localhost (iOS simulator, Flutter web, desktop). Override per
/// device without editing code:
///   Android emulator: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
///   Real phone:       flutter run --dart-define=API_BASE_URL=http://<your-computer-LAN-IP>:3000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);
}
