import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const canvas = Color(0xFFF7F1E7);
  const deepInk = Color(0xFF0E2F35);
  const surface = Color(0xFFFFFFFF);
  const outline = Color(0xFFD7D0C4);
  const mutedText = Color(0xFF5F6C70);

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: deepInk,
      brightness: Brightness.light,
      surface: surface,
      surfaceContainerLowest: surface,
      surfaceContainerLow: const Color(0xFFFFFBF5),
      outlineVariant: outline,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: deepInk,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: surface,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: outline),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(3),
      backgroundColor: const WidgetStatePropertyAll(surface),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.10)),
      side: const WidgetStatePropertyAll(BorderSide(color: outline)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(color: deepInk, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      hintStyle: const WidgetStatePropertyAll(
        TextStyle(color: mutedText, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: deepInk.withValues(alpha: 0.07),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}
