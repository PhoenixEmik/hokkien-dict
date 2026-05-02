import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _fontFamilyFallback = <String>['TauhuOo'];
const _brandSeedColor = Color(0xFF1A365D);
const _amoledSeedColor = Color(0xFFA9D8FF);

ThemeData buildLightAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _brandSeedColor,
    brightness: Brightness.light,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    contrastLevel: 0.5,
  );
  final baseTheme = _buildMaterialTheme(colorScheme: colorScheme);

  return _applySharedComponentThemes(baseTheme, colorScheme).copyWith(
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    appBarTheme: baseTheme.appBarTheme.copyWith(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      systemOverlayStyle: buildSystemUiOverlayStyle(colorScheme),
    ),
    cardTheme: baseTheme.cardTheme.copyWith(
      color: colorScheme.surfaceContainerLow,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1.1),
      ),
    ),
    dialogTheme: baseTheme.dialogTheme.copyWith(
      backgroundColor: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: baseTheme.snackBarTheme.copyWith(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: baseTheme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: colorScheme.inversePrimary,
      disabledActionTextColor: colorScheme.onSurfaceVariant,
      closeIconColor: colorScheme.onInverseSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outlineVariant, width: 1.1),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    dropdownMenuTheme: baseTheme.dropdownMenuTheme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerLowest,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(
          BorderSide(color: colorScheme.outlineVariant, width: 1.1),
        ),
      ),
    ),
    floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
    ),
  );
}

ThemeData buildDarkAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _brandSeedColor,
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    contrastLevel: 0.5,
  );

  final baseTheme = _buildMaterialTheme(colorScheme: colorScheme);

  return _applySharedComponentThemes(baseTheme, colorScheme).copyWith(
    appBarTheme: ThemeData(brightness: Brightness.dark).appBarTheme.copyWith(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: buildSystemUiOverlayStyle(colorScheme),
    ),
  );
}

ThemeData buildAmoledAppTheme() {
  const black = Color(0xFF000000);
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: _amoledSeedColor,
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        contrastLevel: 0.5,
      ).copyWith(
        surface: black,
        surfaceContainerLowest: black,
        surfaceContainerLow: black,
        surfaceContainer: black,
        surfaceContainerHigh: black,
        surfaceContainerHighest: black,
      );

  final baseTheme = _buildMaterialTheme(colorScheme: colorScheme);

  return _applySharedComponentThemes(baseTheme, colorScheme).copyWith(
    scaffoldBackgroundColor: black,
    canvasColor: black,
    appBarTheme: ThemeData(brightness: Brightness.dark).appBarTheme.copyWith(
      backgroundColor: black,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: buildSystemUiOverlayStyle(colorScheme),
    ),
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

ThemeData _applySharedComponentThemes(
  ThemeData baseTheme,
  ColorScheme colorScheme,
) {
  return baseTheme.copyWith(
    chipTheme: baseTheme.chipTheme.copyWith(
      backgroundColor: colorScheme.surfaceContainerHigh,
      selectedColor: colorScheme.secondaryContainer,
      secondarySelectedColor: colorScheme.secondaryContainer,
      side: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: baseTheme.textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: baseTheme.textTheme.labelLarge?.copyWith(
        color: colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.secondaryContainer,
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(
        colorScheme.surfaceContainerLowest,
      ),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStatePropertyAll(
        BorderSide(color: colorScheme.outlineVariant, width: 1.1),
      ),
    ),
  );
}

SystemUiOverlayStyle buildSystemUiOverlayStyle(ColorScheme colorScheme) {
  final useDarkIcons = colorScheme.brightness == Brightness.light;
  final baseStyle = useDarkIcons
      ? SystemUiOverlayStyle.dark
      : SystemUiOverlayStyle.light;
  final navigationBarColor = useDarkIcons
      ? colorScheme.surfaceContainerHigh
      : colorScheme.surface;
  final navigationBarDividerColor = useDarkIcons
      ? colorScheme.outlineVariant
      : colorScheme.surfaceContainerHighest;

  return baseStyle.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: navigationBarColor,
    systemNavigationBarDividerColor: navigationBarDividerColor,
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
