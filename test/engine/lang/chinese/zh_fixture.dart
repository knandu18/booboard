// SPDX-License-Identifier: GPL-3.0-or-later
//
// A few hundred words' worth of fixture for the Chinese tests: a tiny zh.kdict built with the real
// writer, and a tiny s2twp.tsv. The scores are hand-picked log10 probabilities.
import 'package:booboard/src/engine/lang/chinese/s2twp.dart';
import 'package:booboard/src/engine/lang/chinese/zh_dictionary.dart';
import 'package:booboard/src/engine/lang/chinese/zh_lexicon.dart';

import '../../../../tool/chinese/zh_dict_writer.dart';

/// The fixture words: text, syllables, log10 probability.
const List<(String, String, double)> fixtureWords = [
  // single characters
  ('你', 'ni', -3.0),
  ('尼', 'ni', -4.0),
  ('好', 'hao', -3.0),
  ('号', 'hao', -3.5),
  ('西', 'xi', -3.0),
  ('安', 'an', -3.0),
  ('先', 'xian', -4.0),
  ('中', 'zhong', -3.0),
  ('国', 'guo', -3.0),
  ('人', 'ren', -3.0),
  ('思', 'si', -3.0),
  ('宗', 'zong', -3.5),
  ('帮', 'bang', -4.0),
  ('三', 'san', -3.0),
  ('下', 'xia', -3.0),
  ('夏', 'xia', -3.5),
  ('的', 'de', -2.0),
  ('的', 'di', -4.5),
  ('软', 'ruan', -3.5),
  ('件', 'jian', -3.5),
  ('體', 'ti', -4.0),
  // words
  ('你好', "ni'hao", -5.0),
  ('西安', "xi'an", -5.0),
  ('中国', "zhong'guo", -4.5),
  ('中国人', "zhong'guo'ren", -5.5),
  ('软件', "ruan'jian", -5.0),
  ('下雨', "xia'yu", -5.0),
];

/// Simplified to Traditional for the fixture, in the `s2twp.tsv` format.
const String fixtureTsv =
    'A\t软件\t軟件\n'
    'B\t国\t國\n'
    'B\t软\t軟\n'
    'B\t件\t件\n'
    'C\t軟件\t軟體\n'
    'D\t裏\t裡\n';

/// The fixture as zh.kdict bytes, through the real writer.
ZhDictionary fixtureDictionary() {
  final bytes = buildZhDictionary([for (final (t, s, p) in fixtureWords) ZhDictEntryInput(t, s, p)]);
  return ZhDictionary.fromBytes(bytes);
}

/// The fixture pack, installed into a lexicon.
ZhLexicon fixtureLexicon() {
  final lexicon = ZhLexicon();
  lexicon.install(
    ZhLoaded(
      dictionary: fixtureDictionary(),
      converter: S2twpConverter.parse(fixtureTsv),
      pack: const ZhPackInfo(id: 'dict-zh-fixture', name: 'Fixture', sizeBytes: 1),
    ),
  );
  return lexicon;
}

/// The texts of [entries], in order.
List<String> texts(Iterable<ZhEntry> entries) => [for (final e in entries) e.text];
