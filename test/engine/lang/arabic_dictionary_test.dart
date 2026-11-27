// SPDX-License-Identifier: GPL-3.0-or-later
//
// The shipped Arabic and Urdu dictionaries (Wave 3-C): within the size budget, normalised, and
// containing common words.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/dictionary/mdict_lexicon.dart';

final RegExp _notNormal = RegExp('[ـً-ٰٟ‌]|[A-Za-z0-9]');

void main() {
  for (final (lang, common) in [
    ('ar', ['الذي', 'ولكن', 'عندما']),
    ('ur', ['حوالہ', 'انگریزی', 'تاریخ']),
  ]) {
    group(lang, () {
      final file = File('assets/dict/$lang.mdict');

      test('is within the 1.5 MB budget', () {
        expect(file.lengthSync(), lessThanOrEqualTo(1500 * 1024));
      });

      test('has tens of thousands of words, all normalised, and common words', () {
        final lexicon = MdictLexicon.fromBytes(file.readAsBytesSync());
        final words = [for (final e in lexicon.entries()) e.word];
        expect(words.length, greaterThan(20000));
        expect(words.where(_notNormal.hasMatch), isEmpty, reason: 'harakat, tatweel, ZWNJ or Latin in a word');
        final set = words.toSet();
        for (final w in common) {
          expect(set, contains(w), reason: 'common word missing');
        }
      });
    });
  }
}
