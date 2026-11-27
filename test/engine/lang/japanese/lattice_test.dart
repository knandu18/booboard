// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/japanese/japanese_dictionary.dart';
import 'package:booboard/src/engine/lang/japanese/japanese_learning.dart';
import 'package:booboard/src/engine/lang/japanese/lattice.dart';

import 'japanese_fixture.dart';

String _joined(List<JapaneseSegment> segs) => segs.map((s) => s.surface).join('|');

void main() {
  final dict = fixtureDictionary();

  group('dictionary format', () {
    test('reads back readings, entries and ids', () {
      expect(dict.readingCount, greaterThan(0));
      expect(dict.unknownId, 1);
      final r = dict.readingIndex('いい')!;
      expect(dict.readingAt(r), 'いい');
      expect(dict.entriesOf(r).map((e) => e.surface), ['いい', '良い']);
      expect(dict.readingIndex('ねこ'), isNull);
      expect(dict.connection(2, 3), 10);
    });

    test('prefix search finds the readings that start with the prefix', () {
      final first = dict.firstReadingWithPrefix('てん');
      expect(dict.readingStartsWith(first, 'てん'), isTrue);
      expect(dict.readingAt(first), 'てんき');
    });

    test('a file that is not the format is rejected', () {
      expect(
        () => JapaneseDictionary.fromBytes(Uint8List.fromList(List.filled(40, 0)), Uint8List(8)),
        throwsFormatException,
      );
    });
  });

  group('conversion', () {
    test('きょうはいいてんきです converts to 今日はいい天気です', () {
      final segs = JapaneseConverter(dictionary: dict).convert('きょうはいいてんきです');
      expect(_joined(segs), '今日|は|いい|天気|です');
      expect(segs.map((s) => s.surface).join(), '今日はいい天気です');
    });

    test('dictionary words rank by cost, and kana forms are offered too', () {
      final seg = JapaneseConverter(dictionary: dict).span('かご', 0, 2);
      expect(seg.candidates, containsAll(['カゴ', '籠', 'かご']));
      expect(seg.candidates.indexOf('カゴ'), lessThan(seg.candidates.indexOf('籠')), reason: 'cheaper first');
      expect(seg.dictionarySurfaces, containsAll(['カゴ', '籠']));
      expect(seg.dictionarySurfaces, isNot(contains('かご')));
    });

    test('without a dictionary the reading is one kana segment, with katakana', () {
      final segs = JapaneseConverter().convert('にほんご');
      expect(segs, hasLength(1));
      expect(segs.single.candidates, ['にほんご', 'ニホンゴ']);
    });

    test('ASCII readings also get full-width forms', () {
      final forms = JapaneseConverter.formsOf('ab');
      expect(forms, containsAll(['ab', 'ａｂ']));
    });

    test('learned picks rank first for their reading', () {
      final learning = JapaneseLearning();
      for (var i = 0; i < 5; i++) {
        learning.learn('かご', '籠');
      }
      final converter = JapaneseConverter(dictionary: dict, learning: learning);
      final seg = converter.span('かご', 0, 2);
      expect(seg.candidates.first, '籠');
      final path = converter.convert('かご');
      expect(path.single.surface, '籠', reason: 'the learned bonus outweighs the cost difference');
    });

    test('predictions are dictionary words that start with the reading, best first', () {
      final p = JapaneseConverter(dictionary: dict).predict('い');
      expect(p.map((e) => e.surface), ['いい', '良い']);
      expect(JapaneseConverter().predict('い'), isEmpty);
    });
  });

  group('segments', () {
    test('a segment that is not in the dictionary is still converted, one character at a time', () {
      final segs = JapaneseConverter(dictionary: dict).convert('ぬ');
      expect(segs.map((s) => s.reading), ['ぬ']);
      expect(segs.single.surface, 'ぬ');
    });

    test('a chosen segment reports whether it is a dictionary word', () {
      final segs = JapaneseConverter(dictionary: dict).convert('きょう');
      expect(segs.single.choseDictionary, isTrue);
    });
  });
}
