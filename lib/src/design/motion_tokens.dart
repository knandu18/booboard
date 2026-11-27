// SPDX-License-Identifier: GPL-3.0-or-later
//
// Material 3 Expressive spring motion tokens. Spatial springs move things
// (position, size, shape) and may overshoot; effects springs change colour or
// opacity and never overshoot.
import 'package:meta/meta.dart';

@immutable
class SpringToken {
  const SpringToken(this.stiffness, this.dampingRatio);

  final double stiffness;
  final double dampingRatio;

  /// Scales the stiffness by [factor] (motion intensity). Damping is kept.
  SpringToken scaled(double factor) => SpringToken(stiffness * factor, dampingRatio);

  @override
  bool operator ==(Object other) =>
      other is SpringToken && other.stiffness == stiffness && other.dampingRatio == dampingRatio;

  @override
  int get hashCode => Object.hash(stiffness, dampingRatio);

  @override
  String toString() => 'SpringToken($stiffness, $dampingRatio)';
}

abstract final class BooBoardMotion {
  // Spatial (expressive: slight overshoot).
  static const SpringToken fastSpatial = SpringToken(800, 0.6);
  static const SpringToken defaultSpatial = SpringToken(380, 0.8);
  static const SpringToken slowSpatial = SpringToken(200, 0.8);

  // Effects (no overshoot).
  static const SpringToken fastEffects = SpringToken(3800, 1.0);
  static const SpringToken defaultEffects = SpringToken(1600, 1.0);
  static const SpringToken slowEffects = SpringToken(800, 1.0);

  /// Key scale while pressed.
  static const double pressScale = 0.92;
}
