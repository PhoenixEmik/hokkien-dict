import 'package:flutter/material.dart';

const _fontFamilyFallback = <String>['TauhuOo'];
const _brandSeedColor = Color(0xFF17454C);
const _amoledSeedColor = Color(0xFFA9D8FF);

ThemeData buildLightAppTheme() {
  return _buildMaterialTheme(
    brightness: Brightness.light,
    seedColor: _brandSeedColor,
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
