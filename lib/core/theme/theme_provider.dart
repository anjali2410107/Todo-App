import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _kThemeKey = 'is_dark_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider(bool isDarkMode) {
    _isDarkMode = isDarkMode;
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kThemeKey, _isDarkMode);
  }

  static Future<bool> getSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kThemeKey) ?? false;
  }

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: false,
      scaffoldBackgroundColor: const Color(0xFFF8F9FF),
      primaryColor: const Color(0xFF6366F1),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6366F1),
        secondary: Color(0xFF8B5CF6),
        surface: Colors.white,
        background: Color(0xFFF8F9FF),
        onPrimary: Colors.white,
        onSurface: Color(0xFF1E1B4B),
        onBackground: Color(0xFF1E1B4B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9FF),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1E1B4B)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1E1B4B),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardColor: Colors.white,
      dividerColor: Color(0xFFE5E7EB),
      iconTheme: const IconThemeData(color: Color(0xFF1E1B4B)),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1E1B4B)),
        bodyMedium: TextStyle(color: Color(0xFF6B7280)),
        titleLarge: TextStyle(
            color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6366F1),
        unselectedItemColor: Color(0xFF9CA3AF),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF6366F1);
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: false,
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      primaryColor: const Color(0xFF6366F1),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6366F1),
        secondary: Color(0xFF8B5CF6),
        surface: Color(0xFF1A1A2E),
        background: Color(0xFF0F0F1A),
        onPrimary: Colors.white,
        onSurface: Color(0xFFF1F5F9),
        onBackground: Color(0xFFF1F5F9),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0F1A),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF1F5F9),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardColor: const Color(0xFF1A1A2E),
      dividerColor: const Color(0xFF2D2D44),
      iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFF1F5F9)),
        bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
        titleLarge: TextStyle(
            color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A2E),
        selectedItemColor: Color(0xFF6366F1),
        unselectedItemColor: Color(0xFF64748B),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF6366F1);
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: Color(0xFF4B5563), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      dialogBackgroundColor: const Color(0xFF1A1A2E),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1A1A2E),
      ),
    );
  }
}