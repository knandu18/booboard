// SPDX-License-Identifier: GPL-3.0-or-later
//
// Built-in themes, defined in Dart so resolution stays synchronous. Every
// preset has light, dark and pure-black variants and three contrast levels,
// all derived from the same spec (see theme_resolver.dart).
import 'glass_themes.dart';
import 'theme_spec.dart';

/// Brand gold (the colour of the first BooBoard icon, a treasure chest; the seed of the brand scheme) and brand dark brown
/// (the chest's straps and keycap, and the launcher background). See tool/brand/render.py.
const int booboardYellow = 0xFFEFB33A;
const int booboardBrown = 0xFF3E2723;

/// The theme new installs start with (decision 2026-11-26: Dark Glass, always dark; Lime Glass is the other
/// built-in choice; Oceanblue is no longer shown).
const String defaultThemeId = GlassThemeIds.dark;

abstract final class ThemePresets {
  /// Wallpaper colours on Android 12+, brand seed otherwise.
  static const ThemeSpec booboardDynamic = ThemeSpec(
    id: 'booboard_dynamic',
    name: 'BooBoard Dynamic',
    colorSource: ThemeColorSource.dynamic,
    seedColor: booboardYellow,
    variant: ThemeSchemeVariant.fidelity,
  );

  /// The brand look: warm yellow primary with dark-brown accents.
  static const ThemeSpec booboardGold = ThemeSpec(
    id: 'booboard_gold',
    name: 'BooBoard Gold',
    colorSource: ThemeColorSource.custom,
    seedColor: booboardYellow,
    variant: ThemeSchemeVariant.fidelity,
    customRoles: {
      'primary': booboardYellow,
      'onPrimary': booboardBrown,
      'primaryContainer': 0xFFFFE08C,
      'onPrimaryContainer': booboardBrown,
      'secondary': 0xFF8D6E63,
      'onSecondary': 0xFFFFFFFF,
      'secondaryContainer': 0xFFF1DFC4,
      'onSecondaryContainer': booboardBrown,
      'tertiary': 0xFF6D4C41,
      'onTertiary': 0xFFFFFFFF,
      'tertiaryContainer': 0xFFFFDBC8,
      'onTertiaryContainer': booboardBrown,
      'surface': 0xFFFFF8EA,
      'onSurface': 0xFF2A1F1B,
      'onSurfaceVariant': 0xFF5D4A42,
      'surfaceContainer': 0xFFFFF0CC,
      'surfaceContainerHigh': 0xFFFFF6E3,
      'surfaceContainerHighest': 0xFFFFFBF0,
      'outline': 0xFF8A7468,
      'outlineVariant': 0xFFE3D2B5,
    },
    customRolesDark: {
      'primary': booboardYellow,
      'onPrimary': booboardBrown,
      'primaryContainer': 0xFF5C4400,
      'onPrimaryContainer': 0xFFFFE08C,
      'secondary': 0xFFD7BFA8,
      'onSecondary': booboardBrown,
      'secondaryContainer': 0xFF4F4130,
      'onSecondaryContainer': 0xFFF1DFC4,
      'tertiary': 0xFFE0B9A4,
      'onTertiary': booboardBrown,
      'tertiaryContainer': 0xFF5D4037,
      'onTertiaryContainer': 0xFFFFDBC8,
      'surface': 0xFF1F1A12,
      'onSurface': 0xFFEDE1CF,
      'onSurfaceVariant': 0xFFD3C4B0,
      'surfaceContainer': 0xFF251F16,
      'surfaceContainerHigh': 0xFF30291D,
      'surfaceContainerHighest': 0xFF3B3326,
      'outline': 0xFF9C8E7C,
      'outlineVariant': 0xFF4D4435,
    },
  );

  static const ThemeSpec lavender = ThemeSpec(id: 'lavender', name: 'Lavender', seedColor: 0xFF8F6FD8);

  static const ThemeSpec ocean = ThemeSpec(id: 'ocean', name: 'Ocean', seedColor: 0xFF0B79C4);

  static const ThemeSpec mint = ThemeSpec(
    id: 'mint',
    name: 'Mint',
    seedColor: 0xFF2FA67F,
    variant: ThemeSchemeVariant.vibrant,
  );

  static const ThemeSpec coral = ThemeSpec(
    id: 'coral',
    name: 'Coral',
    seedColor: 0xFFFF6F61,
    variant: ThemeSchemeVariant.vibrant,
  );

  static const ThemeSpec rose = ThemeSpec(
    id: 'rose',
    name: 'Rose',
    seedColor: 0xFFD6336C,
    variant: ThemeSchemeVariant.expressive,
  );

  /// Monochrome; slightly squarer keys than the others.
  static const ThemeSpec graphite = ThemeSpec(
    id: 'graphite',
    name: 'Graphite',
    seedColor: 0xFF616161,
    variant: ThemeSchemeVariant.monochrome,
    keyRadius: 0.32,
  );

