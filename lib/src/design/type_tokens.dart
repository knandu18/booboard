// SPDX-License-Identifier: GPL-3.0-or-later
//
// Type scale for key labels. Sizes are in logical pixels at labelScale 1.0.
import 'package:material_ui/material_ui.dart';

abstract final class BooBoardType {
  /// Primary letter on a key.
  static const double keyLabel = 22;

  /// Small hint (long-press character) in the key corner.
  static const double keyHint = 10;

  /// Function key text (e.g. "?123", "abc").
  static const double functionLabel = 16;

  /// Space bar language name.
  static const double spaceLabel = 14;

  /// Suggestion bar text.
  static const double suggestion = 16;

  /// Popup preview letter.
  static const double popupLabel = 30;

  /// Variable font axis tags.
  static const String weightAxis = 'wght';
  static const String roundnessAxis = 'ROND';

  /// Builds the variable-font axes for key labels. [roundness] is 0..100.
  static List<FontVariation> variations({required double weight, required double roundness}) => [
    FontVariation(weightAxis, weight.clamp(100, 1000).toDouble()),
    FontVariation(roundnessAxis, roundness.clamp(0, 100).toDouble()),
  ];
}
