// SPDX-License-Identifier: GPL-3.0-or-later
//
// Resolves the keyboard theme to paint: preset (ThemeSpec) + appearance
// settings + system colours -> KeyboardThemeData. Synchronous and cached.
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

import '../bridge/messages.g.dart';
import '../design/design.dart';
import '../settings/sections/appearance_settings.dart';
import 'custom/custom_theme_store.dart';
import 'glass_themes.dart';
import 'keyboard_theme_data.dart';
import 'presets.dart';
import 'scheme_builder.dart';
import 'theme_spec.dart';

/// Resolves the keyboard theme to paint.
///
/// [systemColors] is null on Android < 12 (no Material You palette).
/// [systemDark] is the system night mode.
/// [disableAnimations] reflects the system "Remove animations" setting.
///
/// An unknown `appearance.themeId` falls back to BooBoard Dynamic. Results are
/// cached on the inputs, so calling this on every build is cheap.
///
/// [customThemesDirectory] is where custom themes are stored (`<dataDirectory>/themes`). A
/// `custom:<uuid>` id is read from there; a missing or broken theme falls back to BooBoard Dynamic.
/// Null (tests, or no data directory) means custom ids cannot be resolved.
KeyboardThemeData resolveKeyboardTheme({
  required AppearanceSettings appearance,
  required SystemColorsMessage? systemColors,
  required bool systemDark,
  required bool disableAnimations,
  String? customThemesDirectory,
}) {
  final spec = specForId(appearance.themeId, customThemesDirectory);
  final dark = _isDark(appearance.darkMode, systemDark);
  return _cache.resolve(
    _ThemeKey(
      spec: spec,
      revision: appearance.customThemeRevision,
      dark: dark,
      pureBlack: appearance.pureBlack,
      contrast: appearance.contrast,
      palettes: spec.colorSource == ThemeColorSource.dynamic ? systemColors?.palettes : null,
      disableAnimations: disableAnimations,
    ),
    () => resolveKeyboardThemeFromSpec(
      withAbsoluteImage(spec, customThemesDirectory),
      dark: dark,
      pureBlack: appearance.pureBlack,
      contrast: appearance.contrast,
      palettes: systemColors?.palettes,
      disableAnimations: disableAnimations,
    ),
  );
}

/// The spec for a theme id: a preset, or a custom theme read from [customThemesDirectory].
/// Unknown presets, and custom themes that are missing or broken, give the default preset (Dark Glass).
ThemeSpec specForId(String themeId, String? customThemesDirectory) {
  if (CustomThemeIds.isCustom(themeId)) {
    final dir = customThemesDirectory;
    final spec = dir == null ? null : CustomThemeStore.readSpecSync(dir, themeId);
    return spec ?? ThemePresets.defaultPreset;
  }
  return ThemePresets.byId(themeId);
}

/// [spec] with its background image turned into an absolute path (the keyboard paints it with
/// `Image.file`). A photo that is missing, or whose path is not `images/<uuid>.png`, becomes a
/// solid background, so a bad file never breaks the keyboard.
ThemeSpec withAbsoluteImage(ThemeSpec spec, String? themesDirectory) {
  final bg = spec.background;
  if (bg.type != ThemeBackgroundType.image) return spec;
  final rel = bg.imagePath;
  final dir = themesDirectory;
  if (dir == null || rel == null || !CustomThemeStore.imageRelativePattern.hasMatch(rel)) {
    return spec.copyWith(background: const ThemeBackgroundSpec());
  }
  final absolute = '$dir${Platform.pathSeparator}${rel.replaceAll('/', Platform.pathSeparator)}';
  if (!File(absolute).existsSync()) {
    return spec.copyWith(background: const ThemeBackgroundSpec());
  }
  return spec.copyWith(background: bg.copyWith(imagePath: absolute));
}

bool _isDark(DarkModePreference pref, bool systemDark) =>
    pref == DarkModePreference.dark || (pref == DarkModePreference.system && systemDark);

/// Uncached resolution of any [ThemeSpec] (presets or a custom theme).
KeyboardThemeData resolveKeyboardThemeFromSpec(
  ThemeSpec spec, {
  required bool dark,
  bool pureBlack = false,
  ContrastPreference contrast = ContrastPreference.standard,
  List<int>? palettes,
  bool disableAnimations = false,
}) {
  // The glass keyboards are hand-made: the same in light and dark mode, without Material You colours.
  final glass = glassThemeFor(
    spec.id,
    motion: _motion(spec.motionIntensity, disableAnimations),
    highContrast: contrast == ContrastPreference.high,
  );
  if (glass != null) return glass;
  final level = switch (contrast) {
    ContrastPreference.standard => 0.0,
    ContrastPreference.medium => 0.5,
    ContrastPreference.high => 1.0,
  };
  final scheme = buildColorScheme(
    spec,
    dark ? Brightness.dark : Brightness.light,
    palettes: palettes,
    contrastLevel: level,
    pureBlack: pureBlack,
  );
  return themeFromScheme(
    spec,
    scheme,
    pureBlack: pureBlack && dark,
    minContrast: contrast == ContrastPreference.high ? highContrastRatio : standardContrastRatio,
    disableAnimations: disableAnimations,
  );
}

