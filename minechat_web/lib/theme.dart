import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
}

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFFFF5722); // Orange
  static const Color primaryDarkColor = Color(0xFFE64A19); // Dark Orange
  static const Color primaryLightColor = Color(0xFFFFCCBC); // Light Orange
  static const Color secondaryColor = Color(0xFFFFA000); // Amber
  static const Color accentColor = Color(0xFFFF9800); // Orange
  static const Color errorColor = Color(0xFFE53935); // Red
  static const Color miningColor = Color(0xFFFF9800); // Orange
  static const Color walletColor = Color(0xFFFF6D00); // Deep Orange

  // Light Theme Colors
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightCardColor = Colors.white;
  static const Color lightTextColor = Color(0xFF212121);
  static const Color lightSecondaryTextColor = Color(0xFF757575);

  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Colors.white;
  static const Color darkSecondaryTextColor = Color(0xFFBDBDBD);

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      primaryContainer: primaryLightColor,
      secondary: secondaryColor,
      error: errorColor,
      background: lightBackgroundColor,
      surface: lightCardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: lightTextColor,
      onSurface: lightTextColor,
    ),
    scaffoldBackgroundColor: lightBackgroundColor,
    cardColor: lightCardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: lightSecondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    iconTheme: const IconThemeData(
      color: primaryColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      primaryContainer: primaryDarkColor,
      secondary: secondaryColor,
      error: errorColor,
      background: darkBackgroundColor,
      surface: darkCardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: darkTextColor,
      onSurface: darkTextColor,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    cardColor: darkCardColor,
    appBarTheme: AppBarTheme(
      backgroundColor: darkCardColor,
      foregroundColor: darkTextColor,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkCardColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: darkSecondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    iconTheme: const IconThemeData(
      color: primaryColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
