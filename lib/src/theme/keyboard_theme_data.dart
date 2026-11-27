// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (Wave 0): the resolved values the keyboard view paints with.
// Produced by the theme system (Wave 1-D, theme_resolver.dart) from presets,
// the editor and Material You colors. Consumed by the keyboard view (Wave 1-A).
// New fields must have defaults in [KeyboardThemeData.fromScheme].
import 'package:material_ui/material_ui.dart';

@immutable
class KeyStyle {
  const KeyStyle({
    required this.fill,
    required this.pressedFill,
    required this.label,
    required this.hint,
    this.border,
    this.fillTop,
    this.edgeTop,
    this.shadow,
  });

  final Color fill;
  final Color pressedFill;
  final Color label;
  final Color hint;
  final Color? border;

  /// Glass keys: the fill fades from [fillTop] at the top to [fill] at the bottom.
  final Color? fillTop;

  /// Glass keys: the border fades from [edgeTop] at the top to [border] at the bottom (a lit top edge).
  final Color? edgeTop;

  /// Glass keys: a soft shadow under the key.
  final Color? shadow;
}

@immutable
class MotionSpec {
  const MotionSpec({this.enabled = true, this.pressScale = 0.92, this.stiffness = 800, this.dampingRatio = 0.6});

  /// False when the user or the system asked to remove animations.
  final bool enabled;

  /// Key scale while pressed.
  final double pressScale;

  /// Spring for press/release (Material 3 Expressive "fast spatial" defaults).
  final double stiffness;
  final double dampingRatio;
}

@immutable
class KeyboardThemeData {
  const KeyboardThemeData({
    required this.id,
    required this.brightness,
    required this.background,
    required this.letterKey,
    required this.functionKey,
    required this.actionKey,
    required this.spaceKey,
    required this.popupFill,
    required this.popupLabel,
    required this.popupSelectedFill,
    required this.popupSelectedLabel,
    required this.suggestionText,
    required this.suggestionHighlightFill,
    required this.suggestionHighlightText,
    required this.suggestionDivider,
    required this.toolbarIcon,
    required this.trailStart,
    required this.trailEnd,
    this.backgroundGradient,
    this.backgroundLayers = const [],
    this.backgroundImagePath,
    this.backgroundImageDim = 0,
    this.keyCornerRadius = 0.5,
    this.keyGap = 6,
    this.borderWidth = 0,
    this.fontFamily,
    this.labelWeight = FontWeight.w500,
    this.labelFontVariations = const [],
    this.labelScale = 1.0,
    this.showHints = true,
    this.motion = const MotionSpec(),
  });

  /// Neutral Material 3 theme built from a color scheme.
  factory KeyboardThemeData.fromScheme(ColorScheme scheme, {String id = 'fallback'}) => KeyboardThemeData(
    id: id,
    brightness: scheme.brightness,
    background: scheme.surfaceContainer,
    letterKey: KeyStyle(
      fill: scheme.surfaceContainerHighest,
      pressedFill: scheme.surfaceDim,
      label: scheme.onSurface,
      hint: scheme.onSurfaceVariant,
    ),
    functionKey: KeyStyle(
      fill: scheme.secondaryContainer,
      pressedFill: scheme.secondary.withValues(alpha: 0.4),
      label: scheme.onSecondaryContainer,
      hint: scheme.onSecondaryContainer,
    ),
    actionKey: KeyStyle(
      fill: scheme.primary,
      pressedFill: scheme.primary.withValues(alpha: 0.8),
      label: scheme.onPrimary,
      hint: scheme.onPrimary,
    ),
    spaceKey: KeyStyle(
      fill: scheme.surfaceContainerHighest,
      pressedFill: scheme.surfaceDim,
      label: scheme.onSurfaceVariant,
      hint: scheme.onSurfaceVariant,
    ),
    popupFill: scheme.primaryContainer,
    popupLabel: scheme.onPrimaryContainer,
    popupSelectedFill: scheme.primary,
    popupSelectedLabel: scheme.onPrimary,
    suggestionText: scheme.onSurface,
    suggestionHighlightFill: scheme.secondaryContainer,
    suggestionHighlightText: scheme.onSecondaryContainer,
    suggestionDivider: scheme.outlineVariant,
    toolbarIcon: scheme.onSurfaceVariant,
    trailStart: scheme.primary,
    trailEnd: scheme.tertiary,
  );

  factory KeyboardThemeData.fallback(Brightness brightness) =>
      KeyboardThemeData.fromScheme(ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: brightness));

  final String id;
  final Brightness brightness;
  final Color background;
  final Gradient? backgroundGradient;

  /// Painted in order over the background (the glass themes' soft lime glows).
  final List<Gradient> backgroundLayers;

  /// Pre-blurred/dimmed image file chosen in the theme editor.
  final String? backgroundImagePath;
  final double backgroundImageDim;
  final KeyStyle letterKey;
  final KeyStyle functionKey;
  final KeyStyle actionKey;
  final KeyStyle spaceKey;
  final Color popupFill;
  final Color popupLabel;
  final Color popupSelectedFill;
  final Color popupSelectedLabel;
  final Color suggestionText;
  final Color suggestionHighlightFill;
  final Color suggestionHighlightText;
  final Color suggestionDivider;
  final Color toolbarIcon;
  final Color trailStart;
  final Color trailEnd;

  /// 0 = square, 0.5 = pill (fraction of the key's shorter side).
  final double keyCornerRadius;

  /// Gap between keys (dp).
  final double keyGap;
  final double borderWidth;

  /// Bundled family (e.g. 'GoogleSansFlex'); null = system font.
  final String? fontFamily;
  final FontWeight labelWeight;

  /// Variable-font axes for key labels (e.g. wght, ROND for Google Sans Flex).
  /// Apply via TextStyle.fontVariations.
  final List<FontVariation> labelFontVariations;
  final double labelScale;
  final bool showHints;
  final MotionSpec motion;
}
