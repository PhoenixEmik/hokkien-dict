import 'package:flutter/material.dart';

const _fontFamilyFallback = <String>['TauhuOo'];
const _brandSeedColor = Color(0xFF26416B);
const _amoledSeedColor = Color(0xFFA9D8FF);
const _lightCanvasColor = Color(0xFFF2F5FA);
const _lightSurfaceTint = Color(0xFFE8EEF7);
const _lightNavigationBackground = Color(0xFFEEF3F9);
const _lightNavigationIndicator = Color(0xFFD6E1F0);
const _lightOutlineColor = Color(0xFFD2DBE8);
const _lightSecondaryColor = Color(0xFF3B5B88);
const _lightTertiaryColor = Color(0xFF5877A3);
const _lightInputFillColor = Color(0xFFFBFCFE);
const _lightChipColor = Color(0xFFE1EAF5);
const _lightChipSelectedColor = Color(0xFFC8D7EB);
const _lightPrimaryContainerColor = Color(0xFFD7E2F0);
const _lightSecondaryContainerColor = Color(0xFFDEE8F4);

ThemeData buildLightAppTheme() {
  final baseTheme = _buildMaterialTheme(
    brightness: Brightness.light,
    seedColor: _brandSeedColor,
  );

  final colorScheme = baseTheme.colorScheme.copyWith(
    primary: _brandSeedColor,
    onPrimary: Colors.white,
    primaryContainer: _lightPrimaryContainerColor,
    onPrimaryContainer: _brandSeedColor,
    secondary: _lightSecondaryColor,
    onSecondary: Colors.white,
    secondaryContainer: _lightSecondaryContainerColor,
    onSecondaryContainer: _brandSeedColor,
    tertiary: _lightTertiaryColor,
    onTertiary: Colors.white,
    surface: Colors.white,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF8FAFD),
    surfaceContainer: _lightSurfaceTint,
    surfaceContainerHigh: const Color(0xFFE0E8F4),
    surfaceContainerHighest: const Color(0xFFD6E1F0),
    outlineVariant: _lightOutlineColor,
  );

  return baseTheme.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _lightCanvasColor,
    canvasColor: _lightCanvasColor,
    appBarTheme: baseTheme.appBarTheme.copyWith(
      backgroundColor: _lightCanvasColor,
      foregroundColor: _brandSeedColor,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: _brandSeedColor),
      actionsIconTheme: const IconThemeData(color: _brandSeedColor),
    ),
    cardTheme: baseTheme.cardTheme.copyWith(
      color: Colors.white,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: baseTheme.dialogTheme.copyWith(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: baseTheme.snackBarTheme.copyWith(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _brandSeedColor,
      contentTextStyle: baseTheme.textTheme.bodyMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: const Color(0xFFDCE7F6),
      disabledActionTextColor: const Color(0xFFB9C8DE),
      closeIconColor: const Color(0xFFDCE7F6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _brandSeedColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _lightNavigationIndicator,
        disabledForegroundColor: _lightSecondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _brandSeedColor,
        side: const BorderSide(color: _lightOutlineColor),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: _lightInputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _lightOutlineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _lightOutlineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _brandSeedColor, width: 1.4),
      ),
    ),
    dropdownMenuTheme: baseTheme.dropdownMenuTheme.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: _lightInputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: _lightOutlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: _lightOutlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: _brandSeedColor, width: 1.4),
        ),
      ),
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide(color: _lightOutlineColor)),
      ),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      backgroundColor: _lightChipColor,
      selectedColor: _lightChipSelectedColor,
      secondarySelectedColor: _lightChipSelectedColor,
      side: const BorderSide(color: _lightOutlineColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: baseTheme.textTheme.labelLarge?.copyWith(
        color: _brandSeedColor,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: baseTheme.textTheme.labelLarge?.copyWith(
        color: _brandSeedColor,
        fontWeight: FontWeight.w700,
      ),
    ),
    floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
      backgroundColor: _brandSeedColor,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _lightNavigationBackground,
      surfaceTintColor: Colors.transparent,
      indicatorColor: _lightNavigationIndicator,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? _brandSeedColor : colorScheme.onSurfaceVariant,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return baseTheme.textTheme.labelMedium?.copyWith(
          color: selected ? _brandSeedColor : colorScheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: const WidgetStatePropertyAll(Colors.white),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      side: const WidgetStatePropertyAll(
        BorderSide(color: _lightOutlineColor),
      ),
    ),
  );
}

ThemeData buildDarkAppTheme() {
  return _buildMaterialTheme(
    brightness: Brightness.dark,
    seedColor: _brandSeedColor,
  );
}

ThemeData buildAmoledAppTheme() {
  const black = Color(0xFF000000);
  final baseTheme = _buildMaterialTheme(
    brightness: Brightness.dark,
    seedColor: _amoledSeedColor,
  );

  final colorScheme = baseTheme.colorScheme.copyWith(
    surface: black,
    surfaceContainerLowest: black,
    surfaceContainerLow: black,
    surfaceContainer: black,
    surfaceContainerHigh: black,
    surfaceContainerHighest: black,
  );

  return baseTheme.copyWith(
    scaffoldBackgroundColor: black,
    canvasColor: black,
    colorScheme: colorScheme,
    appBarTheme: baseTheme.appBarTheme.copyWith(
      backgroundColor: black,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: baseTheme.cardTheme.copyWith(
      color: black,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: baseTheme.dialogTheme.copyWith(
      backgroundColor: black,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

ThemeData _buildMaterialTheme({
  required Brightness brightness,
  required Color seedColor,
}) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ),
    fontFamilyFallback: _fontFamilyFallback,
  );
}
