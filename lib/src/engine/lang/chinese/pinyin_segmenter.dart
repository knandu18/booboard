// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A. Splits a run of pinyin letters into dictionary words and characters. A lattice of
// every dictionary key that matches a substring (plus fuzzy variants, when asked) is searched with
// Viterbi, scoring each unit by its log probability. A letter with no match becomes an "unknown"
// unit, so every input has a segmentation and typing never stops.
//
// Nothing here logs; the letters and the text are the user's.
import 'zh_dictionary.dart';

/// log10 probability of a letter that no dictionary entry covers.
const double unknownLogP = -9.0;

/// log10 penalty for a unit matched through a fuzzy substitution (about one tenth as likely).
const double fuzzyPenalty = 1.0;

/// One piece of a segmentation: letters [start, end) of the run, and the entry they spell.
class PinyinUnit {
  const PinyinUnit(this.start, this.end, this.entry, {this.fuzzy = false, this.unknown = false});

  final int start;
  final int end;
  final ZhEntry entry;

  /// Matched through a fuzzy substitution.
  final bool fuzzy;

  /// No dictionary entry; the letters are kept as typed.
  final bool unknown;

  /// The unit's score for Viterbi and ranking (higher is better; a log10 probability).
  double get score => unknown ? unknownLogP : entry.logP - (fuzzy ? fuzzyPenalty : 0);
}

/// The best segmentation of a run of letters.
class PinyinSegmentation {
  const PinyinSegmentation(this.units);

  final List<PinyinUnit> units;

  /// True when some letters had no dictionary entry.
  bool get hasUnknown => units.any((u) => u.unknown);

  /// The text: the units' characters joined; unknown letters stay as typed.
  String get text => units.map((u) => u.entry.text).join();

  /// The segmented pinyin: syllables with apostrophes between the units ("zhong'guo'ren").
  String get reading => units.map((u) => u.entry.syllables).join("'");

  double get score => units.fold<double>(0, (s, u) => s + u.score);
}

/// Fuzzy pinyin substitutions (one per variant): z/zh, c/ch, s/sh, n/l, an/ang, en/eng, in/ing.
/// Each pair is (from, to) and matches only where the replacement does not split a longer sound.
const List<(String, String)> _fuzzyPairs = [
  ('zh', 'z'),
  ('z', 'zh'),
  ('ch', 'c'),
  ('c', 'ch'),
  ('sh', 's'),
  ('s', 'sh'),
  ('n', 'l'),
  ('l', 'n'),
  ('ang', 'an'),
  ('an', 'ang'),
  ('eng', 'en'),
  ('en', 'eng'),
  ('ing', 'in'),
  ('in', 'ing'),
];

/// The single-substitution fuzzy variants of [letters], without duplicates and without the input.
///
/// A match must be whole: "zh" is not read as "z" plus "h", and "an" does not turn "ang" into "ang"
/// plus a stray letter, so each occurrence is checked against what follows it.
List<String> fuzzyVariants(String letters) {
  final out = <String>{};
  for (final (from, to) in _fuzzyPairs) {
    var at = letters.indexOf(from);
    while (at >= 0) {
      final after = at + from.length;
      final nextIsH = after < letters.length && letters[after] == 'h';
      final nextIsG = after < letters.length && letters[after] == 'g';
      final ok = switch (from) {
        'z' || 'c' || 's' => !nextIsH,
        'an' || 'en' || 'in' => !nextIsG,
        'zh' || 'ch' || 'sh' => true,
        _ => true,
      };
      if (ok) {
        final variant = letters.substring(0, at) + to + letters.substring(after);
        if (variant != letters) out.add(variant);
      }
      at = letters.indexOf(from, at + 1);
    }
  }
  return out.toList();
}

/// Segments pinyin letters over a [ZhDictionary]. Cheap to make; keeps no state between calls.
class PinyinSegmenter {
  PinyinSegmenter(this.dictionary, {this.fuzzy = false});

  final ZhDictionary dictionary;

  /// Also match fuzzy substitutions (settings.chinese.fuzzyPinyin).
  final bool fuzzy;

  /// The longest run of letters to look up: the dictionary's longest key, capped.
  int get _maxLen {
    final m = dictionary.maxKeyLen;
    return m < 1 ? 1 : (m > 32 ? 32 : m);
  }

  /// Every unit that matches a substring of [letters], by its start, including unknown letters.
  List<List<PinyinUnit>> _lattice(String letters) {
    final n = letters.length;
    final byStart = List<List<PinyinUnit>>.generate(n, (_) => <PinyinUnit>[], growable: false);
    final maxLen = _maxLen;
    for (var i = 0; i < n; i++) {
      final limit = i + maxLen < n ? i + maxLen : n;
      for (var j = i + 1; j <= limit; j++) {
        final sub = letters.substring(i, j);
        for (final e in dictionary.entriesFor(sub)) {
          byStart[i].add(PinyinUnit(i, j, e));
        }
        if (fuzzy) {
          for (final v in fuzzyVariants(sub)) {
            for (final e in dictionary.entriesFor(v)) {
              byStart[i].add(PinyinUnit(i, j, e, fuzzy: true));
            }
          }
        }
      }
      byStart[i].add(
        PinyinUnit(i, i + 1, ZhEntry(text: letters[i], syllables: letters[i], logP: unknownLogP), unknown: true),
      );
    }
    return byStart;
  }

  /// The most probable segmentation of [letters] (lower-case ASCII, no apostrophes). Empty input gives
  /// an empty segmentation.
  PinyinSegmentation segment(String letters) {
    final n = letters.length;
    if (n == 0) return const PinyinSegmentation([]);
    final byStart = _lattice(letters);
    final best = List<double>.filled(n + 1, double.negativeInfinity);
    final back = List<PinyinUnit?>.filled(n + 1, null);
    best[0] = 0;
    for (var i = 0; i < n; i++) {
      final here = best[i];
      if (here == double.negativeInfinity) continue;
      for (final u in byStart[i]) {
        final cand = here + u.score;
        if (cand > best[u.end]) {
          best[u.end] = cand;
          back[u.end] = u;
        }
      }
    }
    final units = <PinyinUnit>[];
    var at = n;
    while (at > 0) {
      final u = back[at]!;
      units.add(u);
      at = u.start;
    }
    return PinyinSegmentation(units.reversed.toList(growable: false));
  }

  /// Dictionary entries that spell all of [letters] as one key (fuzzy variants included, marked), best
  /// first. Used for whole-buffer candidates and for prefixes.
  List<PinyinUnit> wholeMatches(String letters) {
    if (letters.isEmpty) return const [];
    final out = <PinyinUnit>[for (final e in dictionary.entriesFor(letters)) PinyinUnit(0, letters.length, e)];
    if (fuzzy) {
      for (final v in fuzzyVariants(letters)) {
        for (final e in dictionary.entriesFor(v)) {
          out.add(PinyinUnit(0, letters.length, e, fuzzy: true));
        }
      }
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  /// Entries whose initials are [letters] ("nh" for 你好, "zgr" for 中国人), best first.
  List<ZhEntry> abbreviations(String letters) => letters.length < 2 ? const [] : dictionary.entriesForInitials(letters);
}
