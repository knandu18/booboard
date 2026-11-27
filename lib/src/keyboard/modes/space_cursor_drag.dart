// SPDX-License-Identifier: GPL-3.0-or-later
//
// Space-bar cursor control: turns the horizontal travel of a finger on the space bar into cursor
// steps. Slow drags move one character per 12 dp, fast drags one per 4 dp. Each call reports only
// the new whole steps, so the editor sees deltas and never a repeat of earlier moves.
import 'dart:math' as math;

/// Dp of travel per cursor step, slow and fast.
const double kSlowDpPerStep = 12;
const double kFastDpPerStep = 4;

/// Speeds in dp per millisecond: below the first, drags are slow; above the second, fast.
const double _slowSpeed = 0.2;
const double _fastSpeed = 1.0;

class SpaceCursorDrag {
  SpaceCursorDrag({required this.move, this.tick, int Function()? clockMs}) : _clock = clockMs ?? _monotonicMs;

  /// Moves the cursor by [steps] characters (negative is left). Never called with 0.
  final void Function(int steps) move;

  /// A light haptic tick every one or two steps.
  final void Function()? tick;

  final int Function() _clock;

  double _lastDx = 0;
  int? _lastMs;
  double _speed = 0;
  double _fraction = 0;
  int _sinceTick = 0;

  /// Smoothed finger speed in dp per millisecond (exposed for tests).
  double get speed => _speed;

  /// Called with the total horizontal travel since touch-down, in dp. [done] ends the drag.
  void drag(double dx, {required bool done}) {
    if (done) {
      reset();
      return;
    }
    final now = _clock();
    final ddx = dx - _lastDx;
    _lastDx = dx;
    final last = _lastMs;
    _lastMs = now;
    if (last != null) {
      final instant = ddx.abs() / math.max(now - last, 1);
      _speed = _speed == 0 ? instant : 0.5 * _speed + 0.5 * instant;
    }
    final t = ((_speed - _slowSpeed) / (_fastSpeed - _slowSpeed)).clamp(0.0, 1.0).toDouble();
    final stepsPerDp = 1 / kSlowDpPerStep + (1 / kFastDpPerStep - 1 / kSlowDpPerStep) * t;
    _fraction += ddx * stepsPerDp;
    final whole = _fraction.truncate();
    _fraction -= whole;
    if (whole == 0) return;
    move(whole);
    _sinceTick += whole.abs();
    final every = t > 0.5 ? 1 : 2;
    if (_sinceTick >= every) {
      _sinceTick = 0;
      tick?.call();
    }
  }

  /// Forgets the touch: the next drag starts from zero.
  void reset() {
    _lastDx = 0;
    _lastMs = null;
    _speed = 0;
    _fraction = 0;
    _sinceTick = 0;
  }

  static final Stopwatch _watch = Stopwatch()..start();
  static int _monotonicMs() => _watch.elapsedMilliseconds;
}
