// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-B (Japanese). Learned conversions: when the user picks a dictionary word for a
// reading, that pick ranks higher next time. Stored only in the encrypted blob `learned_ja_words`
// (through SecureBlobStore), and only when learning is allowed. Never logged.
import 'dart:convert';
import 'dart:typed_data';

class JapaneseLearning {
  JapaneseLearning();

  /// The blob that holds this store (SecureBlobStore name).
  static const String blobName = 'learned_ja_words';

  /// Readings kept at most; the oldest reading goes first.
  static const int maxReadings = 2000;

  /// Surfaces kept per reading.
  static const int maxSurfacesPerReading = 5;

  final Map<String, Map<String, int>> _byReading = {};

  bool get isEmpty => _byReading.isEmpty;

  /// How many times [surface] was picked for [reading].
  int count(String reading, String surface) => _byReading[reading]?[surface] ?? 0;

  /// True when [reading] has any learned pick.
  bool hasReading(String reading) => _byReading.containsKey(reading);

  /// The picked surfaces for [reading], most picked first.
  List<String> surfacesFor(String reading) {
    final m = _byReading[reading];
    if (m == null) return const [];
    final list = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in list) e.key];
  }

  /// Cost bonus for a learned pick (subtracted from the word cost in the lattice).
  static int bonusFor(int count) => (count < 5 ? count : 5) * 700;

  void learn(String reading, String surface) {
    if (reading.isEmpty || surface.isEmpty) return;
    final m = _byReading.remove(reading) ?? <String, int>{};
    _byReading[reading] = m;
    m[surface] = (m[surface] ?? 0) + 1;
    if (m.length > maxSurfacesPerReading) {
      final weakest = m.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
      m.remove(weakest);
    }
    while (_byReading.length > maxReadings) {
      _byReading.remove(_byReading.keys.first);
    }
  }

  void clear() => _byReading.clear();

  /// Adds the picks of [other] to this store (used when the saved picks load after new ones).
  void absorb(JapaneseLearning other) {
    for (final r in other._byReading.entries) {
      for (final s in r.value.entries) {
        for (var i = 0; i < s.value; i++) {
          learn(r.key, s.key);
        }
      }
    }
  }

  /// The store as bytes: `{"v":1,"w":{reading:{surface:count}}}`.
  Uint8List toBytes() => Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'v': 1,
        'w': {
          for (final e in _byReading.entries) e.key: {for (final s in e.value.entries) s.key: s.value},
        },
      }),
    ),
  );

  /// Reads [bytes]. Anything unreadable gives an empty store: learned words are a convenience.
  static JapaneseLearning fromBytes(Uint8List? bytes) {
    final out = JapaneseLearning();
    if (bytes == null || bytes.isEmpty) return out;
    try {
      final j = jsonDecode(utf8.decode(bytes));
      if (j is! Map || j['v'] != 1 || j['w'] is! Map) return out;
      for (final r in (j['w'] as Map).entries) {
        final v = r.value;
        if (r.key is! String || v is! Map) continue;
        for (final s in v.entries) {
          final c = s.value;
          if (s.key is String && c is int && c > 0) {
            final m = out._byReading.putIfAbsent(r.key as String, () => <String, int>{});
            if (m.length < maxSurfacesPerReading) m[s.key as String] = c > 1000 ? 1000 : c;
          }
        }
      }
    } on Object {
      return JapaneseLearning();
    }
    return out;
  }
}
