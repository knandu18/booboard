// SPDX-License-Identifier: GPL-3.0-or-later
//
// The glass keyboards (2026-11-26; prototype .design/topbar_v2_body.html): frosted, see-through keys
// drawn over BooBoard's own background with soft lime glows. Dark Glass is the default and always
// dark; Lime Glass is always light. They are hand-made rather than derived from a colour scheme, so the
// phone's dark mode and Material You colours do not change them.
import 'package:material_ui/material_ui.dart';

import '../design/design.dart';
import 'keyboard_theme_data.dart';

/// Ids of the glass presets (see `ThemePresets`).
abstract final class GlassThemeIds {
  static const String dark = 'booboard_glass_dark';
  static const String lime = 'booboard_glass_lime';
}

const Color _lime = Color(0xFFE3F794);
const Color _ink = Color(0xFF161015);
const Color _paper = Color(0xFFF3F1EC);

Color _white(double a) => Colors.white.withValues(alpha: a);

/// The glass theme for [id], or null when [id] is not a glass preset. [motion] comes from the resolver.
KeyboardThemeData? glassThemeFor(String id, {required MotionSpec motion, bool highContrast = false}) => switch (id) {
  GlassThemeIds.dark => _darkGlass(motion, highContrast),
  GlassThemeIds.lime => _limeGlass(motion, highContrast),
  _ => null,
};

List<FontVariation> _variations() => BooBoardType.variations(weight: 500, roundness: 50);

KeyboardThemeData _darkGlass(MotionSpec motion, bool highContrast) {
  // High contrast: nearly opaque dark keys, so labels never depend on what glows behind them.
  final hc = highContrast;
  final letter = KeyStyle(
    fill: hc ? const Color(0xF2221C21) : _white(0.07),
    fillTop: hc ? const Color(0xF22E282D) : _white(0.17),
    pressedFill: hc ? const Color(0xF2443D42) : _white(0.20),
    label: _paper,
    hint: _paper,
    border: _white(0.08),
    edgeTop: _white(0.30),
    shadow: Colors.black.withValues(alpha: 0.35),
  );
  return KeyboardThemeData(
    id: GlassThemeIds.dark,
    brightness: Brightness.dark,
    background: _ink,
    backgroundGradient: const LinearGradient(
      begin: Alignment(-0.5, -1),
      end: Alignment(0.5, 1),
      colors: [Color(0xFF241E23), _ink],
    ),
    backgroundLayers: [
      RadialGradient(
        center: const Alignment(-0.6, -0.5),
        radius: 0.7,
        colors: [_lime.withValues(alpha: 0.20), _lime.withValues(alpha: 0)],
      ),
      RadialGradient(
        center: const Alignment(0.7, 0.6),
        radius: 0.8,
        colors: [_lime.withValues(alpha: 0.12), _lime.withValues(alpha: 0)],
      ),
    ],
    letterKey: letter,
    functionKey: KeyStyle(
      fill: hc ? const Color(0xF21B161A) : _white(0.04),
      fillTop: hc ? const Color(0xF2262025) : _white(0.09),
      pressedFill: hc ? const Color(0xF2443D42) : _white(0.18),
      label: _paper,
      hint: _paper,
      border: _white(0.06),
      edgeTop: _white(0.22),
      shadow: Colors.black.withValues(alpha: 0.30),
    ),
    actionKey: KeyStyle(
      fill: _lime,
      fillTop: const Color(0xFFEFFCB8),
      pressedFill: const Color(0xFFC6DB70),
      label: _ink,
      hint: _ink,
      border: _lime,
      edgeTop: _white(0.7),
      shadow: Colors.black.withValues(alpha: 0.35),
    ),
    spaceKey: KeyStyle(
      fill: letter.fill,
      fillTop: letter.fillTop,
      pressedFill: letter.pressedFill,
      label: _paper,
      hint: _paper,
      border: letter.border,
      edgeTop: letter.edgeTop,
      shadow: letter.shadow,
    ),
    popupFill: const Color(0xFF3A3338),
    popupLabel: _paper,
    popupSelectedFill: _lime,
    popupSelectedLabel: _ink,
    suggestionText: _paper,
    suggestionHighlightFill: _lime,
    suggestionHighlightText: _ink,
    suggestionDivider: _paper.withValues(alpha: 0.2),
    toolbarIcon: _paper,
    trailStart: _lime,
    trailEnd: const Color(0xFFB9DD52),
    keyCornerRadius: 0.25,
    keyGap: 6,
    borderWidth: 1,
    fontFamily: 'GoogleSansFlex',
    labelFontVariations: _variations(),
    labelScale: 0.9,
    showHints: false,
    motion: motion,
  );
}

