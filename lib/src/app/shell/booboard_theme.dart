// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A. Themes for the settings app: the BooBoard brand scheme, Material You
// colours from the wallpaper when the platform gives them, and the contrast preference.
import 'package:material_ui/material_ui.dart';

import '../../settings/booboard_settings.dart';
import '../../theme/material_you.dart';

/// Contrast preference as the level `ColorScheme.fromSeed` and [materialYouScheme] expect.
double contrastLevelOf(ContrastPreference contrast) => switch (contrast) {
  ContrastPreference.standard => 0,
  ContrastPreference.medium => 0.5,
  ContrastPreference.high => 1.0,
};

/// BooBoard's colours (lime look, 2026-11-26): ink and lime on warm paper in light mode, the same lime on
/// near-black in dark mode. Lime is an accent (selected chips, switch thumbs, icon circles), never the main
/// button colour: buttons are ink in light mode.
ColorScheme booboardBrandScheme(Brightness brightness, {double contrastLevel = 0}) {
  const lime = Color(0xFFE3F794);
  const ink = Color(0xFF161015);
  final light = brightness == Brightness.light;
  final base = ColorScheme.fromSeed(seedColor: lime, brightness: brightness, contrastLevel: contrastLevel);
  if (light) {
    return base.copyWith(
      primary: ink,
      onPrimary: Colors.white,
      primaryContainer: lime,
      onPrimaryContainer: ink,
      secondary: const Color(0xFF5A544E),
      onSecondary: Colors.white,
      secondaryContainer: lime,
      onSecondaryContainer: ink,
      tertiary: const Color(0xFF4E5E12),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFEEFBB6),
      onTertiaryContainer: ink,
      surface: const Color(0xFFF6F5EE),
      onSurface: ink,
      onSurfaceVariant: const Color(0xFF5A544E),
      surfaceDim: const Color(0xFFE2E0D7),
      surfaceBright: Colors.white,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFFBFAF5),
      surfaceContainer: Colors.white,
      surfaceContainerHigh: const Color(0xFFF0EEE6),
      surfaceContainerHighest: const Color(0xFFE9E7DE),
      outline: const Color(0xFF8D858A),
      outlineVariant: const Color(0xFFDCD9CF),
      inverseSurface: ink,
      onInverseSurface: const Color(0xFFF3F1EC),
      inversePrimary: lime,
    );
  }
  return base.copyWith(
    primary: lime,
    onPrimary: ink,
    primaryContainer: const Color(0xFF3A4210),
    onPrimaryContainer: lime,
    secondary: const Color(0xFFB8B2AC),
    onSecondary: ink,
    secondaryContainer: lime,
    onSecondaryContainer: ink,
    tertiary: const Color(0xFFC9DE76),
    onTertiary: ink,
    tertiaryContainer: const Color(0xFF3A4210),
    onTertiaryContainer: lime,
    surface: const Color(0xFF121012),
    onSurface: const Color(0xFFF3F1EC),
    onSurfaceVariant: const Color(0xFFB8B2AC),
    surfaceDim: const Color(0xFF0E0B0D),
    surfaceBright: const Color(0xFF3A3338),
    surfaceContainerLowest: const Color(0xFF0E0B0D),
    surfaceContainerLow: const Color(0xFF1B171A),
    surfaceContainer: const Color(0xFF262123),
    surfaceContainerHigh: const Color(0xFF2F2A2C),
    surfaceContainerHighest: const Color(0xFF3A3338),
    outline: const Color(0xFF8D858A),
    outlineVariant: const Color(0xFF3A3338),
    inverseSurface: const Color(0xFFF3F1EC),
    onInverseSurface: ink,
    inversePrimary: ink,
  );
}

/// The app always uses the BooBoard colours (2026-11-26). [palettes] (wallpaper colours) are no longer
/// used for the app; the keyboard's own themes decide its look.
ColorScheme booboardSchemeFor(Brightness brightness, {List<int>? palettes, double contrastLevel = 0}) =>
    booboardBrandScheme(brightness, contrastLevel: contrastLevel);

ThemeData booboardThemeData(ColorScheme scheme) {
  const lime = Color(0xFFE3F794);
  final light = scheme.brightness == Brightness.light;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'GoogleSansFlex',
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(backgroundColor: scheme.surface, foregroundColor: scheme.onSurface),
    // Switches: an ink track with a lime thumb when on (a lime track with an ink thumb in dark mode).
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? (light ? lime : scheme.onPrimary) : null,
      ),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? scheme.primary : null),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.outline,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: const StadiumBorder())),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
