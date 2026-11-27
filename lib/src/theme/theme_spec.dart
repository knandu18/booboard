// SPDX-License-Identifier: GPL-3.0-or-later
//
// Editable, versioned theme description. Presets are defined in Dart
// (presets.dart) and custom themes are stored as JSON; both use this model.
// The JSON format is documented in assets/themes/README.txt.
import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:meta/meta.dart';

import '../settings/json_util.dart';

/// Where the colour scheme comes from.
enum ThemeColorSource {
  /// Material You palettes from the wallpaper (Android 12+). Falls back to the
  /// seed colour when the platform gives no palettes.
  dynamic,

  /// Generated from [ThemeSpec.seedColor] with [ThemeSpec.variant].
  seed,

  /// Generated from the seed, then individual roles replaced from
  /// [ThemeSpec.customRoles] / [ThemeSpec.customRolesDark].
  custom,
}

/// Mirrors `DynamicSchemeVariant`; kept separate so stored JSON never depends
/// on a framework enum.
enum ThemeSchemeVariant { tonalSpot, vibrant, expressive, fidelity, content, monochrome, neutral, rainbow, fruitSalad }

enum ThemeBackgroundType { solid, gradient, image }

@immutable
class ThemeBackgroundSpec {
  const ThemeBackgroundSpec({
    this.type = ThemeBackgroundType.solid,
    this.gradientColors = const [],
    this.gradientAngle = 90,
    this.imagePath,
    this.blur = 0,
    this.dim = 0.3,
  });

  factory ThemeBackgroundSpec.fromJson(Json j) => ThemeBackgroundSpec(
    type: jEnum(j, 'type', ThemeBackgroundType.values, ThemeBackgroundType.solid),
    gradientColors: _colorList(j['gradientColors']),
    gradientAngle: jDouble(j, 'gradientAngle', 90),
    imagePath: jStringOrNull(j, 'imagePath'),
    blur: jDouble(j, 'blur', 0).clamp(0.0, 50.0),
    dim: jDouble(j, 'dim', 0.3).clamp(0.0, 1.0),
  );

  final ThemeBackgroundType type;

  /// ARGB ints; two or more for a gradient. Empty = derive from the scheme.
  final List<int> gradientColors;

  /// Degrees, 0 = left to right, 90 = top to bottom.
  final double gradientAngle;

  /// The pre-rendered image, relative to the themes folder (`images/<uuid>.png`) in the stored
  /// JSON. The resolver turns it into an absolute path before the keyboard paints it.
  final String? imagePath;

  /// Blur radius used when the image was prepared (editor metadata).
  final double blur;

  /// Dim amount 0..1 painted over the image.
  final double dim;

  ThemeBackgroundSpec copyWith({
    ThemeBackgroundType? type,
    List<int>? gradientColors,
    double? gradientAngle,
    String? imagePath,
    double? blur,
    double? dim,
  }) => ThemeBackgroundSpec(
    type: type ?? this.type,
    gradientColors: gradientColors ?? this.gradientColors,
    gradientAngle: gradientAngle ?? this.gradientAngle,
    imagePath: imagePath ?? this.imagePath,
    blur: blur ?? this.blur,
    dim: dim ?? this.dim,
  );

  Json toJson() => {
    'type': type.name,
    if (gradientColors.isNotEmpty) 'gradientColors': gradientColors,
    'gradientAngle': gradientAngle,
    if (imagePath != null) 'imagePath': imagePath,
    'blur': blur,
    'dim': dim,
  };

  @override
  bool operator ==(Object other) =>
      other is ThemeBackgroundSpec &&
      other.type == type &&
      listEquals(other.gradientColors, gradientColors) &&
      other.gradientAngle == gradientAngle &&
      other.imagePath == imagePath &&
      other.blur == blur &&
      other.dim == dim;

  @override
  int get hashCode => Object.hash(type, Object.hashAll(gradientColors), gradientAngle, imagePath, blur, dim);
}

/// Colour overrides for popups and the swipe trail. Null = take from scheme.
@immutable
class ThemeAccentOverrides {
  const ThemeAccentOverrides({
    this.popupFill,
    this.popupLabel,
    this.popupSelectedFill,
    this.popupSelectedLabel,
    this.trailStart,
    this.trailEnd,
  });

