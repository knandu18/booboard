// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/chinese/zh_dictionary.dart';

import '../../../../tool/chinese/zh_dict_writer.dart';
import 'zh_fixture.dart';

void main() {
  group('zh.kdict', () {
    test('keys find their entries, best first', () {
      final d = fixtureDictionary();
      expect(texts(d.entriesFor('ni')), ['你', '尼']);
      expect(texts(d.entriesFor('de')), ['的']);
      expect(texts(d.entriesFor('di')), ['的']);
      expect(d.entriesFor('de').single.logP, closeTo(-2.0, 0.001));
    });

    test('a key with apostrophes is looked up without them, and the reading keeps them', () {
      final d = fixtureDictionary();
      final e = d.entriesFor('nihao').single;
      expect(e.text, '你好');
      expect(e.syllables, "ni'hao");
      expect(d.hasKey('nihao'), isTrue);
      expect(d.hasKey('nih'), isFalse, reason: 'a prefix is not a key');
      expect(d.hasKey('nihaoo'), isFalse);
      expect(d.entriesFor(''), isEmpty);
    });

    test('every key is found, including those that sort between others', () {
      final d = fixtureDictionary();
      for (final k in ['xi', 'xia', 'xian', 'zhong', 'zhongguo', 'zhongguoren', 'ruanjian', 'ni', 'nihao']) {
        expect(d.hasKey(k), isTrue, reason: k);
      }
      expect(d.hasKey('zho'), isFalse);
      expect(d.hasKey('zz'), isFalse, reason: 'sorts after every key');
      expect(d.hasKey('a'), isFalse, reason: 'sorts before every key');
      expect(texts(d.entriesFor('xia')), ['下', '夏']);
      expect(texts(d.entriesFor('xian')), ['先', '西安'], reason: '西安 has the key xian too; 先 is likelier');
      expect(texts(d.entriesFor('zhongguoren')), ['中国人']);
    });

    test('initials find the multi-syllable entries', () {
      final d = fixtureDictionary();
      expect(texts(d.entriesForInitials('nh')), ['你好']);
      expect(texts(d.entriesForInitials('zgr')), ['中国人']);
      expect(texts(d.entriesForInitials('zg')), ['中国']);
      expect(d.entriesForInitials('n'), isEmpty, reason: 'single characters are not in the index');
      expect(d.entriesForInitials('qq'), isEmpty);
    });

    test('maxKeyLen and the counts describe the file', () {
      final d = fixtureDictionary();
      expect(d.maxKeyLen, 'zhongguoren'.length);
      expect(d.entryCount, fixtureWords.length);
      expect(d.keyCount, greaterThan(0));
      expect(d.initCount, greaterThan(0));
    });

    test('a file that is not a dictionary is rejected', () {
      expect(() => ZhDictionary.fromBytes(Uint8List(10)), throwsFormatException);
      final good = buildZhDictionary(const [ZhDictEntryInput('你', 'ni', -3)]);
      final badMagic = Uint8List.fromList(good)..[0] = 0x00;
      expect(() => ZhDictionary.fromBytes(badMagic), throwsFormatException);
      final truncated = good.sublist(0, good.length - 1);
      expect(() => ZhDictionary.fromBytes(truncated), throwsFormatException);
    });

    test('an empty dictionary is valid and finds nothing', () {
      final d = ZhDictionary.fromBytes(buildZhDictionary(const []));
      expect(d.entryCount, 0);
      expect(d.entriesFor('ni'), isEmpty);
      expect(d.entriesForInitials('nh'), isEmpty);
    });

    test('duplicates are merged, keeping the higher score', () {
      final stats = ZhDictStats();
      final d = ZhDictionary.fromBytes(
        buildZhDictionary(const [ZhDictEntryInput('你', 'ni', -3), ZhDictEntryInput('你', 'ni', -2.5)], stats: stats),
      );
      expect(stats.duplicates, 1);
      expect(d.entriesFor('ni').single.logP, closeTo(-2.5, 0.001));
    });

    test('bad syllables are refused by the writer', () {
      expect(() => buildZhDictionary(const [ZhDictEntryInput('你', 'Ni', -3)]), throwsArgumentError);
      expect(() => buildZhDictionary(const [ZhDictEntryInput('你', 'ni3', -3)]), throwsArgumentError);
    });
  });
}
