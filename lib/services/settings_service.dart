import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

/// User ki app-level preferences: theme (light/dark/system), notifications,
/// aur language. Sab kuch device par `SharedPreferences` mein save hota hai,
/// isliye app band karke kholne par bhi wahi setting rehti hai.
class SettingsService extends ChangeNotifier {
  SettingsService._(this._prefs)
      : _themeMode = _readThemeMode(_prefs),
        _notificationsEnabled = _prefs.getBool(_kNotifications) ?? true,
        _language = AppLang.fromCode(_prefs.getString(_kLanguage));

  static const _kThemeMode = 'theme_mode';
  static const _kNotifications = 'notifications_enabled';
  static const _kLanguage = 'language';

  final SharedPreferences _prefs;

  ThemeMode _themeMode;
  bool _notificationsEnabled;
  AppLang _language;

  /// App start hone par ek baar call hota hai (main.dart mein).
  static Future<SettingsService> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService._(prefs);
  }

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  AppLang get language => _language;

  /// Current language ke hisaab se saari UI strings.
  AppStrings get t => AppStrings(_language);

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_kThemeMode, mode.name);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled == _notificationsEnabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_kNotifications, enabled);
  }

  Future<void> setLanguage(AppLang lang) async {
    if (lang == _language) return;
    _language = lang;
    notifyListeners();
    await _prefs.setString(_kLanguage, lang.code);
  }

  static ThemeMode _readThemeMode(SharedPreferences prefs) {
    final saved = prefs.getString(_kThemeMode);
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }
}

/// Screens ke liye chhota shortcut: `context.t.login`, `context.settings`.
extension SettingsContext on BuildContext {
  SettingsService get settings => watch<SettingsService>();
  AppStrings get t => watch<SettingsService>().t;
}
