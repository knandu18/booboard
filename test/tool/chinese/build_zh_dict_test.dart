// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/chinese/s2twp.dart';
import 'package:booboard/src/engine/lang/chinese/zh_dictionary.dart';

import '../../../tool/chinese/zh_dict_writer.dart';
import '../../../tool/chinese/zh_sources.dart';

const String _header = '# Rime dictionary\n# encoding: utf-8\n#\n---\nname: base\nversion: "1"\nsort: by_weight\n...\n';

const String _base =
    '$_header'
    '# a comment with a tab\there\n'
    '你好\tni hao\t5000\n'
    '中国\tzhong guo\t1000\n'
    '稀有\txi you\t10\n'
    '坏\tbad pinyin\t9000\n'
    'ABC\ta b c\t9000\n';

const String _ext =
    '$_header'
    '中国人\tzhong guo ren\t100\n'
    '写了字\txie le zi\t100\n';

const String _chars =
    '$_header'
    '你\tni\t40000000\n'
    '你\tnv\t1000\n'
    '好\thao\t30000000\n'
    '好\thao3\t1\n';

void main() {
  group('rime-ice rows', () {
    test('the header and comments are skipped; each row has text, pinyin and weight', () {
      final rows = parseRimeRows(_base).toList();
      expect(rows.map((r) => r.text), ['你好', '中国', '稀有', '坏', 'ABC']);
      expect(rows.first.pinyin, 'ni hao');
      expect(rows.first.weight, 5000);
    });

    test('a file without a YAML header is read from the first line', () {
      expect(parseRimeRows('你\tni\t5\n').single.weight, 5);
    });

    test('syllables must match the characters and be lower-case letters', () {
      expect(syllablesFor('ni hao', 2), ['ni', 'hao']);
      expect(syllablesFor('ni', 2), isNull);
      expect(syllablesFor('Ni hao', 2), isNull);
      expect(syllablesFor('ni3 hao3', 2), isNull);
    });
  });

  group('entries', () {
    test('words are kept at or above the base weight; characters need one syllable each', () {
      final r = entriesFromRime(base: _base, ext: _ext, chars: _chars, options: const RimeOptions(minBaseWeight: 1000));
      expect(r.baseDropped, 1, reason: '稀有 (10) is below the weight; 坏 and ABC are dropped as not Han words');
      expect(r.words, 4, reason: '你好, 中国, 中国人, 写了字');
      expect(r.characters, 3, reason: '你 ni, 你 nv (a second reading) and 好 hao; 好 hao3 has a digit');
      final texts = r.entries.map((e) => e.text).toList();
      expect(texts, containsAll(['你好', '中国', '中国人', '写了字', '你', '好']));
      expect(texts, isNot(contains('坏')));
      expect(texts, isNot(contains('ABC')));
    });

    test('scores are log10 of each row within its own source', () {
      final r = entriesFromRime(base: _base, ext: _ext, chars: _chars);
      final words = r.entries.where((e) => e.text == '你好').single;
      final total = 5000 + 1000 + 100 + 100;
      expect(words.logP, closeTo(_log10(5000 / total), 0.0001));
      final ch = r.entries.where((e) => e.text == '你' && e.syllables == 'ni').single;
      expect(ch.logP, closeTo(_log10(40000000 / (40000000 + 1000 + 30000000)), 0.0001));
    });

    test('the built file finds what the rows say', () {
      final r = entriesFromRime(base: _base, ext: _ext, chars: _chars);
      final d = ZhDictionary.fromBytes(buildZhDictionary(r.entries));
      expect(d.entriesFor('nihao').single.text, '你好');
      expect(d.entriesFor('nihao').single.syllables, "ni'hao");
      expect(d.entriesFor('ni').map((e) => e.text), ['你']);
      expect(d.entriesForInitials('zg').map((e) => e.text), ['中国']);
      expect(d.entriesForInitials('zgr').map((e) => e.text), ['中国人']);
    });
  });

  group('golden corpus', () {
    test('the sample is the requested size, one "pinyin<TAB>text" per line, with apostrophes', () {
      final lines = goldenCorpus(_base, count: 2, minWeight: 1000);
      expect(lines, ["zhong'guo\t中国", "ni'hao\t你好"], reason: 'sorted by text');
    });

    test('a short list is returned whole', () {
      expect(goldenCorpus(_base, count: 300, minWeight: 1000), hasLength(2));
    });
  });

  group('OpenCC tables', () {
    test('the four tables are written as section, source and first target', () {
      final tsv = s2twpTsv(
        stPhrases: '软件\t軟件 軟體\n',
        stCharacters: '国\t國\n',
        twPhrases: '軟件\t軟體\n',
        twVariants: '裏\t裡\n',
      );
      expect(tsv, 'A\t软件\t軟件\nB\t国\t國\nC\t軟件\t軟體\nD\t裏\t裡\n');
      final c = S2twpConverter.parse(tsv);
      expect(c.convert('软件'), '軟體');
    });
  });
}

double _log10(double x) => math.log(x) / math.ln10;
