// SPDX-License-Identifier: GPL-3.0-or-later
//
// A tiny Japanese dictionary for the tests, written with the real pack writer (tool/japanese). Ids:
// 0 BOS/EOS, 1 unknown word (名詞,一般), 2 particle, 3 adjective, 4 noun. Costs are chosen so the
// intended segmentation is the cheapest path.
import 'dart:typed_data';

import 'package:booboard/src/engine/lang/japanese/japanese_dictionary.dart';
import 'package:booboard/src/engine/lang/japanese/japanese_learning.dart';

import '../../../../tool/japanese/lexicon_writer.dart';

const int _n = 5;

const List<LexiconEntry> fixtureEntries = [
  LexiconEntry(reading: 'きょう', surface: '今日', lid: 4, rid: 4, cost: 3000),
  LexiconEntry(reading: 'は', surface: 'は', lid: 2, rid: 2, cost: 1500),
  LexiconEntry(reading: 'いい', surface: 'いい', lid: 3, rid: 3, cost: 2500),
  LexiconEntry(reading: 'いい', surface: '良い', lid: 3, rid: 3, cost: 2600),
  LexiconEntry(reading: 'てんき', surface: '天気', lid: 4, rid: 4, cost: 3000),
  LexiconEntry(reading: 'です', surface: 'です', lid: 2, rid: 2, cost: 1500),
  LexiconEntry(reading: 'にほんご', surface: '日本語', lid: 4, rid: 4, cost: 3500),
  LexiconEntry(reading: 'を', surface: 'を', lid: 2, rid: 2, cost: 1400),
  LexiconEntry(reading: 'べんきょう', surface: '勉強', lid: 4, rid: 4, cost: 3200),
  LexiconEntry(reading: 'かご', surface: '籠', lid: 4, rid: 4, cost: 5000),
  LexiconEntry(reading: 'かご', surface: 'カゴ', lid: 4, rid: 4, cost: 2900),
];

/// The fixture dictionary, read back from the bytes the builder writes.
JapaneseDictionary fixtureDictionary() {
  final lex = buildLexiconBytes(fixtureEntries, unknownId: 1);
  final conn = buildConnectionBytes(_n, List<int>.filled(_n * _n, 10));
  return JapaneseDictionary.fromBytes(lex, conn);
}

/// Learned picks as a store (bytes round trip not needed here).
JapaneseLearning emptyLearning() => JapaneseLearning();

Uint8List fixtureLexBytes() => buildLexiconBytes(fixtureEntries, unknownId: 1);
