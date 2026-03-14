import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_configuration.dart';

class AppTheme {
  AppTheme._();

  // ── Shared palette seeds ──────────────────────────────────────────────────
  static const Color _executiveBlue = Color(0xFF1A3C5E);
  static const Color _executiveGold = Color(0xFFB8960C);
  static const Color _technicalCyan = Color(0xFF00E5FF);
  static const Color _technicalBg = Color(0xFF0D1117);
  static const Color _generalTeal = Color(0xFF00897B);
  static const Color _generalBg = Color(0xFFF5F5F5);

  // ── Font family helpers (avoids broken GoogleFonts.*TextTheme() const map) ─
  static String get _interFamily => GoogleFonts.inter().fontFamily!;
  static String get _jetbrainsFamily => GoogleFonts.jetBrainsMono().fontFamily!;
  static String get _nunitoFamily => GoogleFonts.nunito().fontFamily!;

  // ── Executive Theme (Material 3, Light, medium density) ───────────────────
  static ThemeData get executive {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _executiveBlue,
      secondary: _executiveGold,
      brightness: Brightness.light,
    );
    final textTheme = _buildTextTheme(_interFamily, Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _interFamily,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        indicatorColor: colorScheme.primaryContainer,
      ),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // ── Technical Theme (Material 3, Dark, high density) ─────────────────────
  static ThemeData get technical {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _technicalCyan,
      brightness: Brightness.dark,
    ).copyWith(
      surface: _technicalBg,
      onSurface: const Color(0xFFE6EDF3),
      surfaceContainerHighest: const Color(0xFF161B22),
      outline: const Color(0xFF30363D),
    );
    final textTheme = _buildTextTheme(_jetbrainsFamily, Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _technicalBg,
      fontFamily: _jetbrainsFamily,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF30363D)),
        ),
        color: const Color(0xFF161B22),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: const Color(0xFFE6EDF3),
          fontFamily: _jetbrainsFamily,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF8B949E)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF161B22),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        indicatorColor: colorScheme.primaryContainer,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF30363D),
        space: 1,
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: TextStyle(fontFamily: _jetbrainsFamily, fontSize: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
    );
  }

  // ── General / Senior Theme (High contrast, low density, large targets) ────
  static ThemeData get general {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _generalTeal,
      brightness: Brightness.light,
    ).copyWith(
      surface: _generalBg,
    );
    final textTheme = _buildTextTheme(_nunitoFamily, Brightness.light,
        scale: 1.15);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _generalBg,
      fontFamily: _nunitoFamily,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((_) =>
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Text theme builder (avoids GoogleFonts.*TextTheme const map issue) ────
  static TextTheme _buildTextTheme(
    String fontFamily,
    Brightness brightness, {
    double scale = 1.0,
  }) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    TextStyle s(double size, FontWeight weight, {double? height, double? spacing}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size * scale,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
        );

    return base.copyWith(
      displayLarge: s(32, FontWeight.w300, spacing: -1),
      displayMedium: s(28, FontWeight.w300),
      displaySmall: s(24, FontWeight.w400),
      headlineLarge: s(24, FontWeight.w600),
      headlineMedium: s(20, FontWeight.w600),
      headlineSmall: s(18, FontWeight.w600),
      titleLarge: s(18, FontWeight.w500),
      titleMedium: s(15, FontWeight.w500),
      titleSmall: s(13, FontWeight.w500),
      bodyLarge: s(14, FontWeight.w400, height: 1.5),
      bodyMedium: s(13, FontWeight.w400, height: 1.5),
      bodySmall: s(12, FontWeight.w400, height: 1.5),
      labelLarge: s(13, FontWeight.w600, spacing: 0.3),
      labelMedium: s(12, FontWeight.w500),
      labelSmall: s(11, FontWeight.w500),
    );
  }

  // ── Factory accessor ──────────────────────────────────────────────────────
  static ThemeData forRole(UserRole role) {
    switch (role) {
      case UserRole.executive:
        return executive;
      case UserRole.technical:
        return technical;
      case UserRole.general:
        return general;
    }
  }

  static Brightness brightnessForRole(UserRole role) =>
      role == UserRole.technical ? Brightness.dark : Brightness.light;
}
