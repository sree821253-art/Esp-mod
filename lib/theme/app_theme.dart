import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Circuit Board Color Palette
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonBlue = Color(0xFF00B8D4);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonRed = Color(0xFFFF1744);
  static const Color neonAmber = Color(0xFFFFAB00);
  static const Color circuitDark = Color(0xFF0A0E14);
  static const Color circuitDarkAlt = Color(0xFF0D1117);
  static const Color circuitLine = Color(0xFF1A2332);
  static const Color circuitGlow = Color(0xFF00E5FF);

  // Glass effect colors
  static const Color glassLight = Color(0xCCFFFFFF);
  static const Color glassDark = Color(0x33FFFFFF);
  static const Color glassBorder = Color(0x66FFFFFF);

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: circuitDark,
    colorScheme: ColorScheme.dark(
      primary: neonCyan,
      secondary: neonBlue,
      surface: circuitDarkAlt,
      error: neonRed,
      onPrimary: circuitDark,
      onSecondary: circuitDark,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.orbitronTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      headlineLarge: GoogleFonts.orbitron(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
      ),
      headlineMedium: GoogleFonts.orbitron(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 1.5,
      ),
      titleLarge: GoogleFonts.rajdhani(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: GoogleFonts.rajdhani(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.rajdhani(
        fontSize: 16,
        color: Colors.white70,
      ),
      bodyMedium: GoogleFonts.rajdhani(
        fontSize: 14,
        color: Colors.white70,
      ),
      labelLarge: GoogleFonts.orbitron(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: neonCyan,
        letterSpacing: 1,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: neonCyan,
        letterSpacing: 2,
      ),
      iconTheme: const IconThemeData(color: neonCyan),
    ),
    cardTheme: CardThemeData(
      color: circuitDarkAlt.withOpacity(0.8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: neonCyan.withOpacity(0.3), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonCyan.withOpacity(0.2),
        foregroundColor: neonCyan,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: neonCyan, width: 1),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: circuitDarkAlt.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: neonCyan.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: neonCyan.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonCyan, width: 2),
      ),
      labelStyle: GoogleFonts.rajdhani(color: Colors.white70),
      hintStyle: GoogleFonts.rajdhani(color: Colors.white38),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: circuitDarkAlt.withOpacity(0.95),
      selectedItemColor: neonCyan,
      unselectedItemColor: Colors.white38,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return neonCyan;
        }
        return Colors.white38;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return neonCyan.withOpacity(0.3);
        }
        return Colors.white12;
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: neonCyan,
      inactiveTrackColor: neonCyan.withOpacity(0.2),
      thumbColor: neonCyan,
      overlayColor: neonCyan.withOpacity(0.2),
      valueIndicatorColor: neonCyan,
      valueIndicatorTextStyle: GoogleFonts.orbitron(
        fontSize: 12,
        color: circuitDark,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: circuitDarkAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: neonCyan.withOpacity(0.5)),
      ),
      titleTextStyle: GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: neonCyan,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: circuitDarkAlt,
      contentTextStyle: GoogleFonts.rajdhani(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: neonCyan.withOpacity(0.5)),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // Light Theme with Glassmorphism
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F4F8),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF0D47A1),
      secondary: const Color(0xFF00ACC1),
      surface: Colors.white,
      error: Colors.red.shade600,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1A1A2E),
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    ).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1A2E),
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1A1A2E),
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: const Color(0xFF4A4A4A),
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF4A4A4A),
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0D47A1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white.withOpacity(0.8),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1A2E),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withOpacity(0.8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white.withOpacity(0.9),
      selectedItemColor: const Color(0xFF0D47A1),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF0D47A1);
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF0D47A1).withOpacity(0.3);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  );
}