  /// Dark Glass: frosted keys on an ink board with soft lime glows, lime Enter. The default for new installs,
  /// always dark. The colours live in glass_themes.dart; these fields describe it for the editor and lists.
  static const ThemeSpec darkGlass = ThemeSpec(
    id: GlassThemeIds.dark,
    name: 'Dark Glass',
    colorSource: ThemeColorSource.custom,
    seedColor: 0xFFE3F794,
    keyRadius: 0.25,
    borderWidth: 1,
    keyGap: 6,
    labelScale: 0.9,
    showHints: false,
    background: ThemeBackgroundSpec(type: ThemeBackgroundType.gradient, gradientColors: [0xFF241E23, 0xFF161015]),
  );

  /// Lime Glass: frosted white keys on a lime board, ink Enter. Always light.
  static const ThemeSpec limeGlass = ThemeSpec(
    id: GlassThemeIds.lime,
    name: 'Lime Glass',
    colorSource: ThemeColorSource.custom,
    seedColor: 0xFFE3F794,
    keyRadius: 0.25,
    borderWidth: 1,
    keyGap: 6,
    labelScale: 0.9,
    showHints: false,
    background: ThemeBackgroundSpec(
      type: ThemeBackgroundType.gradient,
      gradientColors: [0xFFEEFBB6, 0xFFDDF487, 0xFFCBE86A],
    ),
  );

  /// The Oceanblue theme: a gradient background from lavender to aqua with slate-blue keys. The default from
  /// 2026-11-25 until the glass themes replaced it (no longer shown; a saved choice still resolves).
  /// Values read from the Oceanblue editor (2026-11-25).
  static const ThemeSpec oceanBlue = ThemeSpec(
    id: 'booboard_oceanblue',
    name: 'Oceanblue',
    colorSource: ThemeColorSource.seed,
    seedColor: 0xFF4D5D8B,
    variant: ThemeSchemeVariant.tonalSpot,
    keyRadius: 0.45,
    borderWidth: 2,
    keyGap: 4,
    labelWeight: 500,
    labelScale: 0.79,
    showHints: false,
    background: ThemeBackgroundSpec(
      type: ThemeBackgroundType.gradient,
      gradientColors: [0xFFE4C0FF, 0xFF8DF5F4],
      gradientAngle: 69,
    ),
    accents: ThemeAccentOverrides(trailStart: 0xFF4D5D8B, trailEnd: 0xFF6B567E),
    motionIntensity: 2,
  );

  /// Light Glass: frosted white keys on a soft paper board with a faint lime glow, lime Enter. Always light.
  static const ThemeSpec lightGlass = ThemeSpec(
    id: GlassThemeIds.light,
    name: 'Light Glass',
    colorSource: ThemeColorSource.custom,
    seedColor: 0xFFE3F794,
    keyRadius: 0.25,
    borderWidth: 1,
    keyGap: 6,
    labelScale: 0.9,
    showHints: false,
    background: ThemeBackgroundSpec(type: ThemeBackgroundType.gradient, gradientColors: [0xFFFAF9F5, 0xFFE9E6DE]),
  );

  /// Auto: Light Glass while the phone is in light mode, Dark Glass while it is in dark mode.
  static const ThemeSpec autoGlass = ThemeSpec(
    id: GlassThemeIds.auto,
    name: 'Auto (follows phone)',
    colorSource: ThemeColorSource.custom,
    seedColor: 0xFFE3F794,
    keyRadius: 0.25,
    borderWidth: 1,
    keyGap: 6,
    labelScale: 0.9,
    showHints: false,
    background: ThemeBackgroundSpec(type: ThemeBackgroundType.gradient, gradientColors: [0xFFFAF9F5, 0xFF161015]),
  );

  /// Shown in the app: the glass keyboards (Light Glass and Auto added 2026-11-27).
  static const List<ThemeSpec> all = [darkGlass, lightGlass, autoGlass, limeGlass];

  /// What new installs and unknown ids get.
  static const ThemeSpec defaultPreset = darkGlass;

  /// Older built-in themes. They are no longer shown, but a theme saved before the change still resolves to
  /// itself, so existing users keep the theme they had.
  static const List<ThemeSpec> legacy = [
    oceanBlue,
    booboardDynamic,
    booboardGold,
    lavender,
    ocean,
    mint,
    coral,
    rose,
    graphite,
  ];

  /// The preset with [id] (shown or legacy), or the default preset if unknown.
  static ThemeSpec byId(String id) {
    for (final p in [...all, ...legacy]) {
      if (p.id == id) return p;
    }
    return defaultPreset;
  }

  static bool isPresetId(String id) => [...all, ...legacy].any((p) => p.id == id);
}
