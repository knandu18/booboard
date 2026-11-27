// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/keyboard/modes/space_cursor_drag.dart';
import 'package:booboard/src/keyboard/modes/word_bounds.dart';

/// Feeds the drag total [dx] at a fixed [interval] of milliseconds per event and returns the steps.
class _Feed {
  _Feed() {
    drag = SpaceCursorDrag(move: (steps) => moves.add(steps), tick: () => ticks++, clockMs: () => now);
  }

  late final SpaceCursorDrag drag;
  final List<int> moves = [];
  int ticks = 0;
  int now = 0;
  double total = 0;

  void events(double dpEach, int count, {int intervalMs = 100}) {
    for (var i = 0; i < count; i++) {
      now += intervalMs;
      total += dpEach;
      drag.drag(total, done: false);
    }
  }

  int get sum => moves.fold(0, (s, m) => s + m);
}

void main() {
  group('space-bar cursor drag', () {
    test('slow drags move one character per 12 dp', () {
      final f = _Feed();
      f.events(12.1, 3);
      expect(f.sum, 3);
      expect(f.moves.every((m) => m == 1), isTrue, reason: 'one step per event, never a repeat');
    });

    test('fast drags move one character per 4 dp', () {
      final f = _Feed();
      f.events(16, 2, intervalMs: 16); // 1 dp/ms: the fast end of the scale
      f.events(16, 4, intervalMs: 16);
      // The first event is slow (no speed yet: 1 step); every later one runs at 1 step per 4 dp: 4 steps.
      expect(f.sum, 1 + 4 * 5);
    });

    test('only the difference is applied: going back returns the cursor to where it was', () {
      final f = _Feed();
      f.events(12.1, 3);
      f.events(-12.1, 3);
      expect(f.sum, 0);
    });

    test('a repeated total with no new travel moves nothing', () {
      final f = _Feed();
      f.drag.drag(30, done: false);
      final before = f.moves.length;
      f.now += 100;
      f.drag.drag(30, done: false);
      expect(f.moves.length, before, reason: 'no new travel, no new steps');
    });

    test('a haptic tick every one or two steps', () {
      final f = _Feed();
      f.events(12.1, 6);
      expect(f.sum, 6);
      expect(f.ticks, 3, reason: 'slow drags tick every second step');
    });

    test('done resets the drag so the next touch starts from zero', () {
      final f = _Feed();
      f.events(12.1, 2);
      f.drag.drag(0, done: true);
      f.total = 0;
      f.events(12.1, 1);
      expect(f.sum, 3);
      expect(f.drag.speed, isNonNegative);
    });
  });

  group('whole words before a cursor', () {
    test('one, two and all words', () {
      const text = 'one two three';
      expect(wordStartBefore(text, 13, 0), 13);
      expect(wordStartBefore(text, 13, 1), 8);
      expect(wordStartBefore(text, 13, 2), 4);
      expect(wordStartBefore(text, 13, 3), 0);
      expect(wordStartBefore(text, 13, 9), 0, reason: 'stops at the start of the text');
    });

    test('punctuation is its own run', () {
      const text = 'hi, there!';
      expect(wordStartBefore(text, 10, 1), 9, reason: 'the exclamation mark');
      expect(wordStartBefore(text, 10, 2), 4, reason: 'then the word');
    });

    test('runs of spaces are skipped', () {
      const text = 'a   b';
      expect(wordStartBefore(text, 5, 1), 4);
      expect(wordStartBefore(text, 5, 2), 0);
    });

    test('apostrophes stay inside words', () {
      expect(wordStartBefore("don't go", 8, 1), 6);
      expect(wordStartBefore("don't go", 8, 2), 0);
    });

    test('an emoji is a punctuation run of two units and does not split a word around it', () {
      const text = 'hi \u{1F600}';
      expect(wordStartBefore(text, text.length, 1), 3);
    });

    test('an end past the text is clamped', () {
      expect(wordStartBefore('ab', 99, 1), 0);
    });
  });
}
