// SPDX-License-Identifier: GPL-3.0-or-later
//
// Helpers shared by the theme gallery and the theme editor: where custom themes live, a cache of
// resolved previews, and the colour roles the editor exposes.
import 'dart:collection';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

import '../../settings/sections/appearance_settings.dart';
import '../../theme/custom/custom_theme_store.dart';
import '../../theme/keyboard_theme_data.dart';
import '../../theme/theme_resolver.dart';
import '../../theme/theme_spec.dart';

import 'package:booboard/src/app/l10n.dart';

/// Longest theme name, in characters.
const int kThemeNameMax = 30;

/// `<dataDirectory>/themes`, the same string the keyboard passes to `resolveKeyboardTheme`.
String themesDirectoryFor(String dataDirectory) => '$dataDirectory/themes';

/// Seed colours offered in the editor: the brand colours and a spread of hues.
const List<int> kSeedSwatches = [
  0xFFF5B700, // BooBoard yellow
  0xFF3E2723, // BooBoard brown
  0xFF8F6FD8, // lavender
  0xFF0B79C4, // ocean
  0xFF2FA67F, // mint
  0xFFFF6F61, // coral
  0xFFD6336C, // rose
  0xFF616161, // graphite
];

/// Colour role names, in the order the editor lists them (see [themeRoleNames]).
const List<String> kEditorRoles = themeRoleNames;

/// The effective colour of [role] in [s], or null for an unknown name.
Color? roleColor(ColorScheme s, String role) => switch (role) {
  'primary' => s.primary,
  'onPrimary' => s.onPrimary,
  'primaryContainer' => s.primaryContainer,
  'onPrimaryContainer' => s.onPrimaryContainer,
  'secondary' => s.secondary,
  'onSecondary' => s.onSecondary,
  'secondaryContainer' => s.secondaryContainer,
  'onSecondaryContainer' => s.onSecondaryContainer,
  'tertiary' => s.tertiary,
  'onTertiary' => s.onTertiary,
  'tertiaryContainer' => s.tertiaryContainer,
  'onTertiaryContainer' => s.onTertiaryContainer,
  'error' => s.error,
  'onError' => s.onError,
  'surface' => s.surface,
  'onSurface' => s.onSurface,
  'onSurfaceVariant' => s.onSurfaceVariant,
  'surfaceDim' => s.surfaceDim,
  'surfaceBright' => s.surfaceBright,
  'surfaceContainerLowest' => s.surfaceContainerLowest,
  'surfaceContainerLow' => s.surfaceContainerLow,
  'surfaceContainer' => s.surfaceContainer,
  'surfaceContainerHigh' => s.surfaceContainerHigh,
  'surfaceContainerHighest' => s.surfaceContainerHighest,
  'outline' => s.outline,
  'outlineVariant' => s.outlineVariant,
  _ => null,
};

/// Resolves theme specs for previews, with a small LRU so scrolling a carousel does not resolve
/// the same eight presets again and again. Results are the same objects as the keyboard would paint.
class ThemePreviewCache {
  static const int _capacity = 40;

  final LinkedHashMap<_PreviewKey, KeyboardThemeData> _map = LinkedHashMap();

  KeyboardThemeData resolve(
    ThemeSpec spec, {
    required String? themesDirectory,
    required bool dark,
    required bool pureBlack,
    required ContrastPreference contrast,
    required List<int>? palettes,
    required bool disableAnimations,
  }) {
    final key = _PreviewKey(spec, dark, pureBlack, contrast, disableAnimations, palettes, themesDirectory);
    final hit = _map.remove(key);
    if (hit != null) {
      _map[key] = hit;
      return hit;
    }
    final value = resolveKeyboardThemeFromSpec(
      withAbsoluteImage(spec, themesDirectory),
      dark: dark,
      pureBlack: pureBlack,
      contrast: contrast,
      palettes: spec.colorSource == ThemeColorSource.dynamic ? palettes : null,
      disableAnimations: disableAnimations,
    );
    _map[key] = value;
    if (_map.length > _capacity) _map.remove(_map.keys.first);
    return value;
  }

  void clear() => _map.clear();
}

class _PreviewKey {
  _PreviewKey(this.spec, this.dark, this.pureBlack, this.contrast, this.disableAnimations, this.palettes, this.dir)
    : _hash = Object.hash(
        spec,
        dark,
        pureBlack,
        contrast,
        disableAnimations,
        dir,
        palettes == null ? 0 : Object.hashAll(palettes),
      );

  final ThemeSpec spec;
  final bool dark;
  final bool pureBlack;
  final ContrastPreference contrast;
  final bool disableAnimations;
  final List<int>? palettes;
  final String? dir;
  final int _hash;

  @override
  bool operator ==(Object other) =>
      other is _PreviewKey &&
      other._hash == _hash &&
      other.spec == spec &&
      other.dark == dark &&
      other.pureBlack == pureBlack &&
      other.contrast == contrast &&
      other.disableAnimations == disableAnimations &&
      other.dir == dir &&
      listEquals(other.palettes, palettes);

  @override
  int get hashCode => _hash;
}

/// A fresh custom theme id, for a theme that has not been saved yet.
String newCustomThemeId() => CustomThemeIds.idFor(CustomThemeIds.newUuid());

/// The name to use for a copy of [name], within [kThemeNameMax] characters.
String copyNameFor(String name, AppLocalizations l10n) {
  final suffix = l10n.themeCopySuffix;
  final base = name.length + suffix.length > kThemeNameMax ? name.substring(0, kThemeNameMax - suffix.length) : name;
  return l10n.themeCopyName(base);
}
