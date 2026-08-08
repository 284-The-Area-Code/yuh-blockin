import 'package:flutter/material.dart';
import 'premium_theme.dart';

/// Global theme notifier for app-wide theme changes
/// Centralized in core to prevent type mismatch between main entry points
class ThemeNotifier extends ChangeNotifier {
  String _currentMode = PremiumTheme.lightMode;

  String get currentMode => _currentMode;

  void setTheme(String mode) {
    _currentMode = mode;
    PremiumTheme.setThemeMode(mode);
    notifyListeners();
  }

  ThemeData get currentTheme => PremiumTheme.currentTheme;
}
