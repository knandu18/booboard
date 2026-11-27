// SPDX-License-Identifier: GPL-3.0-or-later
//
// What BooBoard has learned about one language from the user's typing: personal
// word and word-pair counts with time decay, plus the "never suggest" list.
// Persisted only through SecureBlobStore (encrypted), as JSON.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../contracts.dart';

const int _kFormatVersion = 1;

/// Counts lose half their weight every this many days.
const double kLearnHalfLifeDays = 90;
const int kMaxLearnedWords = 6000;
const int kMaxLearnedBigrams = 12000;

/// A word becomes "known" after this many commits.
const int kCommitsToKnow = 2;

int dayNumber(DateTime time) => time.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

double _decay(int ageDays) => ageDays <= 0 ? 1.0 : math.pow(0.5, ageDays / kLearnHalfLifeDays).toDouble();

class LearnedWord {
  LearnedWord(this.surface, {this.commits = 0, this.score = 0, this.day = 0, this.novel = false});

  String surface;

  /// Total commits (not decayed): decides when a new word becomes known.
  int commits;

  /// Decayed usage score as of [day].
  double score;
  int day;

  /// Not in any dictionary when first seen.
  bool novel;

  double scoreAt(int today) => score * _decay(today - day);
}

class LearnedBigram {
  LearnedBigram({this.score = 0, this.day = 0});

  double score;
  int day;

  double scoreAt(int today) => score * _decay(today - day);
}

class LearnedData {
  LearnedData(this.language);

  final LanguageId language;

  /// folded word -> usage.
  final Map<String, LearnedWord> words = {};

  /// folded previous word -> folded next word -> usage.
  final Map<String, Map<String, LearnedBigram>> bigrams = {};

  /// Folded words that must never be suggested.
  final Set<String> blocked = {};

  int _bigramCount = 0;
  bool dirty = false;

  bool get isEmpty => words.isEmpty && bigrams.isEmpty && blocked.isEmpty;

  bool isConfirmed(String key) => (words[key]?.commits ?? 0) >= kCommitsToKnow;

  double wordScore(String key, int today) => words[key]?.scoreAt(today) ?? 0;

  double bigramScore(String previous, String key, int today) => bigrams[previous]?[key]?.scoreAt(today) ?? 0;

  void commitWord(String key, String surface, int today, {required bool novel}) {
    final w = words[key];
    if (w == null) {
      words[key] = LearnedWord(surface, commits: 1, score: 1, day: today, novel: novel);
    } else {
      w
        ..score = w.scoreAt(today) + 1
        ..day = today
        ..commits += 1;
      // Prefer the lower-case spelling: capitals at sentence start are noise.
      if (w.surface != w.surface.toLowerCase() && surface == surface.toLowerCase()) w.surface = surface;
    }
    dirty = true;
    if (words.length > kMaxLearnedWords + kMaxLearnedWords ~/ 10) _pruneWords(today);
  }

  void commitBigram(String previous, String key, int today) {
    final inner = bigrams.putIfAbsent(previous, () => {});
    final b = inner[key];
    if (b == null) {
      inner[key] = LearnedBigram(score: 1, day: today);
      _bigramCount++;
    } else {
      b
        ..score = b.scoreAt(today) + 1
        ..day = today;
    }
    dirty = true;
    if (_bigramCount > kMaxLearnedBigrams + kMaxLearnedBigrams ~/ 10) _pruneBigrams(today);
  }

  /// Forget a word and every pair it is part of.
  void removeWord(String key) {
    var changed = words.remove(key) != null;
    final removed = bigrams.remove(key);
    if (removed != null) {
      _bigramCount -= removed.length;
      changed = true;
    }
    for (final inner in bigrams.values) {
      if (inner.remove(key) != null) {
        _bigramCount--;
        changed = true;
      }
    }
    bigrams.removeWhere((_, inner) => inner.isEmpty);
    if (changed) dirty = true;
  }

  void clear() {
    words.clear();
    bigrams.clear();
    blocked.clear();
    _bigramCount = 0;
    dirty = true;
  }

  void _pruneWords(int today) {
    final entries = words.entries.toList()..sort((a, b) => a.value.scoreAt(today).compareTo(b.value.scoreAt(today)));
    final drop = words.length - kMaxLearnedWords;
    for (var i = 0; i < drop; i++) {
      words.remove(entries[i].key);
    }
  }

  void _pruneBigrams(int today) {
    final all = <(String, String, double)>[
      for (final outer in bigrams.entries)
        for (final inner in outer.value.entries) (outer.key, inner.key, inner.value.scoreAt(today)),
    ]..sort((a, b) => a.$3.compareTo(b.$3));
    final drop = all.length - kMaxLearnedBigrams;
    for (var i = 0; i < drop; i++) {
      bigrams[all[i].$1]?.remove(all[i].$2);
    }
    bigrams.removeWhere((_, inner) => inner.isEmpty);
    _bigramCount = bigrams.values.fold(0, (n, inner) => n + inner.length);
  }

  // ------------------------------------------------------------ persistence

  Uint8List encode() {
    final json = <String, Object?>{
      'v': _kFormatVersion,
      'w': [
        for (final e in words.entries)
          [
            e.key,
            e.value.surface,
            e.value.commits,
            double.parse(e.value.score.toStringAsFixed(3)),
            e.value.day,
            e.value.novel ? 1 : 0,
          ],
      ],
      'b': [
        for (final outer in bigrams.entries)
          for (final inner in outer.value.entries)
            [outer.key, inner.key, double.parse(inner.value.score.toStringAsFixed(3)), inner.value.day],
      ],
      'x': blocked.toList(),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(json)));
  }

  /// Parses stored bytes; corrupt or unknown data yields empty data.
  static LearnedData decode(LanguageId language, Uint8List? bytes) {
    final data = LearnedData(language);
    if (bytes == null || bytes.isEmpty) return data;
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map || json['v'] != _kFormatVersion) return data;
      for (final w in (json['w'] as List? ?? const [])) {
        final row = w as List;
        data.words[row[0] as String] = LearnedWord(
          row[1] as String,
          commits: (row[2] as num).toInt(),
          score: (row[3] as num).toDouble(),
          day: (row[4] as num).toInt(),
          novel: row[5] == 1,
        );
      }
      for (final b in (json['b'] as List? ?? const [])) {
        final row = b as List;
        data.bigrams.putIfAbsent(row[0] as String, () => {})[row[1] as String] = LearnedBigram(
          score: (row[2] as num).toDouble(),
          day: (row[3] as num).toInt(),
        );
        data._bigramCount++;
      }
      for (final x in (json['x'] as List? ?? const [])) {
        data.blocked.add(x as String);
      }
    } on Object {
      return LearnedData(language);
    }
    return data;
  }
}