  factory ThemeAccentOverrides.fromJson(Json j) => ThemeAccentOverrides(
    popupFill: _colorOrNull(j['popupFill']),
    popupLabel: _colorOrNull(j['popupLabel']),
    popupSelectedFill: _colorOrNull(j['popupSelectedFill']),
    popupSelectedLabel: _colorOrNull(j['popupSelectedLabel']),
    trailStart: _colorOrNull(j['trailStart']),
    trailEnd: _colorOrNull(j['trailEnd']),
  );

  final int? popupFill;
  final int? popupLabel;
  final int? popupSelectedFill;
  final int? popupSelectedLabel;
  final int? trailStart;
  final int? trailEnd;

  /// Changes the given fields. [clearPopup] and [clearTrail] reset the group to "from scheme".
  ThemeAccentOverrides copyWith({
    int? popupFill,
    int? popupLabel,
    int? popupSelectedFill,
    int? popupSelectedLabel,
    int? trailStart,
    int? trailEnd,
    bool clearPopup = false,
    bool clearTrail = false,
  }) => ThemeAccentOverrides(
    popupFill: clearPopup ? null : popupFill ?? this.popupFill,
    popupLabel: clearPopup ? null : popupLabel ?? this.popupLabel,
    popupSelectedFill: clearPopup ? null : popupSelectedFill ?? this.popupSelectedFill,
    popupSelectedLabel: clearPopup ? null : popupSelectedLabel ?? this.popupSelectedLabel,
    trailStart: clearTrail ? null : trailStart ?? this.trailStart,
    trailEnd: clearTrail ? null : trailEnd ?? this.trailEnd,
  );

  Json toJson() => {
    if (popupFill != null) 'popupFill': popupFill,
    if (popupLabel != null) 'popupLabel': popupLabel,
    if (popupSelectedFill != null) 'popupSelectedFill': popupSelectedFill,
    if (popupSelectedLabel != null) 'popupSelectedLabel': popupSelectedLabel,
    if (trailStart != null) 'trailStart': trailStart,
    if (trailEnd != null) 'trailEnd': trailEnd,
  };

  @override
  bool operator ==(Object other) =>
      other is ThemeAccentOverrides &&
      other.popupFill == popupFill &&
      other.popupLabel == popupLabel &&
      other.popupSelectedFill == popupSelectedFill &&
      other.popupSelectedLabel == popupSelectedLabel &&
      other.trailStart == trailStart &&
      other.trailEnd == trailEnd;

  @override
  int get hashCode => Object.hash(popupFill, popupLabel, popupSelectedFill, popupSelectedLabel, trailStart, trailEnd);
}

@immutable
class ThemeSpec {
  const ThemeSpec({
    required this.id,
    required this.name,
    this.colorSource = ThemeColorSource.seed,
    this.seedColor = 0xFFF5B700,
    this.variant = ThemeSchemeVariant.tonalSpot,
    this.customRoles = const {},
    this.customRolesDark,
    this.keyRadius = 0.5,
    this.borderWidth = 0,
    this.keyGap = 6,
    this.fontFamily = 'GoogleSansFlex',
    this.labelWeight = 500,
    this.fontRoundness,
    this.labelScale = 1.0,
    this.showHints = true,
    this.background = const ThemeBackgroundSpec(),
    this.accents = const ThemeAccentOverrides(),
    this.motionIntensity = 1.0,
  });

  /// Current JSON format version. Older versions are migrated on read.
  static const int currentVersion = 1;

  /// Parses (and migrates) a stored theme. Tolerant: unknown or invalid values
  /// fall back to defaults so a bad file can never crash the keyboard.
  factory ThemeSpec.fromJson(Json raw) {
    final j = migrateThemeJson(raw);
    return ThemeSpec(
      id: jString(j, 'id', 'custom'),
      name: jString(j, 'name', 'Custom'),
      colorSource: jEnum(j, 'colorSource', ThemeColorSource.values, ThemeColorSource.seed),
      seedColor: _colorOrNull(j['seedColor']) ?? 0xFFF5B700,
      variant: jEnum(j, 'variant', ThemeSchemeVariant.values, ThemeSchemeVariant.tonalSpot),
      customRoles: _roleMap(j['customRoles']) ?? const {},
      customRolesDark: _roleMap(j['customRolesDark']),
      keyRadius: jDouble(j, 'keyRadius', 0.5).clamp(0.0, 0.5),
      borderWidth: jDouble(j, 'borderWidth', 0).clamp(0.0, 4.0),
      keyGap: jDouble(j, 'keyGap', 6).clamp(0.0, 16.0),
      fontFamily: j.containsKey('fontFamily') ? jStringOrNull(j, 'fontFamily') : 'GoogleSansFlex',
      labelWeight: jInt(j, 'labelWeight', 500).clamp(100, 900),
      fontRoundness: j['fontRoundness'] is num ? (j['fontRoundness']! as num).toDouble().clamp(0.0, 100.0) : null,
      labelScale: jDouble(j, 'labelScale', 1.0).clamp(0.7, 1.5),
      showHints: jBool(j, 'showHints', true),
      background: ThemeBackgroundSpec.fromJson(jObject(j, 'background')),
      accents: ThemeAccentOverrides.fromJson(jObject(j, 'accents')),
      motionIntensity: jDouble(j, 'motionIntensity', 1.0).clamp(0.0, 2.0),
    );
  }

