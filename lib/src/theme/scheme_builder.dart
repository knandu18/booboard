// SPDX-License-Identifier: GPL-3.0-or-later
//
// ThemeSpec + brightness + contrast + system palettes -> ColorScheme.
import 'package:material_ui/material_ui.dart';

import 'material_you.dart';
import 'theme_spec.dart';

DynamicSchemeVariant _variant(ThemeSchemeVariant v) => switch (v) {
  ThemeSchemeVariant.tonalSpot => DynamicSchemeVariant.tonalSpot,
  ThemeSchemeVariant.vibrant => DynamicSchemeVariant.vibrant,
  ThemeSchemeVariant.expressive => DynamicSchemeVariant.expressive,
  ThemeSchemeVariant.fidelity => DynamicSchemeVariant.fidelity,
  ThemeSchemeVariant.content => DynamicSchemeVariant.content,
  ThemeSchemeVariant.monochrome => DynamicSchemeVariant.monochrome,
  ThemeSchemeVariant.neutral => DynamicSchemeVariant.neutral,
  ThemeSchemeVariant.rainbow => DynamicSchemeVariant.rainbow,
  ThemeSchemeVariant.fruitSalad => DynamicSchemeVariant.fruitSalad,
};

/// The colour scheme for [spec].
///
/// [palettes] are the Android 12+ system palettes (5 x 13 ARGB ints) or null.
/// They are used only for [ThemeColorSource.dynamic]; if missing or invalid the
/// spec's seed colour is used instead. [contrastLevel] is 0, 0.5 or 1.0.
ColorScheme buildColorScheme(
  ThemeSpec spec,
  Brightness brightness, {
  List<int>? palettes,
  double contrastLevel = 0,
  bool pureBlack = false,
}) {
  ColorScheme? scheme;
  if (spec.colorSource == ThemeColorSource.dynamic && palettes != null) {
    scheme = materialYouScheme(palettes, brightness, contrastLevel: contrastLevel);
  }
  scheme ??= ColorScheme.fromSeed(
    seedColor: Color(spec.seedColor),
    brightness: brightness,
    dynamicSchemeVariant: _variant(spec.variant),
    contrastLevel: contrastLevel,
  );
  if (spec.colorSource == ThemeColorSource.custom) {
    final roles = brightness == Brightness.dark ? (spec.customRolesDark ?? spec.customRoles) : spec.customRoles;
    scheme = applyRoleOverrides(scheme, roles);
  }
  if (pureBlack && brightness == Brightness.dark) scheme = applyPureBlack(scheme);
  return scheme;
}

/// Replaces the roles named in [roles] (see [themeRoleNames]).
ColorScheme applyRoleOverrides(ColorScheme s, Map<String, int> roles) {
  if (roles.isEmpty) return s;
  Color? c(String name) {
    final v = roles[name];
    return v == null ? null : Color(v | 0xFF000000);
  }

  return s.copyWith(
    primary: c('primary'),
    onPrimary: c('onPrimary'),
    primaryContainer: c('primaryContainer'),
    onPrimaryContainer: c('onPrimaryContainer'),
    secondary: c('secondary'),
    onSecondary: c('onSecondary'),
    secondaryContainer: c('secondaryContainer'),
    onSecondaryContainer: c('onSecondaryContainer'),
    tertiary: c('tertiary'),
    onTertiary: c('onTertiary'),
    tertiaryContainer: c('tertiaryContainer'),
    onTertiaryContainer: c('onTertiaryContainer'),
    error: c('error'),
    onError: c('onError'),
    surface: c('surface'),
    onSurface: c('onSurface'),
    onSurfaceVariant: c('onSurfaceVariant'),
    surfaceDim: c('surfaceDim'),
    surfaceBright: c('surfaceBright'),
    surfaceContainerLowest: c('surfaceContainerLowest'),
    surfaceContainerLow: c('surfaceContainerLow'),
    surfaceContainer: c('surfaceContainer'),
    surfaceContainerHigh: c('surfaceContainerHigh'),
    surfaceContainerHighest: c('surfaceContainerHighest'),
    outline: c('outline'),
    outlineVariant: c('outlineVariant'),
  );
}

const Color _black = Color(0xFF000000);

/// True-black background with near-black keys: the surface ladder is pulled
/// toward black (keeping a hint of the scheme's tint), and the tonal function
/// key fill is darkened to match.
ColorScheme applyPureBlack(ColorScheme s) {
  Color toward(Color c, double keep) => Color.lerp(_black, c, keep)!;
  return s.copyWith(
    surface: _black,
    surfaceDim: _black,
    surfaceContainerLowest: _black,
    surfaceContainer: _black,
    surfaceContainerLow: toward(s.surfaceContainerLow, 0.5),
    surfaceContainerHigh: toward(s.surfaceContainerHigh, 0.6),
    surfaceContainerHighest: toward(s.surfaceContainerHighest, 0.6),
    surfaceBright: toward(s.surfaceBright, 0.6),
    secondaryContainer: toward(s.secondaryContainer, 0.6),
  );
}