KeyboardThemeData _limeGlass(MotionSpec motion, bool highContrast) {
  final k = highContrast ? 1.6 : 1.0;
  final letter = KeyStyle(
    fill: _white((0.38 * k).clamp(0, 1)),
    fillTop: _white((0.72 * k).clamp(0, 1)),
    pressedFill: _white(0.95),
    label: _ink,
    hint: _ink.withValues(alpha: 0.8),
    border: _white(0.55),
    edgeTop: _white(0.95),
    shadow: const Color(0xFF506400).withValues(alpha: 0.20),
  );
  return KeyboardThemeData(
    id: GlassThemeIds.lime,
    brightness: Brightness.light,
    background: _lime,
    backgroundGradient: const LinearGradient(
      begin: Alignment(-0.5, -1),
      end: Alignment(0.5, 1),
      colors: [Color(0xFFEEFBB6), Color(0xFFDDF487), Color(0xFFCBE86A)],
    ),
    backgroundLayers: [
      RadialGradient(center: const Alignment(-0.6, -0.4), radius: 0.6, colors: [_white(0.7), _white(0)]),
      RadialGradient(
        center: const Alignment(0.7, 0.6),
        radius: 0.8,
        colors: [const Color(0xFFBFE04F).withValues(alpha: 0.6), const Color(0xFFBFE04F).withValues(alpha: 0)],
      ),
    ],
    letterKey: letter,
    functionKey: KeyStyle(
      fill: _white(0.16 * k),
      fillTop: _white(0.42 * k),
      pressedFill: _white(0.8),
      label: _ink,
      hint: _ink.withValues(alpha: 0.8),
      border: _white(0.45),
      edgeTop: _white(0.9),
      shadow: const Color(0xFF506400).withValues(alpha: 0.16),
    ),
    actionKey: KeyStyle(
      fill: _ink,
      fillTop: const Color(0xFF2E282D),
      pressedFill: const Color(0xFF3A3338),
      label: _lime,
      hint: _lime,
      border: _ink,
      edgeTop: _white(0.25),
      shadow: const Color(0xFF506400).withValues(alpha: 0.25),
    ),
    spaceKey: KeyStyle(
      fill: letter.fill,
      fillTop: letter.fillTop,
      pressedFill: letter.pressedFill,
      label: _ink.withValues(alpha: 0.8),
      hint: _ink.withValues(alpha: 0.8),
      border: letter.border,
      edgeTop: letter.edgeTop,
      shadow: letter.shadow,
    ),
    popupFill: Colors.white,
    popupLabel: _ink,
    popupSelectedFill: _ink,
    popupSelectedLabel: _lime,
    suggestionText: _ink,
    suggestionHighlightFill: Colors.white,
    suggestionHighlightText: _ink,
    suggestionDivider: _ink.withValues(alpha: 0.18),
    toolbarIcon: _ink,
    trailStart: _ink,
    trailEnd: const Color(0xFF4E5E12),
    keyCornerRadius: 0.25,
    keyGap: 6,
    borderWidth: 1,
    fontFamily: 'GoogleSansFlex',
    labelFontVariations: _variations(),
    labelScale: 0.9,
    showHints: false,
    motion: motion,
  );
}
