// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/keyboard/modes/mode_geometry.dart';

void main() {
  group('height scale', () {
    test('the keyboard height is linear in the scale and keeps the strip', () {
      // Natural keyboard at scale 1: 44 strip + 224 rows.
      double h(double s) => keyboardHeightFor(scale: s, naturalH: 268, currentScale: 1, stripH: 44);
      expect(h(1), 268);
      expect(h(1.5), 380);
      expect(h(0.7), closeTo(44 + 224 * 0.7, 1e-9));
    });

    test('the scale that gives a height is clamped to 0.7 to 1.5', () {
      double s(double h) => heightScaleFor(h: h, naturalH: 268, currentScale: 1, stripH: 44);
      expect(s(380), closeTo(1.5, 1e-9));
      expect(s(10), 0.7);
      expect(s(900), 1.5);
      expect(s(268), closeTo(1, 1e-9));
    });

    test('a landscape scale works the same way', () {
      final s = heightScaleFor(h: 44 + 112, naturalH: 44 + 112 * 2, currentScale: 2, stripH: 44);
      expect(s, closeTo(1, 1e-9));
    });
  });

  group('one-handed width', () {
    test('80% by default, never below 60% or closer than 56 dp to the edge', () {
      expect(oneHandedWidth(screenW: 360, fraction: 0.8), closeTo(288, 1e-9));
      expect(oneHandedWidth(screenW: 360, fraction: 0.95), closeTo(304, 1e-9), reason: 'strip keeps 56 dp');
      expect(oneHandedWidth(screenW: 360, fraction: 0.2), closeTo(216, 1e-9));
    });
  });

  group('floating window and rect', () {
    test('the window is 85% of the screen, at most 640 and never smaller than the keyboard', () {
      expect(floatingWindowHeight(screenH: 700, contentH: 316), closeTo(595, 1e-9));
      expect(floatingWindowHeight(screenH: 1200, contentH: 316), 640);
      expect(floatingWindowHeight(screenH: 400, contentH: 316), closeTo(340, 1e-9));
      expect(floatingWindowHeight(screenH: 100, contentH: 50), 120);
    });

    test('the width fraction is between 60% and 100%', () {
      expect(floatingWidthFraction(0.3), 0.6);
      expect(floatingWidthFraction(0.8), 0.8);
      expect(floatingWidthFraction(1.4), 1.0);
    });

    test('x and y are fractions of the free space: 0 is left or top, 1 is right or bottom', () {
      Rect at(double x, double y) => floatingRect(windowW: 360, windowH: 600, width: 288, height: 260, x: x, y: y);
      expect(at(0, 0), const Rect.fromLTWH(0, 0, 288, 260));
      expect(at(1, 1), const Rect.fromLTWH(72, 340, 288, 260));
      expect(at(0.5, 0.5).left, closeTo(36, 1e-9));
      expect(at(1.5, -2).left, closeTo(72, 1e-9), reason: 'out-of-range values clamp');
    });

    test('a rect larger than the window is shrunk to fit', () {
      final r = floatingRect(windowW: 300, windowH: 200, width: 400, height: 260, x: 0.5, y: 0.5);
      expect(r.width, 300);
      expect(r.height, 200);
    });

    test('snapping to the left, right and bottom edges within 16 dp', () {
      const w = 360.0;
      const h = 600.0;
      final near = snapFloatingRect(const Rect.fromLTWH(12, 100, 288, 260), windowW: w, windowH: h);
      expect(near.left, 0);
      final right = snapFloatingRect(const Rect.fromLTWH(60, 100, 288, 260), windowW: w, windowH: h);
      expect(right.left, 72, reason: 'right edge 348 is within 16 dp of 360');
      final bottom = snapFloatingRect(const Rect.fromLTWH(60, 330, 288, 260), windowW: w, windowH: h);
      expect(bottom.top, 340, reason: 'bottom 590 is within 16 dp of 600');
      final far = snapFloatingRect(const Rect.fromLTWH(30, 100, 288, 260), windowW: w, windowH: h);
      expect(far.left, 30, reason: 'more than 16 dp from every edge: no snap');
    });

    test('clamping keeps a dragged rect on screen', () {
      final r = clampRectToWindow(const Rect.fromLTWH(400, -30, 288, 260), windowW: 360, windowH: 600);
      expect(r.left, 72);
      expect(r.top, 0);
    });

    test('fractions are read back from a rect', () {
      const r = Rect.fromLTWH(36, 170, 288, 260);
      expect(floatingXFraction(r, windowW: 360), closeTo(0.5, 1e-9));
      expect(floatingYFraction(r, windowH: 600), closeTo(170 / 340, 1e-9));
      expect(floatingXFraction(const Rect.fromLTWH(0, 0, 360, 260), windowW: 360), 0);
    });
  });
}
