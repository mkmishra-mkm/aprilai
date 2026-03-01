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

  // ── Executive Theme (Material 3, Light, medium density) ───────────────────
  static ThemeData get executive {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _executiveBlue,
      secondary: _executiveGold,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _executiveTextTheme,
      cardTheme: CardTheme(
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
        titleTextStyle: _executiveTextTheme.titleLarge?.copyWith(
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
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _technicalBg,
      textTheme: _technicalTextTheme,
      cardTheme: CardTheme(
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
        titleTextStyle: _technicalTextTheme.titleLarge?.copyWith(
          color: const Color(0xFFE6EDF3),
          fontFamily: 'JetBrains Mono',
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
          textStyle: GoogleFonts.jetBrainsMono(fontSize: 13),
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
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _generalBg,
      textTheme: _generalTextTheme,
      cardTheme: CardTheme(
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
        titleTextStyle: _generalTextTheme.titleLarge?.copyWith(
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
          textStyle: _generalTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: _generalTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return _generalTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          );
        }),
      ),
    );
  }

  // ── Text Themes ───────────────────────────────────────────────────────────
  static TextTheme get _executiveTextTheme => GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -1),
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 14, height: 1.5),
          bodyMedium: TextStyle(fontSize: 13, height: 1.5),
          labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      );

  static TextTheme get _technicalTextTheme {
    const mono = TextStyle(fontFamily: 'monospace');
    return GoogleFonts.jetBrainsMonoTextTheme(
      TextTheme(
        displayLarge: mono.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
        headlineLarge: mono.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
        headlineMedium: mono.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        titleLarge: mono.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        titleMedium: mono.copyWith(fontSize: 13),
        bodyLarge: mono.copyWith(fontSize: 13, height: 1.6),
        bodyMedium: mono.copyWith(fontSize: 12, height: 1.6),
        labelLarge: mono.copyWith(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    );
  }

  static TextTheme get _generalTextTheme => GoogleFonts.nunitoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 18, height: 1.6),
          bodyMedium: TextStyle(fontSize: 16, height: 1.6),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );

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

  static Brightness brightnessForRole(UserRole role) {
    return role == UserRole.technical ? Brightness.dark : Brightness.light;
  }
}
