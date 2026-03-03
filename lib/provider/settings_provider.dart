import 'package:flutter/foundation.dart';

class SettingsProvider with ChangeNotifier {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  Map<String, dynamic> get settings => _settings;
  bool get isLoading => _isLoading;

  void setSettings(Map<String, dynamic> newSettings) {
    _settings = newSettings;
    _isLoading = false;
    notifyListeners();
  }

  void updateSetting(String key, dynamic value) {
    if (_settings.containsKey(key)) {
      _settings[key] = value;
      notifyListeners();
    }
  }

  void reloadSettings(Map<String, dynamic> newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  dynamic getSetting(String key) {
    return _settings[key];
  }
}
