import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;

    if (_themeMode == newMode) return;

    _themeMode = newMode;

    // Actualizamos la Barra de Estado (Status Bar) inmediatamente
    _updateSystemStatusBar();

    notifyListeners();
  }

  void _updateSystemStatusBar() {
    final isDark = _themeMode == ThemeMode.dark;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: isDark ? AppColors.deepDarkBg : AppColors.softWhiteBg,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    ));
  }
}