import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'premium_theme.dart';

/// Global theme notifier for app-wide theme changes
/// Centralized in core to prevent type mismatch between main entry points
class ThemeNotifier extends ChangeNotifier {
  /// SharedPreferences key holding the user's chosen theme mode.
  static const String _prefsKey = 'theme_mode';

  static const List<String> _knownModes = [
    PremiumTheme.lightMode,
    PremiumTheme.darkMode,
    PremiumTheme.sunsetMode,
    PremiumTheme.pinkMode,
    PremiumTheme.cyberpunkMode,
    PremiumTheme.islandGoldMode,
    PremiumTheme.bviPrideMode,
  ];

  /// [initialMode] is the saved choice read by [loadSavedMode] before the
  /// first frame, so the app starts in the user's theme instead of Light.
  ThemeNotifier({String? initialMode}) {
    if (initialMode != null && _knownModes.contains(initialMode)) {
      _currentMode = initialMode;
      PremiumTheme.setThemeMode(initialMode);
    }
  }

  String _currentMode = PremiumTheme.lightMode;

  String get currentMode => _currentMode;

  /// Reads the saved theme mode, or null if none has been saved.
  static Future<String?> loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsKey);
    } catch (e) {
      debugPrint('⚠️ Could not load saved theme: $e');
      return null;
    }
  }

  void setTheme(String mode) {
    _currentMode = mode;
    PremiumTheme.setThemeMode(mode);
    notifyListeners();
    _saveMode(mode);
  }

  /// Shows Light for this session when a premium theme is active but premium
  /// could not be confirmed. The saved choice is kept, so a premium user who
  /// was offline gets their theme back on the next launch.
  void fallBackFromPremiumTheme() {
    if (!PremiumTheme.isPremiumTheme(_currentMode)) return;
    _currentMode = PremiumTheme.lightMode;
    PremiumTheme.setThemeMode(PremiumTheme.lightMode);
    notifyListeners();
  }

  Future<void> _saveMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode);
    } catch (e) {
      debugPrint('⚠️ Could not save theme: $e');
    }
  }

  ThemeData get currentTheme => PremiumTheme.currentTheme;
}
