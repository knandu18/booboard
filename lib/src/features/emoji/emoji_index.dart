// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Offline emoji search: prefix search over the keyword tables of the enabled
// languages, and an exact map for emoji suggestions. Pure Dart, no I/O.
import 'dart:typed_data';

import 'emoji_data.dart';

/// Emoji data plus the keyword tables for a set of languages.
class EmojiIndex {
  EmojiIndex({required this.data, required this.languages, required this.tables, required this.exact});

  final EmojiData data;

  /// The languages these tables cover, in priority order.
  final List<String> languages;
  final List<EmojiKeywordTable> tables;

  /// Lower-case exact keyword or short name (one word) to the base ref it suggests.
  final Map<String, int> exact;

  /// The base ref for a whole word typed by the user, or -1. Lower-case the input first.
  int exactRef(String word) => exact[word] ?? -1;

  /// Items (not refs) whose keywords start with [query], best first. An exact keyword ranks above a
  /// prefix; ties keep the emoji's catalogue order. Scans at most [scanLimit] keys, so a one-letter
  /// query stays cheap.
  List<int> search(String query, {int limit = 60, int scanLimit = 600}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final scores = <int, int>{};
    var scanned = 0;
    for (final table in tables) {
      final keys = table.keys;
      for (var i = _lowerBound(keys, q); i < keys.length && scanned < scanLimit; i++) {
        final key = keys[i];
        if (!key.startsWith(q)) break;
        scanned++;
        final exactKey = key.length == q.length;
        for (final ref in table.refs[i]) {
          final item = ref ~/ refStride;
          // A short name that is the whole query ("pizza" for the pizza) outranks a keyword that merely lists it.
          final name = table.shortNames[ref];
          final score = name != null && name.toLowerCase() == q
              ? 4
              : exactKey
              ? 3
              : 1;
          if (score > (scores[item] ?? 0)) scores[item] = score;
        }
      }
    }
    final ranked = scores.keys.toList()
      ..sort((a, b) {
        final byScore = scores[b]!.compareTo(scores[a]!);
        return byScore != 0 ? byScore : a.compareTo(b);
      });
    return ranked.length > limit ? ranked.sublist(0, limit) : ranked;
  }

  static int _lowerBound(List<String> sorted, String key) {
    var lo = 0;
    var hi = sorted.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (sorted[mid].compareTo(key) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

/// Builds the index for [languages] from the raw gzip bytes. Runs in an isolate in the app.
/// [keywordGz] is parallel to [languages].
EmojiIndex buildEmojiIndex({
  required Uint8List emojiGz,
  required List<String> languages,
  required List<Uint8List> keywordGz,
}) {
  final data = decodeEmojiData(emojiGz);
  final tables = [for (var i = 0; i < languages.length; i++) decodeKeywordTable(languages[i], keywordGz[i])];
  return EmojiIndex(data: data, languages: languages, tables: tables, exact: buildExactMap(data, tables));
}

/// Single-word keywords and short names that suggest one base emoji. Earlier languages win. A short
/// name beats a plain keyword, and a keyword only suggests emoji that have a base form (never a
/// skin-tone variant on its own).
Map<String, int> buildExactMap(EmojiData data, List<EmojiKeywordTable> tables) {
  final exact = <String, int>{};
  for (final table in tables) {
    for (final entry in table.shortNames.entries) {
      final ref = entry.key;
      if (ref % refStride != 0 || entry.value.contains(' ')) continue;
      exact.putIfAbsent(entry.value.toLowerCase(), () => ref);
    }
  }
  for (final table in tables) {
    for (var i = 0; i < table.keys.length; i++) {
      final key = table.keys[i];
      if (key.contains(' ') || exact.containsKey(key)) continue;
      int? best;
      for (final ref in table.refs[i]) {
        if (ref % refStride != 0) continue;
        if (best == null || ref < best) best = ref;
      }
      if (best != null) exact[key] = best;
    }
  }
  return exact;
}

/// Convenience for the bytes an index is built from, when the caller already holds them.
typedef EmojiBytes = ({Uint8List emojiGz, Map<String, Uint8List> keywordGz});
