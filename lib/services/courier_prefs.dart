import 'package:shared_preferences/shared_preferences.dart';

/// K-43: courier settings that survive closing the app - display name,
/// daily goal, online status and high contrast. Unset values are null so
/// the app can fall back to its defaults.
class CourierPrefs {
  CourierPrefs(this._prefs);

  static Future<CourierPrefs> load() async =>
      CourierPrefs(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _nameKey = 'courier.name';
  static const _goalKey = 'courier.dailyGoalCents';
  static const _onlineKey = 'courier.online';
  static const _contrastKey = 'courier.highContrast';

  String? get name => _prefs.getString(_nameKey);
  Future<void> setName(String name) => _prefs.setString(_nameKey, name);

  int? get dailyGoalCents => _prefs.getInt(_goalKey);
  Future<void> setDailyGoalCents(int cents) => _prefs.setInt(_goalKey, cents);

  bool? get online => _prefs.getBool(_onlineKey);
  Future<void> setOnline(bool online) => _prefs.setBool(_onlineKey, online);

  bool? get highContrast => _prefs.getBool(_contrastKey);
  Future<void> setHighContrast(bool on) => _prefs.setBool(_contrastKey, on);
}
