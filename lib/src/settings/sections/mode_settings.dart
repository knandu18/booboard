// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:meta/meta.dart';

import '../json_util.dart';

enum OneHandedMode { off, left, right }

@immutable
class ModeSettings {
  const ModeSettings({
    this.oneHanded = OneHandedMode.off,
    this.oneHandedWidth = 0.8,
    this.floating = false,
    this.floatingX = 0.1,
    this.floatingY = 0.5,
    this.floatingWidth = 0.8,
    this.splitOnWideScreens = true,
  });

  factory ModeSettings.fromJson(Json j) => ModeSettings(
    oneHanded: jEnum(j, 'oneHanded', OneHandedMode.values, OneHandedMode.off),
    oneHandedWidth: jDouble(j, 'oneHandedWidth', 0.8).clamp(0.6, 0.95),
    floating: jBool(j, 'floating', false),
    floatingX: jDouble(j, 'floatingX', 0.1).clamp(0.0, 1.0),
    floatingY: jDouble(j, 'floatingY', 0.5).clamp(0.0, 1.0),
    floatingWidth: jDouble(j, 'floatingWidth', 0.8).clamp(0.5, 1.0),
    splitOnWideScreens: jBool(j, 'splitOnWideScreens', true),
  );

  final OneHandedMode oneHanded;

  /// Fraction of screen width in one-handed mode.
  final double oneHandedWidth;
  final bool floating;

  /// Floating keyboard: [floatingX] and [floatingY] are fractions of the free space left beside and
  /// above the card (0 = left or top edge, 1 = right or bottom edge), so they stay on screen after a
  /// rotation. [floatingWidth] is the card width as a fraction of the screen.
  final double floatingX;
  final double floatingY;
  final double floatingWidth;
  final bool splitOnWideScreens;

  Json toJson() => {
    'oneHanded': oneHanded.name,
    'oneHandedWidth': oneHandedWidth,
    'floating': floating,
    'floatingX': floatingX,
    'floatingY': floatingY,
    'floatingWidth': floatingWidth,
    'splitOnWideScreens': splitOnWideScreens,
  };

  ModeSettings copyWith({
    OneHandedMode? oneHanded,
    double? oneHandedWidth,
    bool? floating,
    double? floatingX,
    double? floatingY,
    double? floatingWidth,
    bool? splitOnWideScreens,
  }) => ModeSettings(
    oneHanded: oneHanded ?? this.oneHanded,
    oneHandedWidth: oneHandedWidth ?? this.oneHandedWidth,
    floating: floating ?? this.floating,
    floatingX: floatingX ?? this.floatingX,
    floatingY: floatingY ?? this.floatingY,
    floatingWidth: floatingWidth ?? this.floatingWidth,
    splitOnWideScreens: splitOnWideScreens ?? this.splitOnWideScreens,
  );
}
