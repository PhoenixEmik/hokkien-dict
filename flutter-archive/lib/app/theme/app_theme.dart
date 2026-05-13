import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _fontFamilyFallback = <String>['TauhuOo'];
const _brandSeedColor = Color(0xFF1A365D);
const _amoledSeedColor = Color(0xFFA9D8FF);

ThemeData buildLightAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _brandSeedColor,
    brightness: Brightness.light,
  );
  return _buildMaterialTheme(colorScheme: colorScheme);
}

ThemeData buildDarkAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _brandSeedColor,
    brightness: Brightness.dark,
  );
  return _buildMaterialTheme(colorScheme: colorScheme);
}

ThemeData buildAmoledAppTheme() {
  const black = Color(0xFF000000);
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: _amoledSeedColor,
        brightness: Brightness.dark,
      ).copyWith(
        surface: black,
        surfaceContainerLowest: black,
        surfaceContainerLow: black,
        surfaceContainer: black,
        surfaceContainerHigh: black,
        surfaceContainerHighest: black,
      );

  return _buildMaterialTheme(colorScheme: colorScheme).copyWith(
    scaffoldBackgroundColor: black,
    canvasColor: black,
    cardTheme: ThemeData(brightness: Brightness.dark).cardTheme.copyWith(
      color: black,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: ThemeData(brightness: Brightness.dark).dialogTheme.copyWith(
      backgroundColor: black,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

SystemUiOverlayStyle buildSystemUiOverlayStyle(ColorScheme colorScheme) {
  final useDarkIcons = colorScheme.brightness == Brightness.light;
  final baseStyle = useDarkIcons
      ? SystemUiOverlayStyle.dark
      : SystemUiOverlayStyle.light;

  return baseStyle.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: colorScheme.surface,
    systemNavigationBarDividerColor: colorScheme.outlineVariant,
    systemNavigationBarIconBrightness: useDarkIcons
        ? Brightness.dark
        : Brightness.light,
    statusBarIconBrightness: useDarkIcons ? Brightness.dark : Brightness.light,
    statusBarBrightness: useDarkIcons ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: true,
    systemStatusBarContrastEnforced: true,
  );
}

ThemeData _buildMaterialTheme({required ColorScheme colorScheme}) {
  return ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    fontFamilyFallback: _fontFamilyFallback,
  );
}
