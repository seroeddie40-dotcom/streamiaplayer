import 'package:flutter/material.dart';
import '../core/storage/prefs_service.dart';

class LocaleProvider extends ChangeNotifier {
  final PrefsService _prefs;
  late Locale _locale;
  late bool _hasSelected;

  LocaleProvider(this._prefs) {
    _locale = Locale(_prefs.locale);
    _hasSelected = _prefs.hasSelectedLanguage;
  }

  Locale get locale => _locale;
  bool get hasSelectedLanguage => _hasSelected;

  Future<void> setLocale(String code) async {
    _locale = Locale(code);
    _hasSelected = true;
    await _prefs.setLocale(code);
    await _prefs.setLanguageSelected();
    notifyListeners(); // Wichtig: App neu rendern
  }
}
