// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/gesture/gesture_math.dart';
import 'package:booboard/src/engine/gesture/template_index.dart';

import 'gesture_test_support.dart';

void main() {
  group('resamplePolyline', () {
    test('a straight line becomes 64 equidistant points and reports its length', () {
      final xs = Float64List.fromList([0, 10, 100]);
      final ys = Float64List.fromList([0, 0, 0]);
      final ox = Float64List(kGesturePoints), oy = Float64List(kGesturePoints);
      final length = resamplePolyline(xs, ys, 3, kGesturePoints, ox, oy);
      expect(length, closeTo(100, 1e-9));
      expect(ox.first, 0);
      expect(ox.last, 100);
      for (var i = 1; i < kGesturePoints; i++) {
        expect(ox[i] - ox[i - 1], closeTo(100 / 63, 1e-9));
        expect(oy[i], 0);
      }
    });

    test('keeps equal arc-length spacing around a corner', () {
      final xs = Float64List.fromList([0, 60, 60]);
      final ys = Float64List.fromList([0, 0, 80]);
      final ox = Float64List(kGesturePoints), oy = Float64List(kGesturePoints);
      final length = resamplePolyline(xs, ys, 3, kGesturePoints, ox, oy);
      expect(length, closeTo(140, 1e-9));
      final step = 140 / 63;
      for (var i = 1; i < kGesturePoints; i++) {
        final d = math.sqrt(math.pow(ox[i] - ox[i - 1], 2) + math.pow(oy[i] - oy[i - 1], 2));
        // Chords across the corner are slightly shorter than the arc step.
        expect(d, lessThanOrEqualTo(step + 1e-9));
        expect(d, greaterThan(step * 0.6));
      }
      expect(ox.last, 60);
      expect(oy.last, 80);
    });

    test('degenerate inputs do not throw', () {
      final ox = Float64List(kGesturePoints), oy = Float64List(kGesturePoints);
      expect(resamplePolyline(Float64List(0), Float64List(0), 0, kGesturePoints, ox, oy), 0);
      expect(resamplePolyline(Float64List.fromList([5]), Float64List.fromList([7]), 1, kGesturePoints, ox, oy), 0);
      expect(ox.every((v) => v == 5) && oy.every((v) => v == 7), isTrue);
      expect(
        resamplePolyline(Float64List.fromList([1, 1]), Float64List.fromList([2, 2]), 2, kGesturePoints, ox, oy),
        0,
      );
    });
  });

  group('GestureKeys.foldWord', () {
    late GestureKeys keys;
    setUp(() {
      final geo = qwertyGeometry();
      final chars = geo.keys.keys.toList();
      final rects = <double>[];
      for (final c in chars) {
        final r = geo.keys[c]!;
        rects.addAll([r.left, r.top, r.right, r.bottom]);
      }
      keys = GestureKeys(chars: chars, rects: Float64List.fromList(rects), keyWidth: geo.keyWidth);
    });

    String fold(String word) {
      final out = Int32List(48);
      final n = keys.foldWord(word, out);
      if (n < 0) return '<skip>';
      return [for (var i = 0; i < n; i++) keys.chars[out[i]]].join();
    }

    test('collapses repeats, drops apostrophes and hyphens', () {
      expect(fold('hello'), 'helo');
      expect(fold("don't"), 'dont');
      expect(fold('don’t'), 'dont');
      expect(fold('e-mail'), 'email');
      expect(fold('aaa'), 'a');
    });

    test('maps accented letters to their base key', () {
      expect(fold('café'), 'cafe');
      expect(fold('naïve'), 'naive');
      expect(fold('señor'), 'senor');
      expect(fold('straße'), 'strase');
      expect(fold('łódź'), 'lodz');
      expect(fold('crème'), 'creme');
    });

    test('skips words with characters that have no key', () {
      expect(fold('नमस्ते'), '<skip>');
      expect(fold('東京'), '<skip>');
      expect(fold('a1'), '<skip>');
    });

    test('an apostrophe between equal letters still collapses them', () {
      expect(fold("ss's"), 's');
    });
  });

  test('isLetterKey accepts letters in any script and rejects punctuation and digits', () {
    expect(GestureKeys.isLetterKey('a'), isTrue);
    expect(GestureKeys.isLetterKey('ñ'), isTrue);
    expect(GestureKeys.isLetterKey('щ'), isTrue);
    expect(GestureKeys.isLetterKey('ش'), isTrue);
    expect(GestureKeys.isLetterKey(','), isFalse);
    expect(GestureKeys.isLetterKey('1'), isFalse);
    expect(GestureKeys.isLetterKey('ab'), isFalse);
    expect(GestureKeys.isLetterKey(''), isFalse);
  });

  test('neighbours returns keys within the radius and always the nearest', () {
    final geo = qwertyGeometry();
    final chars = geo.keys.keys.toList();
    final rects = <double>[];
    for (final c in chars) {
      final r = geo.keys[c]!;
      rects.addAll([r.left, r.top, r.right, r.bottom]);
    }
    final keys = GestureKeys(chars: chars, rects: Float64List.fromList(rects), keyWidth: geo.keyWidth);
    final out = Int32List(16);
    final g = geo.centerOf('g')!;
    final n = keys.neighbours(g.dx, g.dy, 1.2 * geo.keyWidth, out);
    final found = {for (var i = 0; i < n; i++) keys.chars[out[i]]};
    expect(found, containsAll(['g', 'f', 'h']));
    expect(found, isNot(contains('p')));
    // Far outside the keyboard: still the nearest key.
    final far = keys.neighbours(-500, -500, 10, out);
    expect(far, 1);
    expect(keys.chars[out[0]], 'q');
  });
}
