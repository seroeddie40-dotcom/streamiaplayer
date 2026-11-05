import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  final SharedPreferences _prefs;
  PrefsService(this._prefs);

  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale';
  static const _languageSelectedKey = 'language_selected';
  static const _macKey = 'mac_address';
  static const _pinKey = 'parental_pin';
  static const _lockedFoldersKey = 'locked_folders';

  String get themeMode => _prefs.getString(_themeKey) ?? 'dark';
  Future<void> setThemeMode(String mode) => _prefs.setString(_themeKey, mode);

  String get locale => _prefs.getString(_localeKey) ?? 'en';
  Future<void> setLocale(String code) => _prefs.setString(_localeKey, code);

  bool get hasSelectedLanguage => _prefs.getBool(_languageSelectedKey) ?? false;
  Future<void> setLanguageSelected() =>
      _prefs.setBool(_languageSelectedKey, true);

  String? get macAddress => _prefs.getString(_macKey);
  Future<void> setMacAddress(String mac) => _prefs.setString(_macKey, mac);

  String? get parentalPin => _prefs.getString(_pinKey);
  Future<void> setParentalPin(String pin) => _prefs.setString(_pinKey, pin);

  List<String> get lockedFolders =>
      _prefs.getStringList(_lockedFoldersKey) ?? [];
  Future<void> setLockedFolders(List<String> folders) =>
      _prefs.setStringList(_lockedFoldersKey, folders);

  Future<void> clear() => _prefs.clear();
}
