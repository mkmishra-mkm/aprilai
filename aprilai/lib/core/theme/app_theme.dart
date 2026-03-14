import 'package:flutter/material.dart';

import '../models/user_configuration.dart';

class AppTheme {
  AppTheme._();

  // ── Palette seeds ─────────────────────────────────────────────────────────
  static const Color _executiveBlue = Color(0xFF1A3C5E);
  static const Color _executiveGold = Color(0xFFB8960C);
  static const Color _technicalCyan = Color(0xFF00E5FF);
  static const Color _technicalBg   = Color(0xFF0D1117);
  static const Color _generalTeal   = Color(0xFF00897B);
  static const Color _generalBg     = Color(0xFFF5F5F5);

  // ── Font families (system fonts, no package needed) ───────────────────────
  //   Executive  → Roboto (Material default, clean sans-serif)
  //   Technical  → monospace (system mono on every platform)
  //   General    → Roboto with larger scale
  static const String _monoFamily = 'monospace';

  // ── Executive ─────────────────────────────────────────────────────────────
  static ThemeData get executive {
    final cs = ColorScheme.fromSeed(
      seedColor: _executiveBlue,
      secondary: _executiveGold,
      brightness: Brightness.light,
    );
    final tt = _textTheme(null, Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: tt,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: tt.titleLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cs.surface,
        selectedIconTheme: IconThemeData(color: cs.primary),
        indicatorColor: cs.primaryContainer,
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

  // ── Technical ─────────────────────────────────────────────────────────────
  static ThemeData get technical {
    final cs = ColorScheme.fromSeed(
      seedColor: _technicalCyan,
      brightness: Brightness.dark,
    ).copyWith(
      surface: _technicalBg,
      onSurface: const Color(0xFFE6EDF3),
      surfaceContainerHighest: const Color(0xFF161B22),
      outline: const Color(0xFF30363D),
    );
    final tt = _textTheme(_monoFamily, Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: _technicalBg,
      fontFamily: _monoFamily,
      textTheme: tt,
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
        titleTextStyle: tt.titleLarge?.copyWith(
          color: const Color(0xFFE6EDF3),
          fontFamily: _monoFamily,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF8B949E)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF161B22),
        selectedIconTheme: IconThemeData(color: cs.primary),
        indicatorColor: cs.primaryContainer,
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
          textStyle: const TextStyle(fontFamily: _monoFamily, fontSize: 13),
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
          borderSide: BorderSide(color: cs.primary),
        ),
      ),
    );
  }

  // ── General / Senior ──────────────────────────────────────────────────────
  static ThemeData get general {
    final cs = ColorScheme.fromSeed(
      seedColor: _generalTeal,
      brightness: Brightness.light,
    ).copyWith(surface: _generalBg);
    final tt = _textTheme(null, Brightness.light, scale: 1.18);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: _generalBg,
      textTheme: tt,
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: tt.titleLarge?.copyWith(
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
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((_) =>
            tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Shared text theme builder ─────────────────────────────────────────────
  static TextTheme _textTheme(
    String? fontFamily,
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
          inherit: true,
        );

    return base.copyWith(
      displayLarge:  s(32, FontWeight.w300, spacing: -1),
      displayMedium: s(28, FontWeight.w300),
      displaySmall:  s(24, FontWeight.w400),
      headlineLarge:  s(24, FontWeight.w600),
      headlineMedium: s(20, FontWeight.w600),
      headlineSmall:  s(18, FontWeight.w600),
      titleLarge:  s(18, FontWeight.w500),
      titleMedium: s(15, FontWeight.w500),
      titleSmall:  s(13, FontWeight.w500),
      bodyLarge:  s(14, FontWeight.w400, height: 1.5),
      bodyMedium: s(13, FontWeight.w400, height: 1.5),
      bodySmall:  s(12, FontWeight.w400, height: 1.5),
      labelLarge:  s(13, FontWeight.w600, spacing: 0.3),
      labelMedium: s(12, FontWeight.w500),
      labelSmall:  s(11, FontWeight.w500),
    );
  }

  // ── Factory ───────────────────────────────────────────────────────────────
  static ThemeData forRole(UserRole role) {
    switch (role) {
      case UserRole.executive:  return executive;
      case UserRole.technical:  return technical;
      case UserRole.general:    return general;
    }
  }

  static Brightness brightnessForRole(UserRole role) =>
      role == UserRole.technical ? Brightness.dark : Brightness.light;
}
