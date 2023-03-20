import 'package:acter/common/themes/seperated_themes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

AppTheme currentTheme = AppTheme();

extension CustomColorScheme on ColorScheme {
  Color get success => const Color(0xFF67A24A);
  Color get tertiary2 => const Color(0xFFFFC333);
  Color get tertiary3 => const Color(0xFF3AE3E0);
  Color get neutral => const Color(0xFF121212);
  Color get neutral2 => const Color(0xFF2F2F2F);
  Color get neutral3 => const Color(0xFF5D5D5D);
  Color get neutral4 => const Color(0xFF898989);
  Color get neutral5 => const Color(0xFFB7B7B7);
  Color get neutral6 => const Color(0xFFE5E5E5);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      typography: Typography(
        black: GoogleFonts.interTextTheme(
          const TextTheme(
            headlineLarge: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            headlineMedium: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
            headlineSmall: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
            titleMedium: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w500,
            ),
            titleSmall: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            bodyLarge: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
            bodyMedium: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            bodySmall: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            labelLarge: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            labelMedium: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            labelSmall: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xff122D46),
        surface: Color(0xff122D46),
        secondary: Colors.black,
        background: Colors.black,
        tertiary: Color(0xffFF8E00),
        error: Color(0xffD03838),
      ),
      splashColor: Colors.transparent,
      useMaterial3: true,
      dividerTheme: const DividerThemeData(
        indent: 75,
        endIndent: 15,
        thickness: 0.5,
        color: AppCommonTheme.dividerColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppCommonTheme.transparentColor,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xff1D293E),
        unselectedLabelStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        selectedLabelStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        selectedIconTheme: IconThemeData(color: Colors.white, size: 18),
        unselectedIconTheme: IconThemeData(color: Colors.white, size: 18),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xff1D293E),
        indicatorColor: Color(0xff1E4E7B),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedLabelTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedIconTheme: IconThemeData(color: Colors.white, size: 18),
        unselectedIconTheme: IconThemeData(color: Colors.white, size: 18),
      ),
    );
  }
}
