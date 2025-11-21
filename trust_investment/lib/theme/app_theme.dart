import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFF0B90B); // Binance gold
  static const Color backgroundDark = Color(0xFF0B0E11); // Deep black
  static const Color surfaceDark = Color(0xFF1E2329); // Card dark
  static const Color accentCoffee = Color(0xFF3E2723); // Coffee tone
  static const Color successGreen = Color(0xFF00FF88);
  static const Color dangerRed = Color(0xFFFF4D4D);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentCoffee,
      background: backgroundDark,
      surface: surfaceDark,
      error: dangerRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: primaryColor,
      textColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
  );
}
