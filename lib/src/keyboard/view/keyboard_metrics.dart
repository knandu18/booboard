// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import '../../bridge/messages.g.dart';
import '../../settings/booboard_settings.dart';
import '../layout/layout_engine.dart';

/// Sizes of the keyboard window. Dart owns the total height: the IME window
/// is exactly [totalHeight] dp (content plus the bottom inset Flutter applies).
abstract final class KeyboardMetrics {
  /// Suggestion strip.
  static const double stripHeight = 44;

  /// One standard key row before the height scale.
  static const double rowHeight = 56;

  /// Relative height of the optional number row.
  static const double numberRowUnits = 0.8;

  /// Rows in every page (the number row adds [numberRowUnits] when enabled).
  static const double baseRowUnits = 4;

  /// Landscape on a phone (smallest width under 600 dp): key rows are capped at [kCompactKeyHeight].
  static bool isCompact(WindowMetricsMessage? m) => m != null && m.isLandscape && m.smallestScreenWidthDp < 600;

  /// Split layout: tablets and unfolded foldables (smallest width at least 600 dp) whose keyboard is at
  /// least 600 dp wide, when the user allows it. Phones in landscape get [isCompact] instead.
  static bool isSplit(BooBoardSettings s, double widthDp, WindowMetricsMessage? m) =>
      s.modes.splitOnWideScreens && widthDp >= 600 && m != null && m.smallestScreenWidthDp >= 600;

  static double heightScale(AppearanceSettings a, {required bool landscape}) =>
      landscape ? a.landscapeHeightScale : a.heightScale;

  /// Height of the key rows (strip excluded). Constant across pages so the
  /// window never resizes when the page changes.
  static double rowsHeight(BooBoardSettings s, {required bool landscape, bool compact = false}) {
    final units = baseRowUnits + (s.typing.numberRow ? numberRowUnits : 0);
    final row = rowHeight * heightScale(s.appearance, landscape: landscape);
    return units * (compact ? math.min(row, kCompactKeyHeight) : row);
  }

  /// Content height: strip plus rows.
  static double contentHeight(BooBoardSettings s, {required bool landscape, bool compact = false}) =>
      stripHeight + rowsHeight(s, landscape: landscape, compact: compact);

  /// What to send in WindowLayoutMessage.heightDp.
  static double totalHeight(
    BooBoardSettings s, {
    required bool landscape,
    required double bottomInset,
    bool compact = false,
  }) => contentHeight(s, landscape: landscape, compact: compact) + bottomInset;
}
