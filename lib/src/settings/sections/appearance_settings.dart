// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:meta/meta.dart';

import '../json_util.dart';

enum DarkModePreference { system, light, dark }

enum ContrastPreference { standard, medium, high }

@immutable
class AppearanceSettings {
  const AppearanceSettings({
    this.themeId = 'booboard_glass_dark', // = defaultThemeId (Dark Glass)
    this.darkMode = DarkModePreference.system,
    this.pureBlack = false,
    this.contrast = ContrastPreference.standard,
    this.heightScale = 1.0,
    this.landscapeHeightScale = 1.0,
    this.customThemeRevision = 0,
  });

  factory AppearanceSettings.fromJson(Json j) => AppearanceSettings(
    themeId: jString(j, 'themeId', 'booboard_glass_dark'),
    darkMode: jEnum(j, 'darkMode', DarkModePreference.values, DarkModePreference.system),
    pureBlack: jBool(j, 'pureBlack', false),
    contrast: jEnum(j, 'contrast', ContrastPreference.values, ContrastPreference.standard),
    heightScale: jDouble(j, 'heightScale', 1.0).clamp(0.7, 1.5),
    landscapeHeightScale: jDouble(j, 'landscapeHeightScale', 1.0).clamp(0.6, 1.5),
    customThemeRevision: jInt(j, 'customThemeRevision', 0).clamp(0, 1 << 30),
  );

  /// Preset id or custom theme id (`custom:<uuid>`; custom themes live in their own files).
  final String themeId;
  final DarkModePreference darkMode;
  final bool pureBlack;
  final ContrastPreference contrast;
  final double heightScale;
  final double landscapeHeightScale;

  /// Bumped whenever a custom theme is saved or deleted. The keyboard re-resolves when this
  /// object changes, so a theme edited while in use takes effect at once.
  final int customThemeRevision;

  Json toJson() => {
    'themeId': themeId,
    'darkMode': darkMode.name,
    'pureBlack': pureBlack,
    'contrast': contrast.name,
    'heightScale': heightScale,
    'landscapeHeightScale': landscapeHeightScale,
    'customThemeRevision': customThemeRevision,
  };

  AppearanceSettings copyWith({
    String? themeId,
    DarkModePreference? darkMode,
    bool? pureBlack,
    ContrastPreference? contrast,
    double? heightScale,
    double? landscapeHeightScale,
    int? customThemeRevision,
  }) => AppearanceSettings(
    themeId: themeId ?? this.themeId,
    darkMode: darkMode ?? this.darkMode,
    pureBlack: pureBlack ?? this.pureBlack,
    contrast: contrast ?? this.contrast,
    heightScale: heightScale ?? this.heightScale,
    landscapeHeightScale: landscapeHeightScale ?? this.landscapeHeightScale,
    customThemeRevision: customThemeRevision ?? this.customThemeRevision,
  );
}
