import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ================== BRAND COLORS (Opal/OneSec Inspired) ==================
  
  // Primary Gradient Colors
  static const primaryPurple = Color(0xFF667EEA);
  static const primaryIndigo = Color(0xFF764BA2);
  static const accentCyan = Color(0xFF00D9FF);
  static const accentPink = Color(0xFFFF6B9D);
  
  // Status Colors
  static const successGreen = Color(0xFF00B894);
  static const warningOrange = Color(0xFFFFAB00);
  static const dangerRed = Color(0xFFFF4757);
  static const dangerRedLight = Color(0xFFFF6B81);
  
  // Dark Mode Colors (Main Theme)
  static const darkBg = Color(0xFF0A0A0F);
  static const darkBgSecondary = Color(0xFF12121A);
  static const darkSurface = Color(0xFF1A1A25);
  static const darkSurfaceLight = Color(0xFF252532);
  static const darkText = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextMuted = Color(0xFF64748B);
  
  // Light Mode Colors
  static const lightBg = Color(0xFFF1F5F9);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF64748B);

  // ================== GRADIENTS ==================
  
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryIndigo],
  );
  
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A0A0F),
      Color(0xFF12121A),
      Color(0xFF1A1A25),
    ],
  );
  
  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1E2E),
      Color(0xFF16161F),
    ],
  );
  
  static const dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dangerRed, Color(0xFFFF6B81)],
  );
  
  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successGreen, Color(0xFF00E6A7)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, accentPink],
  );

  // ================== SHADOWS & GLOWS ==================
  
  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: primaryPurple.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get dangerGlow => [
    BoxShadow(
      color: dangerRed.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // ================== DARK THEME (PRIMARY) ==================
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'SF Pro Display', // Will fallback to system font
    
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      onPrimary: Colors.white,
      secondary: accentCyan,
      onSecondary: darkBg,
      surface: darkSurface,
      onSurface: darkText,
      error: dangerRed,
      onError: Colors.white,
    ),
    
    scaffoldBackgroundColor: darkBg,
    
    // Card Theme
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
    ),
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: darkBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: darkText,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: darkText),
    ),
    
    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    
    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryPurple,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryPurple,
      inactiveTrackColor: darkSurfaceLight,
      thumbColor: Colors.white,
      overlayColor: primaryPurple.withOpacity(0.2),
      trackHeight: 8,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
    ),
    
    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return darkTextMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryPurple;
        }
        return darkSurfaceLight;
      }),
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: darkText,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
      ),
      displayMedium: TextStyle(
        color: darkText,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      headlineLarge: TextStyle(
        color: darkText,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: darkText,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: darkText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: darkText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: darkText,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: darkTextSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: darkTextMuted,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: darkText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );

  // ================== LIGHT THEME ==================
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      onPrimary: Colors.white,
      secondary: primaryIndigo,
      surface: lightSurface,
      onSurface: lightText,
      error: dangerRed,
    ),
    
    scaffoldBackgroundColor: lightBg,
    
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        color: lightText,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: lightText),
    ),
    
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: lightText, fontWeight: FontWeight.w800),
      headlineLarge: TextStyle(color: lightText, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: lightText, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: lightTextSecondary),
      bodySmall: TextStyle(color: lightTextSecondary),
    ),
  );
}