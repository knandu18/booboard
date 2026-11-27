// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A. What the user picked, for ranking: phrases picked from the candidates and new
// words built from two or more picks in a row. Kept as pinyin letters -> text -> count, in the
// encrypted blob `learned_zh_phrases` (SecureBlobStore). Text is always Simplified.
//
// PRIVACY: this file never logs. Nothing is learned in password fields, incognito or when learning
// is off; the composer checks that before it calls [add].
import 'dart:convert';
import 'dart:typed_data';

/// The SecureBlobStore name for the learned phrases.
const String learnedZhBlobName = 'learned_zh_phrases';

class LearnedPhrases {
  LearnedPhrases([Map<String, Map<String, int>>? data]) : _byLetters = data ?? {};

  /// Upper bound on distinct (letters, text) pairs; the least picked go first.
  static const int capacity = 2000;

  final Map<String, Map<String, int>> _byLetters;
  int _size = 0;

  /// True after a change that has not been saved yet.
  bool dirty = false;

  /// Distinct (letters, text) pairs stored.
  int get length {
    if (_size == 0) {
      _size = _byLetters.values.fold<int>(0, (s, m) => s + m.length);
    }
    return _size;
  }

  /// How often [text] was learned for [letters] (0 when never).
  int countFor(String letters, String text) => _byLetters[letters]?[text] ?? 0;

  /// The learned texts for [letters], most picked first.
  List<(String, int)> wordsFor(String letters) {
    final m = _byLetters[letters];
    if (m == null) return const [];
    final out = [for (final e in m.entries) (e.key, e.value)]..sort((a, b) => b.$2.compareTo(a.$2));
    return out;
  }

  /// Counts one pick of [text] for [letters].
  void add(String letters, String text) {
    if (letters.isEmpty || text.isEmpty) return;
    final m = _byLetters.putIfAbsent(letters, () => <String, int>{});
    if (!m.containsKey(text)) {
      _size = length + 1;
      if (_size > capacity) _evictLeastPicked();
    }
    m[text] = (m[text] ?? 0) + 1;
    dirty = true;
  }

  /// Replaces the contents with [other]'s (a reload from the blob keeps this object, so the composer
  /// that holds it sees the change).
  void replaceWith(LearnedPhrases other) {
    _byLetters
      ..clear()
      ..addAll(other._byLetters);
    _size = 0;
    dirty = false;
  }

  /// Removes everything.
  void clear() {
    _byLetters.clear();
    _size = 0;
    dirty = true;
  }

  void _evictLeastPicked() {
    String? bestKey;
    String? bestText;
    var bestCount = 1 << 30;
    for (final e in _byLetters.entries) {
      for (final t in e.value.entries) {
        if (t.value < bestCount) {
          bestCount = t.value;
          bestKey = e.key;
          bestText = t.key;
        }
      }
    }
    if (bestKey == null || bestText == null) return;
    final m = _byLetters[bestKey]!;
    m.remove(bestText);
    if (m.isEmpty) _byLetters.remove(bestKey);
    _size = length - 1;
  }

  /// The stored form: UTF-8 JSON `{"v":1,"p":{"nihao":{"你好":3}}}`.
  Uint8List encode() {
    final json = jsonEncode({
      'v': 1,
      'p': {for (final e in _byLetters.entries) e.key: e.value},
    });
    return Uint8List.fromList(utf8.encode(json));
  }

  /// Reads [bytes]. Anything unreadable gives an empty store (no error is shown for a learned blob).
  static LearnedPhrases decode(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return LearnedPhrases();
    try {
      final j = jsonDecode(utf8.decode(bytes));
      if (j is! Map || j['v'] != 1 || j['p'] is! Map) return LearnedPhrases();
      final data = <String, Map<String, int>>{};
      (j['p'] as Map).forEach((letters, value) {
        if (letters is! String || value is! Map) return;
        final m = <String, int>{};
        value.forEach((text, count) {
          if (text is String && count is int && count > 0) m[text] = count;
        });
        if (m.isNotEmpty) data[letters] = m;
      });
      return LearnedPhrases(data);
    } on Object {
      return LearnedPhrases();
    }
  }
}