  final String id;
  final String name;
  final ThemeColorSource colorSource;

  /// ARGB. Fallback colour for [ThemeColorSource.dynamic].
  final int seedColor;
  final ThemeSchemeVariant variant;

  /// Role name (see [themeRoleNames]) to ARGB, used when colorSource is custom.
  final Map<String, int> customRoles;

  /// Dark-mode overrides; null = reuse [customRoles].
  final Map<String, int>? customRolesDark;

  /// Key corner radius as a fraction of the shorter side: 0 square .. 0.5 pill.
  final double keyRadius;
  final double borderWidth;
  final double keyGap;

  /// Null = system font.
  final String? fontFamily;

  /// 100..900.
  final int labelWeight;

  /// Google Sans Flex ROND axis 0..100. Null = follow [keyRadius] (pill = 100).
  final double? fontRoundness;
  final double labelScale;
  final bool showHints;
  final ThemeBackgroundSpec background;
  final ThemeAccentOverrides accents;

  /// 0 = no motion, 1 = normal, 2 = snappier and deeper press.
  final double motionIntensity;

  Json toJson() => {
    'version': currentVersion,
    'id': id,
    'name': name,
    'colorSource': colorSource.name,
    'seedColor': seedColor,
    'variant': variant.name,
    if (customRoles.isNotEmpty) 'customRoles': customRoles,
    if (customRolesDark != null) 'customRolesDark': customRolesDark,
    'keyRadius': keyRadius,
    'borderWidth': borderWidth,
    'keyGap': keyGap,
    'fontFamily': fontFamily,
    'labelWeight': labelWeight,
    if (fontRoundness != null) 'fontRoundness': fontRoundness,
    'labelScale': labelScale,
    'showHints': showHints,
    'background': background.toJson(),
    'accents': accents.toJson(),
    'motionIntensity': motionIntensity,
  };

  ThemeSpec copyWith({
    String? id,
    String? name,
    ThemeColorSource? colorSource,
    int? seedColor,
    ThemeSchemeVariant? variant,
    Map<String, int>? customRoles,
    Map<String, int>? customRolesDark,
    double? keyRadius,
    double? borderWidth,
    double? keyGap,
    String? fontFamily,
    int? labelWeight,
    double? fontRoundness,
    double? labelScale,
    bool? showHints,
    ThemeBackgroundSpec? background,
    ThemeAccentOverrides? accents,
    double? motionIntensity,
  }) => ThemeSpec(
    id: id ?? this.id,
    name: name ?? this.name,
    colorSource: colorSource ?? this.colorSource,
    seedColor: seedColor ?? this.seedColor,
    variant: variant ?? this.variant,
    customRoles: customRoles ?? this.customRoles,
    customRolesDark: customRolesDark ?? this.customRolesDark,
    keyRadius: keyRadius ?? this.keyRadius,
    borderWidth: borderWidth ?? this.borderWidth,
    keyGap: keyGap ?? this.keyGap,
    fontFamily: fontFamily ?? this.fontFamily,
    labelWeight: labelWeight ?? this.labelWeight,
    fontRoundness: fontRoundness ?? this.fontRoundness,
    labelScale: labelScale ?? this.labelScale,
    showHints: showHints ?? this.showHints,
    background: background ?? this.background,
    accents: accents ?? this.accents,
    motionIntensity: motionIntensity ?? this.motionIntensity,
  );

