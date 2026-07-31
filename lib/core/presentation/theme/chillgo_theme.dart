import 'package:flutter/material.dart';

import 'chillgo_colors.dart';

abstract final class ChillGoTheme {
  static ThemeData get sunshine {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: ChillGoColors.coral,
          brightness: Brightness.light,
          surface: ChillGoColors.surface,
        ).copyWith(
          primary: ChillGoColors.coral,
          onPrimary: Colors.white,
          primaryContainer: ChillGoColors.coralSoft,
          onPrimaryContainer: ChillGoColors.ink,
          secondary: ChillGoColors.sky,
          onSecondary: ChillGoColors.ink,
          secondaryContainer: ChillGoColors.skySoft,
          onSecondaryContainer: ChillGoColors.ink,
          tertiary: ChillGoColors.leaf,
          onTertiary: Colors.white,
          tertiaryContainer: ChillGoColors.leafSoft,
          onTertiaryContainer: ChillGoColors.ink,
          error: ChillGoColors.danger,
          surface: ChillGoColors.surface,
          onSurface: ChillGoColors.ink,
          outline: ChillGoColors.outline,
          outlineVariant: ChillGoColors.outline,
        );

    final baseTextTheme = ThemeData.light().textTheme.apply(
      bodyColor: ChillGoColors.ink,
      displayColor: ChillGoColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ChillGoColors.canvas,
      canvasColor: ChillGoColors.canvas,
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ChillGoColors.canvas,
        foregroundColor: ChillGoColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ChillGoColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: IconThemeData(color: ChillGoColors.ink),
      ),
      cardTheme: CardThemeData(
        color: ChillGoColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: ChillGoColors.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ChillGoColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ChillGoColors.surface,
          foregroundColor: ChillGoColors.ink,
          elevation: 0,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: ChillGoColors.outline),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ChillGoColors.ink,
          minimumSize: const Size(48, 52),
          side: const BorderSide(color: ChillGoColors.outline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ChillGoColors.coral,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ChillGoColors.surface,
        labelStyle: const TextStyle(color: ChillGoColors.inkMuted),
        hintStyle: const TextStyle(color: ChillGoColors.inkMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ChillGoColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ChillGoColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ChillGoColors.coral, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ChillGoColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ChillGoColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ChillGoColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ChillGoColors.coral,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ChillGoColors.sunshineSoft,
        selectedColor: ChillGoColors.coralSoft,
        side: const BorderSide(color: ChillGoColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(
          color: ChillGoColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerColor: ChillGoColors.outline,
    );
  }
}
