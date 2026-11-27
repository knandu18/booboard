// SPDX-License-Identifier: GPL-3.0-or-later
//
// Builds light and dark ColorSchemes from the Android 12+ system palettes
// (SystemColorsMessage.palettes), using the Material 3 baseline role mapping.
import 'package:material_ui/material_ui.dart';

import '../design/tonal_tokens.dart';

/// Palette order delivered by the platform.
enum SystemPalette { accent1, accent2, accent3, neutral1, neutral2 }

/// True when [palettes] holds 5 palettes x 13 opaque colours.
bool isValidSystemPalettes(List<int> palettes) {
  if (palettes.length != SystemPalette.values.length * androidTones.length) return false;
  for (final c in palettes) {
    if (((c >> 24) & 0xFF) != 0xFF) return false;
  }
  return true;
}

/// One tone of one system palette: [androidTone] is 0,10,50,100,...,1000.
/// Android tone N corresponds to Material tone 100 - N/10.
Color systemTone(List<int> palettes, SystemPalette palette, int androidTone) {
  final i = androidTones.indexOf(androidTone);
  if (i < 0) throw ArgumentError.value(androidTone, 'androidTone');
  return Color((palettes[palette.index * androidTones.length + i] & 0xFFFFFFFF) | 0xFF000000);
}

/// Material tone (0..100) of a system palette. Tones between the 13 delivered
/// stops are interpolated.
Color systemToneM3(List<int> palettes, SystemPalette palette, double m3Tone) {
  final a = ((100 - m3Tone.clamp(0, 100)) * 10).toDouble();
  for (var i = 0; i < androidTones.length - 1; i++) {
    final lo = androidTones[i];
    final hi = androidTones[i + 1];
    if (a >= lo && a <= hi) {
      final t = (a - lo) / (hi - lo);
      return Color.lerp(systemTone(palettes, palette, lo), systemTone(palettes, palette, hi), t)!;
    }
  }
  return systemTone(palettes, palette, androidTones.last);
}

double _lerpD(double a, double b, double t) => a + (b - a) * t;

/// The Material 3 baseline mapping of system palettes to a [ColorScheme].
///
/// [contrastLevel] is 0 (standard), 0.5 (medium) or 1.0 (high); it moves the
/// accent, outline and variant-text tones toward higher contrast.
///
/// Returns null when [palettes] is not a valid 5 x 13 palette set.
ColorScheme? materialYouScheme(List<int> palettes, Brightness brightness, {double contrastLevel = 0}) {
  if (!isValidSystemPalettes(palettes)) return null;
  final c = contrastLevel.clamp(0.0, 1.0);
  final dark = brightness == Brightness.dark;
  Color t(SystemPalette p, double tone) => systemToneM3(palettes, p, tone);

  // Accent tones (primary/secondary/tertiary share them).
  final accentTone = dark ? _lerpD(80, 90, c) : _lerpD(40, 20, c);
  final onAccentTone = dark ? _lerpD(20, 10, c) : 100.0;
  final containerTone = dark ? 30.0 : 90.0;
  final onContainerTone = dark ? 90.0 : 10.0;

  const a1 = SystemPalette.accent1;
  const a2 = SystemPalette.accent2;
  const a3 = SystemPalette.accent3;
  const n1 = SystemPalette.neutral1;
  const n2 = SystemPalette.neutral2;

  return ColorScheme(
    brightness: brightness,
    primary: t(a1, accentTone),
    onPrimary: t(a1, onAccentTone),
    primaryContainer: t(a1, containerTone),
    onPrimaryContainer: t(a1, onContainerTone),
    secondary: t(a2, accentTone),
    onSecondary: t(a2, onAccentTone),
    secondaryContainer: t(a2, containerTone),
    onSecondaryContainer: t(a2, onContainerTone),
    tertiary: t(a3, accentTone),
    onTertiary: t(a3, onAccentTone),
    tertiaryContainer: t(a3, containerTone),
    onTertiaryContainer: t(a3, onContainerTone),
    error: dark ? const Color(0xFFF2B8B5) : const Color(0xFFB3261E),
    onError: dark ? const Color(0xFF601410) : const Color(0xFFFFFFFF),
    errorContainer: dark ? const Color(0xFF8C1D18) : const Color(0xFFF9DEDC),
    onErrorContainer: dark ? const Color(0xFFF9DEDC) : const Color(0xFF410E0B),
    surface: t(n1, dark ? 6 : 98),
    onSurface: t(n1, dark ? 90 : 10),
    surfaceDim: t(n1, dark ? 6 : 87),
    surfaceBright: t(n1, dark ? 24 : 98),
    surfaceContainerLowest: t(n1, dark ? 4 : 100),
    surfaceContainerLow: t(n1, dark ? 10 : 96),
    surfaceContainer: t(n1, dark ? 12 : 94),
    surfaceContainerHigh: t(n1, dark ? 17 : 92),
    surfaceContainerHighest: t(n1, dark ? 22 : 90),
    onSurfaceVariant: t(n2, dark ? _lerpD(80, 95, c) : _lerpD(30, 10, c)),
    outline: t(n2, dark ? _lerpD(60, 80, c) : _lerpD(50, 30, c)),
    outlineVariant: t(n2, dark ? _lerpD(30, 50, c) : _lerpD(80, 60, c)),
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    inverseSurface: t(n1, dark ? 90 : 20),
    onInverseSurface: t(n1, dark ? 20 : 95),
    inversePrimary: t(a1, dark ? 40 : 80),
  );
}
