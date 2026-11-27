// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/chinese/pinyin_segmenter.dart';

import 'zh_fixture.dart';

void main() {
  final dict = fixtureDictionary();

  group('segment', () {
    test('a word beats its characters when it is more probable', () {
      final s = PinyinSegmenter(dict).segment('nihao');
      expect(s.text, '你好');
      expect(s.reading, "ni'hao");
      expect(s.hasUnknown, isFalse);
    });

    test('a likelier single character beats a rarer word of the same sound', () {
      final s = PinyinSegmenter(dict).segment('xian');
      expect(s.text, '先', reason: '先 (-4) beats 西安 (-5) and 西 + 安 (-6)');
      expect(s.reading, 'xian');
    });

    test('a longer word is found over its parts', () {
      final s = PinyinSegmenter(dict).segment('zhongguoren');
      expect(s.text, '中国人');
      expect(s.reading, "zhong'guo'ren");
    });

    test('unknown letters stay as typed, so every input has a segmentation', () {
      final s = PinyinSegmenter(dict).segment('qx');
      expect(s.hasUnknown, isTrue);
      expect(s.text, 'qx');
      expect(PinyinSegmenter(dict).segment('').units, isEmpty);
    });

    test('a known prefix followed by unknown letters segments both parts', () {
      final s = PinyinSegmenter(dict).segment('nihaoq');
      expect(s.text, '你好q');
      expect(s.hasUnknown, isTrue);
    });
  });

  group('whole matches and prefixes', () {
    test('every entry with the whole key, best first', () {
      final matches = PinyinSegmenter(dict).wholeMatches('xia');
      expect(matches.map((u) => u.entry.text), ['下', '夏']);
      expect(matches.every((u) => u.start == 0 && u.end == 3), isTrue);
      expect(PinyinSegmenter(dict).wholeMatches('qx'), isEmpty);
    });

    test('abbreviations use the initials of multi-syllable entries', () {
      final seg = PinyinSegmenter(dict);
      expect(seg.abbreviations('nh').map((e) => e.text), ['你好']);
      expect(seg.abbreviations('zgr').map((e) => e.text), ['中国人']);
      expect(seg.abbreviations('n'), isEmpty);
    });
  });

  group('fuzzy pinyin', () {
    test('the variants of a run swap one pair at a time', () {
      expect(fuzzyVariants('shi'), contains('si'));
      expect(fuzzyVariants('si'), contains('shi'));
      expect(fuzzyVariants('zhong'), contains('zong'));
      expect(fuzzyVariants('zong'), contains('zhong'));
      expect(fuzzyVariants('an'), contains('ang'));
      expect(fuzzyVariants('ang'), contains('an'));
      expect(fuzzyVariants('ni'), contains('li'));
      expect(fuzzyVariants('xin'), contains('xing'));
    });

    test('a match is whole: zh is not read as z plus h, and an does not split ang', () {
      expect(fuzzyVariants('zhi'), contains('zi'), reason: 'zh becomes z');
      expect(fuzzyVariants('zhi'), isNot(contains('zhhi')));
      expect(fuzzyVariants('ang'), isNot(contains('anng')));
    });

    test('fuzzy matches are off by default and cost a little when on', () {
      expect(PinyinSegmenter(dict).segment('si').text, '思');
      expect(PinyinSegmenter(dict).segment('shi').hasUnknown, isTrue, reason: 'shi is not in the fixture');
      final fuzzy = PinyinSegmenter(dict, fuzzy: true);
      final s = fuzzy.segment('shi');
      expect(s.text, '思');
      expect(s.units.single.fuzzy, isTrue);
      expect(s.score, closeTo(-3.0 - fuzzyPenalty, 0.001));
    });

    test('a fuzzy match loses to an exact one', () {
      final s = PinyinSegmenter(dict, fuzzy: true).segment('zong');
      expect(s.text, '宗');
      expect(s.units.single.fuzzy, isFalse, reason: 'zong is in the fixture');
    });
  });
}
