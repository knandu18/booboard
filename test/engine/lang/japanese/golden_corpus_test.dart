// SPDX-License-Identifier: GPL-3.0-or-later
//
// Golden corpus (300 items from Tatoeba's furigana transcriptions, CC BY 2.0 FR; see golden_ja.tsv and
// tool/japanese/build_golden_tatoeba.py). Needs the staged dict-ja-mozc pack
// (tool/packs/japanese/stage_mozc.ps1); skipped when it is not there, or when BOOBOARD_JA_DICT names
// another folder. Thresholds from the brief: top-1 sentence accuracy >= 70% (kana/kanji spelling variants
// count), per-segment top-5 >= 95% (whole kanji words only).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/japanese/japanese_dictionary.dart';
import 'package:booboard/src/engine/lang/japanese/lattice.dart';

String? _packDir() {
  final env = Platform.environment['BOOBOARD_JA_DICT'];
  if (env != null && File('$env/japanese.lex.gz').existsSync()) return env;
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home == null) return null;
  final staged = '$home/.booboard/packs/staging/dict-ja-mozc';
  return File('$staged/japanese.lex.gz').existsSync() ? staged : null;
}

void main() {
  final dir = _packDir();
  final skip = dir == null ? 'needs the staged dict-ja-mozc pack (tool/packs/japanese/stage_mozc.ps1)' : null;

  test(
    'golden corpus: top-1 sentence accuracy and per-segment top-5',
    skip: skip,
    timeout: const Timeout(Duration(minutes: 5)),
    () {
      final dict = JapaneseDictionary.load(dir!);
      final conv = JapaneseConverter(dictionary: dict);
      final rows = File('test/engine/lang/japanese/golden_ja.tsv')
          .readAsLinesSync()
          .where((l) => l.isNotEmpty && !l.startsWith('#'))
          .toList();
      expect(rows.length, 300);

      var exact = 0;
      var variant = 0;
      var segments = 0;
      var segmentsTop5 = 0;
      final misses = <String>[];
      for (final row in rows) {
        final cols = row.split('\t');
        final reading = cols[0];
        final expected = cols[1];
        final got = conv.convert(reading).map((s) => s.surface).join();
        if (got == expected) {
          exact++;
        } else if (_spellingVariant(got, expected)) {
          variant++;
        } else if (misses.length < 12) {
          misses.add('$expected  <-  $got');
        }
        for (final piece in cols[3].split(' ').where((p) => p.isNotEmpty)) {
          final eq = piece.indexOf('=');
          final r = piece.substring(0, eq);
          final s = piece.substring(eq + 1);
          // A one-kanji piece is often a verb or adjective stem (い=言 in 言う), which is never a word
          // of its own in the dictionary; only whole kanji words count here.
          if (s.length < 2) continue;
          segments++;
          final top5 = conv.span(r, 0, r.length).candidates.take(5);
          if (top5.contains(s)) segmentsTop5++;
        }
      }
      final strict = exact / rows.length;
      // Japanese writes many words either way (下さい or ください, 良い or よい); both are right.
      final top1 = (exact + variant) / rows.length;
      final seg = segmentsTop5 / segments;
      stdout.writeln(
        'golden: top-1 ${(top1 * 100).toStringAsFixed(1)}% (${exact + variant}/${rows.length}; '
        'exact ${(strict * 100).toStringAsFixed(1)}%), '
        'segment top-5 ${(seg * 100).toStringAsFixed(1)}% ($segmentsTop5/$segments)',
      );
      for (final m in misses) {
        stdout.writeln('  miss: $m');
      }
      expect(top1, greaterThanOrEqualTo(0.70), reason: 'top-1 sentence accuracy');
      expect(seg, greaterThanOrEqualTo(0.95), reason: 'per-segment top-5');
    },
  );
}

final RegExp _kanji = RegExp(r'[々一-鿿]');

/// The same sentence with some words in kana instead of kanji (or the other way round): the kanji of
/// one, in order, are a subsequence of the other's. The reading is the same by construction.
bool _spellingVariant(String a, String b) {
  final ka = [
    for (final c in a.split(''))
      if (_kanji.hasMatch(c)) c,
  ];
  final kb = [
    for (final c in b.split(''))
      if (_kanji.hasMatch(c)) c,
  ];
  bool sub(List<String> x, List<String> y) {
    var i = 0;
    for (final c in y) {
      if (i < x.length && x[i] == c) i++;
    }
    return i == x.length;
  }

  return sub(ka, kb) || sub(kb, ka);
}
