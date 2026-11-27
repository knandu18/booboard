// SPDX-License-Identifier: GPL-3.0-or-later
//
// The Indic dictionary step: a .combined list written as tool/indic/build_indic_dict.dart reads it, through the
// shared MDICT writer, keeps three-letter Devanagari words (which tool/build_dictionary.dart's upper-case
// filter drops, since Indic scripts have no case).
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/dictionary/mdict_lexicon.dart';
import 'package:booboard/src/engine/dictionary/mdict_writer.dart';

void main() {
  test('a Devanagari word list keeps the short words and their order', () {
    // Same frequency-to-probability mapping as build_indic_dict.dart.
    const fMax = 244;
    double logProb(int f) => -3.0 - (fMax - f) * 0.075;
    final source = DictSource(
      language: 'hi',
      words: [DictWord('है', logProb(244)), DictWord('और', logProb(230)), DictWord('नमस्ते', logProb(120))],
      foldAccents: false,
    );
    final bytes = buildMdict(source, compress: true);
    final lexicon = MdictLexicon.fromBytes(inflateMdict(Uint8List.fromList(bytes)));
    expect(lexicon.size, 3);
    expect(lexicon.logProb('है'), isNotNull);
    expect(lexicon.logProb('और'), isNotNull);
    expect(lexicon.logProb('नमस्ते')!, lessThan(lexicon.logProb('है')!));
  });
}
