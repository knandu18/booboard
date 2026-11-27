// SPDX-License-Identifier: GPL-3.0-or-later
//
// Material 3 Expressive shape scale (corner radii in dp).

/// Corner radius tokens in dp. [full] is a stadium/pill.
abstract final class BooBoardShape {
  static const double none = 0;
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double largeIncreased = 20;
  static const double extraLarge = 28;
  static const double extraLargeIncreased = 32;
  static const double extraExtraLarge = 48;
  static const double full = 1000;

  /// All stops, ascending, excluding [full].
  static const List<double> scale = [
    none,
    extraSmall,
    small,
    medium,
    large,
    largeIncreased,
    extraLarge,
    extraLargeIncreased,
    extraExtraLarge,
  ];

  /// Corner radius in dp for a key whose shorter side is [shortSide], given a
  /// radius factor in 0..0.5 (0 = square, 0.5 = pill).
  static double keyRadius(double factor, double shortSide) => factor.clamp(0.0, 0.5) * shortSide;
}
