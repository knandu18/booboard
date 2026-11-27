// SPDX-License-Identifier: GPL-3.0-or-later
//
// Pure geometry for the keyboard modes (one-handed, floating, height). No widgets here, so the
// rules are unit-tested: window heights, keyboard widths and rects, snapping and clamping.
//
// Units: dp. W is the IME window width, screenH the screen height. The IME window is docked at the
// bottom of the screen; a floating keyboard lives inside a transparent window of height H.
import 'dart:math' as math;
import 'dart:ui' show Rect;

/// Kotlin clamps the IME window height to this range.
const double kMinWindowHeight = 120;
const double kMaxWindowHeight = 640;

/// Height of the bar above the keyboard (floating move bar, height bar).
const double kTopBarHeight = 48;

/// Narrowest strip kept beside a one-handed keyboard, so its buttons keep 48 dp targets.
const double kOneHandedStripWidth = 56;

/// Tablets and foldables: at least this width (dp) is "wide".
const double kWideScreenWidth = 600;

/// Snap distance for the floating keyboard's edges, in dp.
const double kSnapDistance = 16;

const double kMinOneHanded = 0.6;
const double kMaxOneHanded = 0.95;
const double kMinFloatingWidth = 0.6;
const double kMinHeightScale = 0.7;
const double kMaxHeightScale = 1.5;

/// Keyboard height (strip included) at row scale [scale]. Mirrors `KeyboardMetrics.rowsHeight`, which
/// is linear in the scale, so [naturalH] is the height at [currentScale].
double keyboardHeightFor({
  required double scale,
  required double naturalH,
  required double currentScale,
  required double stripH,
}) {
  final rows = naturalH - stripH;
  return stripH + rows * (scale / currentScale);
}

/// The row scale that gives keyboard height [h] (strip included), clamped to 0.7 to 1.5.
double heightScaleFor({
  required double h,
  required double naturalH,
  required double currentScale,
  required double stripH,
}) {
  final rows = naturalH - stripH;
  if (rows <= 0) return currentScale;
  final scale = currentScale * (h - stripH) / rows;
  return scale.clamp(kMinHeightScale, kMaxHeightScale).toDouble();
}

/// Width of the one-handed keyboard. It never leaves less than [kOneHandedStripWidth] for the buttons.
double oneHandedWidth({required double screenW, required double fraction}) {
  final wanted = fraction.clamp(kMinOneHanded, kMaxOneHanded) * screenW;
  final room = math.max(screenW - kOneHandedStripWidth, screenW * kMinOneHanded);
  return math.min(wanted, room).toDouble();
}

/// Height of the floating window: 85% of the screen height, at most 640 dp, and never shorter than
/// the keyboard that has to fit in it.
double floatingWindowHeight({required double screenH, required double contentH}) {
  final h = math.min(kMaxWindowHeight, math.max(screenH * 0.85, contentH));
  return math.max(kMinWindowHeight, h).toDouble();
}

/// Width fraction of the floating keyboard: 60% to 100% of the screen.
double floatingWidthFraction(double value) => value.clamp(kMinFloatingWidth, 1.0).toDouble();

/// The floating keyboard rect in window coordinates. [x] and [y] are fractions of the free space, so
/// 0 is the left or top edge and 1 the right or bottom edge. The rect stays on screen by construction,
/// which also covers rotation.
Rect floatingRect({
  required double windowW,
  required double windowH,
  required double width,
  required double height,
  required double x,
  required double y,
}) {
  final w = math.min(width, windowW).toDouble();
  final h = math.min(height, windowH).toDouble();
  final left = x.clamp(0.0, 1.0).toDouble() * (windowW - w);
  final top = y.clamp(0.0, 1.0).toDouble() * (windowH - h);
  return Rect.fromLTWH(left, top, w, h);
}

/// Moves [r] (same size) so that it lies inside the window.
Rect clampRectToWindow(Rect r, {required double windowW, required double windowH}) {
  final left = r.left.clamp(0.0, math.max(0.0, windowW - r.width)).toDouble();
  final top = r.top.clamp(0.0, math.max(0.0, windowH - r.height)).toDouble();
  return Rect.fromLTWH(left, top, r.width, r.height);
}

/// Snaps a dragged rect to the left, right and bottom edges when it is within [kSnapDistance].
Rect snapFloatingRect(Rect r, {required double windowW, required double windowH}) {
  var left = r.left;
  var top = r.top;
  if (left.abs() <= kSnapDistance) left = 0;
  if ((windowW - r.right).abs() <= kSnapDistance) left = windowW - r.width;
  if ((windowH - r.bottom).abs() <= kSnapDistance) top = windowH - r.height;
  return Rect.fromLTWH(left, top, r.width, r.height);
}

/// Fraction of the free horizontal space the rect sits at (0 = left edge, 1 = right edge).
double floatingXFraction(Rect r, {required double windowW}) {
  final free = windowW - r.width;
  if (free <= 0) return 0;
  return (r.left / free).clamp(0.0, 1.0).toDouble();
}

/// Fraction of the free vertical space the rect sits at (0 = top edge, 1 = bottom edge).
double floatingYFraction(Rect r, {required double windowH}) {
  final free = windowH - r.height;
  if (free <= 0) return 0;
  return (r.top / free).clamp(0.0, 1.0).toDouble();
}
