// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/japanese/japanese_dictionary.dart';

import '../../../tool/japanese/lexicon_writer.dart';

void main() {
  test('duplicates keep the lowest cost; readings are sorted and grouped', () {
    final lex = buildLexiconBytes(const [
      LexiconEntry(reading: 'ねこ', surface: '猫', lid: 4, rid: 4, cost: 500),
      LexiconEntry(reading: 'ねこ', surface: '猫', lid: 4, rid: 4, cost: 300),
      LexiconEntry(reading: 'あめ', surface: '雨', lid: 4, rid: 4, cost: 700),
      LexiconEntry(reading: 'あめ', surface: '飴', lid: 4, rid: 4, cost: 900),
    ], unknownId: 1);
    final dict = JapaneseDictionary.fromBytes(lex, buildConnectionBytes(2, [0, 0, 0, 0]));
    expect(dict.readingCount, 2);
    expect(dict.entryCount, 3, reason: 'the duplicate 猫 is dropped');
    final neko = dict.readingIndex('ねこ')!;
    expect(dict.entriesOf(neko), [(surface: '猫', lid: 4, rid: 4, cost: 300)]);
    final ame = dict.readingIndex('あめ')!;
    expect(dict.entriesOf(ame).map((e) => e.surface), ['雨', '飴'], reason: 'cheapest first');
    expect(dict.readingStartsWith(dict.firstReadingWithPrefix('あ'), 'あ'), isTrue);
  });

  test('costs are clamped into the 16-bit range; ids and the connection matrix round-trip', () {
    final lex = buildLexiconBytes(const [
      LexiconEntry(reading: 'す', surface: '酢', lid: 3, rid: 2, cost: -5),
    ], unknownId: 1851);
    final conn = buildConnectionBytes(3, [0, 1, 2, 3, 4, 5, 6, 7, 70000]);
    final dict = JapaneseDictionary.fromBytes(lex, conn);
    final e = dict.entryStart(dict.readingIndex('す')!);
    expect(dict.cost(e), 0);
    expect(dict.lid(e), 3);
    expect(dict.rid(e), 2);
    expect(dict.unknownId, 1851);
    expect(dict.connection(2, 2), 65535, reason: 'row 2, column 2 of the 3 by 3 matrix, clamped');
    expect(dict.connection(1, 1), 4);
    expect(dict.connection(0, 1), 1);
    expect(dict.connection(2, 3), 0, reason: 'ids beyond the matrix cost nothing');
  });

  test('the connection matrix must have N by N values', () {
    expect(() => buildConnectionBytes(2, [1, 2, 3]), throwsArgumentError);
  });

  test('an empty lexicon is valid and has no readings', () {
    final dict = JapaneseDictionary.fromBytes(buildLexiconBytes(const [], unknownId: 0), buildConnectionBytes(1, [0]));
    expect(dict.readingCount, 0);
    expect(dict.readingIndex('あ'), isNull);
  });
}
