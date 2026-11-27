// SPDX-License-Identifier: GPL-3.0-or-later
//
// Spring animation of pressed keys (Material 3 Expressive "fast spatial").
// Each key has a progress value: 0 = resting, 1 = fully pressed. A spring
// drives it, so it can overshoot a little and feel alive.
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/keyboard_theme_data.dart';

class _KeySpring {
  _KeySpring(this.sim, this.startTime, this.target, {required this.x, required this.v});

  SpringSimulation sim;
  double startTime;
  double target;
  double x;
  double v;
}

class KeyPressAnimator extends ChangeNotifier {
  KeyPressAnimator({required TickerProvider vsync, this._motion = const MotionSpec()}) {
    _ticker = vsync.createTicker(_onTick);
  }

  late final Ticker _ticker;
  MotionSpec _motion;
  final Map<int, _KeySpring> _springs = {};
  final Map<int, double> _held = {};
  double _time = 0;
  Duration _last = Duration.zero;

  MotionSpec get motion => _motion;

  set motion(MotionSpec value) {
    if (identical(_motion, value)) return;
    final wasEnabled = _motion.enabled;
    _motion = value;
    if (wasEnabled && !value.enabled) {
      _springs.clear();
      _ticker.stop();
      notifyListeners();
    }
  }

  /// Current press progress of [key] (can overshoot outside 0..1 while the spring settles).
  double progress(int key) => _springs[key]?.x ?? _held[key] ?? 0;

  bool get isAnimating => _springs.isNotEmpty;

  void press(int key) => _retarget(key, 1);

  void release(int key) => _retarget(key, 0);

  void releaseAll() {
    for (final k in {..._springs.keys, ..._held.keys}.toList()) {
      _retarget(k, 0);
    }
  }

  void _retarget(int key, double target) {
    if (!_motion.enabled) {
      if (target == 0) {
        _held.remove(key);
      } else {
        _held[key] = 1;
      }
      notifyListeners();
      return;
    }
    final current = _springs[key];
    final x = current?.x ?? _held[key] ?? 0;
    final v = current?.v ?? 0;
    _held.remove(key);
    final sim = SpringSimulation(
      SpringDescription.withDampingRatio(mass: 1, stiffness: _motion.stiffness, ratio: _motion.dampingRatio),
      x,
      target,
      v,
    );
    _springs[key] = _KeySpring(sim, _time, target, x: x, v: v);
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
    notifyListeners();
  }

  void _onTick(Duration elapsed) {
    _time += (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final done = <int>[];
    _springs.forEach((key, s) {
      final t = _time - s.startTime;
      s.x = s.sim.x(t);
      s.v = s.sim.dx(t);
      if (s.sim.isDone(t)) done.add(key);
    });
    for (final k in done) {
      final s = _springs.remove(k)!;
      if (s.target != 0) _held[k] = s.target;
    }
    if (_springs.isEmpty) _ticker.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
