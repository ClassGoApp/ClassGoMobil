import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;
  static const String _localeKey = 'app_locale';

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    
    if (languageCode != null) {
      _locale = Locale(languageCode);
      debugPrint('LocaleProvider: Loaded locale from prefs: ${_locale?.languageCode}');
    } else {
      debugPrint('LocaleProvider: No locale found in prefs, using system default');
      _locale = null;
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) {
      debugPrint('LocaleProvider: Attempted to set same locale: ${locale.languageCode}');
      return;
    }

    _locale = locale;
    debugPrint('LocaleProvider: Setting locale to: ${_locale?.languageCode}');
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  void clearLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);
    _locale = null;
    notifyListeners();
  }
}
