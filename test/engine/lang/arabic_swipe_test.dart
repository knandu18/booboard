// SPDX-License-Identifier: GPL-3.0-or-later
//
// Swipe typing on the Arabic layout (Wave 3-C): synthetic swipes over the 50 most common Arabic
// words of assets/dict/ar.mdict, decoded by the existing (script-agnostic) gesture engine.
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/engine/dictionary/mdict_lexicon.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/keyboard/layout/layout_repository.dart';

import '../gesture/gesture_test_support.dart';

/// Key rectangles from the layout's rows: each row is 12.5 key units wide, as in the layout file.
KeyboardGeometry _arabicGeometry(KeyboardLayoutDef layout, {double width = 1080, double rowHeight = 150}) {
  final pitch = width / 12.5;
  final keys = <String, Rect>{};
  for (var r = 0; r < 3; r++) {
    final row = layout.rows[r];
    var x = row.padding * pitch;
    for (final k in row.keys) {
      final w = k.width * pitch;
      final output = k.output;
      if (k.isCharacter && output != null) {
        keys[output] = Rect.fromLTWH(x + 4, r * rowHeight + 6, w - 8, rowHeight - 12);
      }
      x += w;
    }
  }
  return KeyboardGeometry(layoutId: 'arabic-test', size: Size(width, rowHeight * 3), keys: keys);
}

void main() {
  test('swipe accuracy on 50 common Arabic words (synthetic paths)', () {
    final layout = LayoutVariants.parse(File('assets/layouts/arabic.json').readAsStringSync());
    final geometry = _arabicGeometry(layout);
    final lexicon = MdictLexicon.fromBytes(File('assets/dict/ar.mdict').readAsBytesSync());

    // The most probable words of two to six letters that the layout can type.
    final words = <String>[];
    for (final e in lexicon.entries()) {
      final w = e.word;
      if (w.runes.length < 2 || w.runes.length > 6) continue;
      if (!w.split('').every(geometry.keys.containsKey)) continue;
      words.add(w);
      if (words.length == 50) break;
    }
    expect(words, hasLength(50));

    final engine = buildEngine(geometry, [lexicon]);
    for (final noise in [0.25, 0.35]) {
      final synth = SwipeSynth(geometry, seed: 5, noise: noise);
      var top1 = 0, top3 = 0, n = 0;
      final missed = <String>[];
      for (final w in words) {
        final path = synth.generate(w);
        if (path == null) continue;
        final ranked = [for (final c in engine.decode(toXy(path), maxResults: 6)) c.word];
        n++;
        if (ranked.isNotEmpty && ranked.first == w) top1++;
        if (ranked.take(3).contains(w)) {
          top3++;
        } else {
          missed.add(w);
        }
      }
      // ignore: avoid_print
      print(
        'arabic swipe noise $noise over $n words: top1=${(top1 / n * 100).toStringAsFixed(1)}% '
        'top3=${(top3 / n * 100).toStringAsFixed(1)}% missed top3: ${missed.join(' ')}',
      );
      if (noise == 0.25) {
        expect(n, 50);
        expect(top3 / n, greaterThanOrEqualTo(0.5));
      }
    }
  });
}