  @override
  bool operator ==(Object other) =>
      other is ThemeSpec &&
      other.id == id &&
      other.name == name &&
      other.colorSource == colorSource &&
      other.seedColor == seedColor &&
      other.variant == variant &&
      mapEquals(other.customRoles, customRoles) &&
      mapEquals(other.customRolesDark, customRolesDark) &&
      other.keyRadius == keyRadius &&
      other.borderWidth == borderWidth &&
      other.keyGap == keyGap &&
      other.fontFamily == fontFamily &&
      other.labelWeight == labelWeight &&
      other.fontRoundness == fontRoundness &&
      other.labelScale == labelScale &&
      other.showHints == showHints &&
      other.background == background &&
      other.accents == accents &&
      other.motionIntensity == motionIntensity;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    colorSource,
    seedColor,
    variant,
    Object.hashAll(customRoles.entries.map((e) => Object.hash(e.key, e.value))),
    keyRadius,
    borderWidth,
    keyGap,
    fontFamily,
    labelWeight,
    fontRoundness,
    labelScale,
    showHints,
    background,
    accents,
    motionIntensity,
  );
}

/// Role names accepted in `customRoles` (camelCase `ColorScheme` getters).
const List<String> themeRoleNames = [
  'primary',
  'onPrimary',
  'primaryContainer',
  'onPrimaryContainer',
  'secondary',
  'onSecondary',
  'secondaryContainer',
  'onSecondaryContainer',
  'tertiary',
  'onTertiary',
  'tertiaryContainer',
  'onTertiaryContainer',
  'error',
  'onError',
  'surface',
  'onSurface',
  'onSurfaceVariant',
  'surfaceDim',
  'surfaceBright',
  'surfaceContainerLowest',
  'surfaceContainerLow',
  'surfaceContainer',
  'surfaceContainerHigh',
  'surfaceContainerHighest',
  'outline',
  'outlineVariant',
];

// ---------------------------------------------------------------------------
// Migrations. Each entry upgrades a JSON object from version N to N+1.
// Add a new function here and bump [ThemeSpec.currentVersion] to change the
// format; never edit an old step.
// ---------------------------------------------------------------------------

/// Returns [raw] upgraded to [ThemeSpec.currentVersion]. A missing `version`
/// is treated as 0 (the pre-release flat format). Versions newer than this app
/// understands are returned unchanged and read leniently.
Json migrateThemeJson(Json raw) {
  var j = Map<String, Object?>.of(raw);
  var v = jInt(j, 'version', 0);
  while (v < ThemeSpec.currentVersion) {
    final step = _migrations[v];
    if (step == null) break;
    j = step(j);
    v++;
    j['version'] = v;
  }
  return j;
}

final Map<int, Json Function(Json)> _migrations = {0: _v0ToV1};

/// v0 (pre-release): flat keys `radius`, `gap`, `border`, `font`, `weight`,
/// `seed`, `scheme`, `bgColors`, `bgImage`, `bgDim`, `bgBlur`, `motion`.
Json _v0ToV1(Json j) {
  const renamed = {
    'radius': 'keyRadius',
    'gap': 'keyGap',
    'border': 'borderWidth',
    'font': 'fontFamily',
    'weight': 'labelWeight',
    'seed': 'seedColor',
    'scheme': 'variant',
    'motion': 'motionIntensity',
  };
  final out = <String, Object?>{};
  for (final e in j.entries) {
    out[renamed[e.key] ?? e.key] = e.value;
  }
  final hasGradient = out['bgColors'] is List && (out['bgColors']! as List).length >= 2;
  final hasImage = out['bgImage'] is String;
  if (hasGradient || hasImage || out.containsKey('bgDim') || out.containsKey('bgBlur')) {
    out['background'] = {
      'type': hasImage
          ? 'image'
          : hasGradient
          ? 'gradient'
          : 'solid',
      if (hasGradient) 'gradientColors': out['bgColors'],
      if (hasImage) 'imagePath': out['bgImage'],
      if (out['bgDim'] is num) 'dim': out['bgDim'],
      if (out['bgBlur'] is num) 'blur': out['bgBlur'],
    };
  }
  for (final k in ['bgColors', 'bgImage', 'bgDim', 'bgBlur']) {
    out.remove(k);
  }
  // v0 stored the source as a boolean `dynamic`.
  if (out.remove('dynamic') == true) out['colorSource'] = 'dynamic';
  return out;
}

int? _colorOrNull(Object? v) => v is num ? v.toInt() & 0xFFFFFFFF : null;

List<int> _colorList(Object? v) => v is List ? [for (final e in v) ?_colorOrNull(e)] : const [];

Map<String, int>? _roleMap(Object? v) {
  if (v is! Map) return null;
  return {
    for (final e in v.entries)
      if (e.key is String && themeRoleNames.contains(e.key) && _colorOrNull(e.value) != null)
        e.key as String: _colorOrNull(e.value)!,
  };
}
