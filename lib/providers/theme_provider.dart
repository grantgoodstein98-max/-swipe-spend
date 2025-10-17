import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme (light/dark mode)
/// Follows Apple Human Interface Guidelines
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themePreferenceKey = 'isDarkMode';

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  // Apple Color Palette
  static const _iosBlue = Color(0xFF007AFF);
  static const _iosBlueLight = Color(0xFF0A84FF);
  static const _iosGreen = Color(0xFF34C759);
  static const _iosGreenLight = Color(0xFF30D158);
  static const _iosOrange = Color(0xFFFF9500);
  static const _iosOrangeLight = Color(0xFFFF9F0A);
  static const _iosRed = Color(0xFFFF3B30);
  static const _iosRedLight = Color(0xFFFF453A);

  // Light mode colors
  static const _lightBackground = Color(0xFFFFFFFF);
  static const _lightSecondary = Color(0xFFF2F2F7);
  static const _lightTertiary = Color(0xFFE5E5EA);
  static const _lightTextPrimary = Color(0xFF1C1C1E);
  static const _lightTextSecondary = Color(0xFF8E8E93);
  static const _lightTextTertiary = Color(0xFFC7C7CC);
  static const _lightDivider = Color(0xFFD1D1D6);

  // Dark mode colors
  static const _darkBackground = Color(0xFF000000);
  static const _darkSecondary = Color(0xFF1C1C1E);
  static const _darkTertiary = Color(0xFF2C2C2E);
  static const _darkDivider = Color(0xFF38383A);

  /// Light theme with Apple-inspired design
  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: _iosBlue,
          secondary: _iosGreen,
          surface: _lightSecondary,
          background: _lightBackground,
          error: _iosRed,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: _lightTextPrimary,
          onBackground: _lightTextPrimary,
          tertiary: _iosOrange,
        ),
        scaffoldBackgroundColor: _lightBackground,
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _lightBackground,
          foregroundColor: _lightTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: _lightTextPrimary,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        textTheme: const TextTheme(
          // Large Title - 34pt Bold
          displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: _lightTextPrimary,
            height: 1.2,
          ),
          // Title 1 - 28pt Bold
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: _lightTextPrimary,
            height: 1.2,
          ),
          // Title 2 - 22pt Bold
          displaySmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: _lightTextPrimary,
            height: 1.3,
          ),
          // Title 3 - 20pt Semibold
          headlineLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: _lightTextPrimary,
            height: 1.3,
          ),
          // Headline - 17pt Semibold
          headlineMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: _lightTextPrimary,
            height: 1.3,
          ),
          // Body - 17pt Regular
          bodyLarge: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.4,
            color: _lightTextPrimary,
            height: 1.35,
          ),
          // Callout - 16pt Regular
          bodyMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.3,
            color: _lightTextPrimary,
            height: 1.35,
          ),
          // Subheadline - 15pt Regular
          bodySmall: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
            color: _lightTextSecondary,
            height: 1.35,
          ),
          // Footnote - 13pt Regular
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.1,
            color: _lightTextSecondary,
            height: 1.4,
          ),
          // Caption 1 - 12pt Regular
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: _lightTextSecondary,
            height: 1.4,
          ),
          // Caption 2 - 11pt Regular
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
            color: _lightTextTertiary,
            height: 1.4,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _iosBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(0, 50),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _iosBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.4,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _lightTertiary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _iosBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: const TextStyle(
            fontSize: 17,
            color: _lightTextSecondary,
            letterSpacing: -0.4,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: _lightDivider,
          thickness: 0.5,
          space: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _lightBackground,
          selectedItemColor: _iosBlue,
          unselectedItemColor: _lightTextSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          selectedIconTheme: IconThemeData(size: 26),
          unselectedIconTheme: IconThemeData(size: 26),
        ),
      );

  /// Dark theme with Apple-inspired OLED-friendly design
  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: _iosBlueLight,
          secondary: _iosGreenLight,
          surface: _darkTertiary,
          background: _darkBackground,
          error: _iosRedLight,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
          tertiary: _iosOrangeLight,
        ),
        scaffoldBackgroundColor: _darkBackground,
        cardTheme: CardTheme(
          color: _darkSecondary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _darkDivider.withOpacity(0.5),
              width: 0.5,
            ),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkBackground,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        textTheme: const TextTheme(
          // Large Title - 34pt Bold
          displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: Colors.white,
            height: 1.2,
          ),
          // Title 1 - 28pt Bold
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: Colors.white,
            height: 1.2,
          ),
          // Title 2 - 22pt Bold
          displaySmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: Colors.white,
            height: 1.3,
          ),
          // Title 3 - 20pt Semibold
          headlineLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: Colors.white,
            height: 1.3,
          ),
          // Headline - 17pt Semibold
          headlineMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: Colors.white,
            height: 1.3,
          ),
          // Body - 17pt Regular
          bodyLarge: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.4,
            color: Colors.white,
            height: 1.35,
          ),
          // Callout - 16pt Regular
          bodyMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.3,
            color: Colors.white,
            height: 1.35,
          ),
          // Subheadline - 15pt Regular
          bodySmall: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
            color: _lightTextSecondary,
            height: 1.35,
          ),
          // Footnote - 13pt Regular
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.1,
            color: _lightTextSecondary,
            height: 1.4,
          ),
          // Caption 1 - 12pt Regular
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: _lightTextSecondary,
            height: 1.4,
          ),
          // Caption 2 - 11pt Regular
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
            color: _lightTextSecondary,
            height: 1.4,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _iosBlueLight,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(0, 50),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _iosBlueLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.4,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _iosBlueLight, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: const TextStyle(
            fontSize: 17,
            color: _lightTextSecondary,
            letterSpacing: -0.4,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: _darkDivider,
          thickness: 0.5,
          space: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _darkSecondary,
          selectedItemColor: _iosBlueLight,
          unselectedItemColor: _lightTextSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          selectedIconTheme: IconThemeData(size: 26),
          unselectedIconTheme: IconThemeData(size: 26),
        ),
      );

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveThemePreference();
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }
}