/// WCAG AA for normal text and AAA for the high-contrast setting.
const double standardContrastRatio = 4.5;
const double highContrastRatio = 7.0;

/// Minimum for non-text marks such as the swipe trail (WCAG 1.4.11).
const double _graphicContrastRatio = 3.0;

/// State-layer opacity blended over a key while pressed.
const double _stateLayerAlpha = 0.14;

/// Maps [scheme] and [spec] to the values the keyboard paints with. Every
/// label/fill pair is adjusted to reach [minContrast].
KeyboardThemeData themeFromScheme(
  ThemeSpec spec,
  ColorScheme scheme, {
  required bool pureBlack,
  required double minContrast,
  required bool disableAnimations,
}) {
  final s = scheme;
  // Colours that sit directly on the keyboard background. With a gradient or
  // an image they must read against every stop, so we adjust against each.
  final backdrops = _backdrops(spec, s);
  Color onBackdrop(Color c, [double ratio = 0]) {
    var out = c;
    for (final b in backdrops) {
      out = ensureContrast(out, b, ratio == 0 ? minContrast : ratio);
    }
    return out;
  }

  // Text/icon colours on an opaque fill, valid at rest and while pressed.
  KeyStyle key(Color fill, Color label, Color hint) {
    final fit = fitLabelsToFill(fill, [label, hint], minContrast, stateLayerAlpha: _stateLayerAlpha);
    return KeyStyle(
      fill: fit.fill,
      pressedFill: blend(fit.labels[0].withValues(alpha: _stateLayerAlpha), fit.fill),
      label: fit.labels[0],
      hint: fit.labels[1],
      border: spec.borderWidth > 0 ? s.outline : null,
    );
  }

  (Color, Color) pair(Color fill, Color label) {
    final fit = fitLabelsToFill(fill, [label], minContrast);
    return (fit.fill, fit.labels[0]);
  }

  final spaceFill = blend(s.tertiaryContainer.withValues(alpha: pureBlack ? 0.22 : 0.4), s.surfaceContainerHighest);

  Color accent(int? override, Color fallback) => override == null ? fallback : Color(override | 0xFF000000);
  final popupFill = accent(spec.accents.popupFill, s.primaryContainer);
  final popupSelFill = accent(spec.accents.popupSelectedFill, s.primary);

  final popup = pair(popupFill, accent(spec.accents.popupLabel, s.onPrimaryContainer));
  final popupSel = pair(popupSelFill, accent(spec.accents.popupSelectedLabel, s.onPrimary));
  final highlight = pair(s.secondaryContainer, s.onSecondaryContainer);

  return KeyboardThemeData(
    id: spec.id,
    brightness: s.brightness,
    background: s.surfaceContainer,
    backgroundGradient: _gradient(spec, s),
    backgroundImagePath: spec.background.type == ThemeBackgroundType.image ? spec.background.imagePath : null,
    backgroundImageDim: spec.background.type == ThemeBackgroundType.image ? spec.background.dim : 0,
    letterKey: key(s.surfaceContainerHighest, s.onSurface, s.onSurfaceVariant),
    functionKey: key(s.secondaryContainer, s.onSecondaryContainer, s.onSecondaryContainer),
    actionKey: key(s.primary, s.onPrimary, s.onPrimary),
    spaceKey: key(spaceFill, s.onSurfaceVariant, s.onSurfaceVariant),
    popupFill: popup.$1,
    popupLabel: popup.$2,
    popupSelectedFill: popupSel.$1,
    popupSelectedLabel: popupSel.$2,
    suggestionText: onBackdrop(s.onSurface),
    suggestionHighlightFill: highlight.$1,
    suggestionHighlightText: highlight.$2,
    suggestionDivider: s.outlineVariant,
    toolbarIcon: onBackdrop(s.onSurfaceVariant),
    trailStart: onBackdrop(accent(spec.accents.trailStart, s.primary), _graphicContrastRatio),
    trailEnd: onBackdrop(accent(spec.accents.trailEnd, s.tertiary), _graphicContrastRatio),
    keyCornerRadius: spec.keyRadius.clamp(0.0, 0.5),
    keyGap: spec.keyGap,
    borderWidth: spec.borderWidth,
    fontFamily: spec.fontFamily,
    labelWeight: _nearestWeight(spec.labelWeight),
    labelFontVariations: spec.fontFamily == _variableFamily
        ? BooBoardType.variations(
            weight: spec.labelWeight.toDouble(),
            roundness: spec.fontRoundness ?? spec.keyRadius.clamp(0.0, 0.5) * 200,
          )
        : const [],
    labelScale: spec.labelScale,
    showHints: spec.showHints,
    motion: _motion(spec.motionIntensity, disableAnimations),
  );
}

