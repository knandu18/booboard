// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A. Reads the rime-ice dictionaries (GPL-3.0) and the OpenCC tables (Apache-2.0) and
// turns them into dictionary entries for zh_dict_writer.dart. Pure functions over text, so tests can
// use small fixtures.
//
// rime-ice source files (Rime dictionary format; a YAML header ends with a line `...`):
//   base.dict.yaml   `word<TAB>pinyin<TAB>weight` (words of two or more characters)
//   ext.dict.yaml    `word<TAB>pinyin<TAB>weight` (three characters or more, flat weights)
//   8105.dict.yaml   `char<TAB>pinyin<TAB>weight` (the 8105 common characters, one row per reading)
//   tencent.dict.yaml has no pinyin and is not used (see docs/notices/chinese.md).
//
// Weights are per source, so each row's score is log10(weight / total weight of its source).
// Words and characters are normalised separately, so the segmenter compares like with like.
import 'dart:math' as math;

import 'zh_dict_writer.dart';

/// A parsed Rime dictionary row.
class RimeRow {
  const RimeRow(this.text, this.pinyin, this.weight);

  final String text;
  final String pinyin;
  final int weight;
}

final RegExp _han = RegExp(r'^\p{Script=Han}+$', unicode: true);
final RegExp _syllable = RegExp(r'^[a-z]+$');

/// Rows of a Rime dictionary: every line with tab-separated columns after the YAML header.
/// Lines that do not parse are skipped.
Iterable<RimeRow> parseRimeRows(String contents) sync* {
  final lines = contents.split('\n');
  var i = 0;
  // Skip the header: comments, then the YAML block up to a line `...`.
  if (lines.any((l) => l.trim() == '...')) {
    while (i < lines.length && lines[i].trim() != '...') {
      i++;
    }
    i++;
  }
  for (; i < lines.length; i++) {
    final line = lines[i].trimRight();
    if (line.isEmpty || line.startsWith('#')) continue;
    final cols = line.split('\t');
    if (cols.length != 3) continue;
    final weight = int.tryParse(cols[2].trim());
    if (weight == null) continue;
    yield RimeRow(cols[0].trim(), cols[1].trim(), weight);
  }
}

/// The syllables of [pinyin] when every one is lower-case ASCII letters and there are [characters]
/// of them; null otherwise.
List<String>? syllablesFor(String pinyin, int characters) {
  final parts = pinyin.split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.length != characters) return null;
  for (final p in parts) {
    if (!_syllable.hasMatch(p)) return null;
  }
  return parts;
}

/// Options for [entriesFromRime].
class RimeOptions {
  const RimeOptions({this.minBaseWeight = 1000});

  /// Rows of base.dict.yaml below this weight are left out (the budget is about 600k words).
  final int minBaseWeight;
}

/// The result of [entriesFromRime], with counts for the report.
class RimeEntries {
  RimeEntries(this.entries, this.words, this.characters, this.baseDropped, this.extRows, this.charRows);

  final List<ZhDictEntryInput> entries;
  final int words;
  final int characters;
  final int baseDropped;
  final int extRows;
  final int charRows;
}

/// Builds dictionary entries from the three Rime files (contents, not paths).
RimeEntries entriesFromRime({
  required String base,
  required String ext,
  required String chars,
  RimeOptions options = const RimeOptions(),
}) {
  final words = <(String, String, int)>[];
  var baseDropped = 0;
  for (final r in parseRimeRows(base)) {
    if (r.weight < options.minBaseWeight) {
      baseDropped++;
      continue;
    }
    final w = _wordOrNull(r);
    if (w != null) words.add(w);
  }
  var extRows = 0;
  for (final r in parseRimeRows(ext)) {
    extRows++;
    final w = _wordOrNull(r);
    if (w != null) words.add(w);
  }
  final charList = <(String, String, int)>[];
  var charRows = 0;
  for (final r in parseRimeRows(chars)) {
    charRows++;
    if (r.text.runes.length != 1) continue;
    final s = _wordOrNull(r);
    if (s != null) charList.add(s);
  }

  final wordTotal = words.fold<double>(0, (s, w) => s + w.$3);
  final charTotal = charList.fold<double>(0, (s, c) => s + c.$3);
  final out = <ZhDictEntryInput>[
    for (final (text, syl, weight) in words) ZhDictEntryInput(text, syl, _log10(weight, wordTotal)),
    for (final (text, syl, weight) in charList) ZhDictEntryInput(text, syl, _log10(weight, charTotal)),
  ];
  return RimeEntries(out, words.length, charList.length, baseDropped, extRows, charRows);
}

(String, String, int)? _wordOrNull(RimeRow r) {
  if (!_han.hasMatch(r.text) || r.weight <= 0) return null;
  final syl = syllablesFor(r.pinyin, r.text.runes.length);
  if (syl == null) return null;
  return (r.text, syl.join("'"), r.weight);
}

double _log10(int weight, double total) => math.log(weight / total) / math.ln10;

/// The golden corpus: [count] common words of two to four characters (weight at least [minWeight]),
/// chosen evenly across the sorted list so the sample is not all one topic. One line each:
/// `pinyin<TAB>text`, with apostrophes at syllable boundaries.
List<String> goldenCorpus(String base, {int count = 300, int minWeight = 5000}) {
  final seen = <String>{};
  final valid = <(String, String)>[];
  for (final r in parseRimeRows(base)) {
    final n = r.text.runes.length;
    if (r.weight < minWeight || n < 2 || n > 4) continue;
    final w = _wordOrNull(r);
    if (w == null || !seen.add(w.$1)) continue;
    valid.add((w.$2, w.$1));
  }
  valid.sort((a, b) => a.$2.compareTo(b.$2));
  if (valid.length <= count) return [for (final (p, t) in valid) '$p\t$t'];
  final step = valid.length / count;
  final out = <String>[];
  for (var i = 0; i < count; i++) {
    final (p, t) = valid[(i * step).floor()];
    out.add('$p\t$t');
  }
  return out;
}

/// The OpenCC tables for the pack, one `section<TAB>from<TAB>to` line per entry (see s2twp.dart).
String s2twpTsv({
  required String stPhrases,
  required String stCharacters,
  required String twPhrases,
  required String twVariants,
}) {
  final out = StringBuffer();
  void table(String section, String contents) {
    for (final line in contents.split('\n')) {
      final tab = line.indexOf('\t');
      if (tab <= 0) continue;
      final from = line.substring(0, tab).trim();
      final targets = line.substring(tab + 1).trim().split(RegExp(r'\s+'));
      final to = targets.first;
      if (from.isEmpty || to.isEmpty) continue;
      out.write('$section\t$from\t$to\n');
    }
  }

  table('A', stPhrases);
  table('B', stCharacters);
  table('C', twPhrases);
  table('D', twVariants);
  return out.toString();
}
