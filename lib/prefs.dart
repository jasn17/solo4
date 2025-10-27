import 'package:shared_preferences/shared_preferences.dart';

/// Key/value storage for app preferences.
class AppPrefs {
  static const _kShowCompleted = 'show_completed';
  static const _kFirstRunShown = 'first_run_shown';

  /// Returns whether completed items should be displayed
  Future<bool> getShowCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowCompleted) ?? true;
    // Defaults to true so nothing appears to 'disappear' on first run.
  }

  /// Persists the 'show completed' preference
  Future<void> setShowCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowCompleted, value);
  }

  /// One-time welcome hint flag
  Future<bool> getFirstRunShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFirstRunShown) ?? false;
  }

  /// Mark first-run hint as shown
  Future<void> setFirstRunShown(bool shown) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFirstRunShown, shown);
  }
}