/// The only bundled family with `wght`/`ROND` axes.
const String _variableFamily = 'GoogleSansFlex';

FontWeight _nearestWeight(int w) {
  final i = ((w.clamp(100, 900)) / 100).round() - 1;
  return FontWeight.values[i.clamp(0, 8)];
}

MotionSpec _motion(double intensity, bool disableAnimations) {
  final k = intensity.clamp(0.0, 2.0);
  return MotionSpec(
    enabled: !disableAnimations && k > 0,
    // Deeper press with higher intensity: 0.92 at 1.0.
    pressScale: (1 - (1 - BooBoardMotion.pressScale) * k).clamp(0.8, 1.0),
    stiffness: BooBoardMotion.fastSpatial.scaled(math.max(0.5, k)).stiffness,
    dampingRatio: BooBoardMotion.fastSpatial.dampingRatio,
  );
}

List<Color> _backdrops(ThemeSpec spec, ColorScheme s) {
  switch (spec.background.type) {
    case ThemeBackgroundType.solid:
      return [s.surfaceContainer];
    case ThemeBackgroundType.gradient:
      return _gradientColors(spec, s);
    case ThemeBackgroundType.image:
      // The image is dimmed toward black by `dim`; judge against that.
      return [Color.lerp(s.surfaceContainer, const Color(0xFF000000), spec.background.dim)!];
  }
}

List<Color> _gradientColors(ThemeSpec spec, ColorScheme s) {
  final c = spec.background.gradientColors;
  if (c.length >= 2) return [for (final v in c) Color(v | 0xFF000000)];
  return [s.surfaceContainerHigh, s.surfaceContainerLow];
}

Gradient? _gradient(ThemeSpec spec, ColorScheme s) {
  if (spec.background.type != ThemeBackgroundType.gradient) return null;
  final a = spec.background.gradientAngle * math.pi / 180;
  final dx = math.cos(a);
  final dy = math.sin(a);
  return LinearGradient(begin: Alignment(-dx, -dy), end: Alignment(dx, dy), colors: _gradientColors(spec, s));
}

// ---------------------------------------------------------------------------
// Cache: a handful of recent resolutions (the settings UI previews presets, and
// the keyboard re-resolves on every system-colour or night-mode change).
// ---------------------------------------------------------------------------

class _ThemeKey {
  _ThemeKey({
    required this.spec,
    required this.revision,
    required this.dark,
    required this.pureBlack,
    required this.contrast,
    required this.palettes,
    required this.disableAnimations,
  }) : _hash = Object.hash(
         spec,
         revision,
         dark,
         pureBlack,
         contrast,
         disableAnimations,
         palettes == null ? 0 : Object.hashAll(palettes),
       );

  /// The whole spec, not just its id: a custom theme edited in place must not hit a stale entry.
  final ThemeSpec spec;
  final int revision;
  final bool dark;
  final bool pureBlack;
  final ContrastPreference contrast;
  final List<int>? palettes;
  final bool disableAnimations;
  final int _hash;

  @override
  bool operator ==(Object other) =>
      other is _ThemeKey &&
      other._hash == _hash &&
      other.spec == spec &&
      other.revision == revision &&
      other.dark == dark &&
      other.pureBlack == pureBlack &&
      other.contrast == contrast &&
      other.disableAnimations == disableAnimations &&
      listEquals(other.palettes, palettes);

  @override
  int get hashCode => _hash;
}

class _ThemeCache {
  static const int _capacity = 12;
  final LinkedHashMap<_ThemeKey, KeyboardThemeData> _map = LinkedHashMap();

  KeyboardThemeData resolve(_ThemeKey key, KeyboardThemeData Function() compute) {
    final hit = _map.remove(key);
    if (hit != null) {
      _map[key] = hit; // most recently used last
      return hit;
    }
    final value = compute();
    _map[key] = value;
    if (_map.length > _capacity) _map.remove(_map.keys.first);
    return value;
  }
}

final _ThemeCache _cache = _ThemeCache();

/// Number of cached resolutions (for tests).
int get themeCacheSizeForTest => _cache._map.length;
