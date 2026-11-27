// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-B. The romanised -> native table for one Indic language: assets/translit/<lang>.bin
// (gzip of the format written by tool/indic/build_data.py; read here off the UI isolate).
//
// Format before gzip (little-endian): "MYTL", u8 version (1), u32 count, then for each entry, sorted
// by roman then score (desc): u8 roman length, roman bytes (a-z), u8 native UTF-8 length, native
// UTF-8 bytes, u8 score (log2 of the native word's frequency times 12; 0 when unknown).
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

/// One romanised entry.
class TranslitEntry {
  const TranslitEntry(this.roman, this.native, this.score);

  final String roman;
  final String native;

  /// 0..255; higher is more frequent.
  final int score;
}

class TranslitTable {
  TranslitTable._(this._romans, this._natives, this._scores);

  final List<String> _romans;
  final List<String> _natives;
  final Uint8List _scores;

  /// Entries in the table.
  int get length => _romans.length;

  /// Decodes [gzipped] (the .bin asset). Throws [FormatException] on a corrupt file. Call it inside
  /// `Isolate.run` for real assets.
  factory TranslitTable.fromGzip(Uint8List gzipped) =>
      TranslitTable.fromBytes(Uint8List.fromList(gzip.decode(gzipped)));

  factory TranslitTable.fromBytes(Uint8List b) {
    if (b.length < 9 || b[0] != 0x4D || b[1] != 0x59 || b[2] != 0x54 || b[3] != 0x4C) {
      throw const FormatException('not a translit table');
    }
    if (b[4] != 1) throw FormatException('unsupported translit version ${b[4]}');
    final count = ByteData.sublistView(b, 5, 9).getUint32(0, Endian.little);
    // Every entry takes at least three bytes (two lengths and a score): a larger count is a corrupt file, and
    // is refused before anything is allocated (SEC-09).
    if (count > (b.length - 9) ~/ 3) throw const FormatException('translit table count is larger than the file');
    final romans = <String>[];
    final natives = <String>[];
    final scores = Uint8List(count);
    var p = 9;
    void need(int n) {
      if (p + n > b.length) throw const FormatException('translit table is truncated');
    }

    for (var i = 0; i < count; i++) {
      need(1);
      final rl = b[p++];
      need(rl);
      romans.add(String.fromCharCodes(b, p, p + rl));
      p += rl;
      need(1);
      final nl = b[p++];
      need(nl + 1);
      natives.add(utf8.decode(b.sublist(p, p + nl)));
      p += nl;
      scores[i] = b[p++];
    }
    return TranslitTable._(romans, natives, scores);
  }

  /// Entries whose roman form is exactly [roman], most frequent first.
  List<TranslitEntry> exact(String roman, {int max = 5}) {
    final lo = _lowerBound(roman);
    final out = <TranslitEntry>[];
    for (var i = lo; i < _romans.length && _romans[i] == roman; i++) {
      out.add(_entry(i));
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out.length > max ? out.sublist(0, max) : out;
  }

  /// The most frequent entries whose roman form starts with [prefix] (and is not equal to it).
  /// Scans at most [scanLimit] entries, so short prefixes can miss rare words: that is the point.
  List<TranslitEntry> prefix(String prefix, {int max = 5, int scanLimit = 20000}) {
    if (prefix.isEmpty) return const [];
    final lo = _lowerBound(prefix);
    final hits = <int>[];
    var scanned = 0;
    for (var i = lo; i < _romans.length && scanned < scanLimit; i++, scanned++) {
      final r = _romans[i];
      if (!r.startsWith(prefix)) break;
      if (r != prefix) hits.add(i);
    }
    hits.sort((a, b) => _scores[b].compareTo(_scores[a]));
    return [for (final i in hits.take(max)) _entry(i)];
  }

  /// The most frequent entry for each native word, most frequent first (for the swipe mapping).
  List<TranslitEntry> bestPerNative({int max = 20000}) {
    final best = <String, int>{};
    for (var i = 0; i < _romans.length; i++) {
      final old = best[_natives[i]];
      if (old == null || _scores[i] > _scores[old]) best[_natives[i]] = i;
    }
    final idx = best.values.toList()..sort((a, b) => _scores[b].compareTo(_scores[a]));
    return [for (final i in idx.take(max)) _entry(i)];
  }

  TranslitEntry _entry(int i) => TranslitEntry(_romans[i], _natives[i], _scores[i]);

  /// First index whose roman form is >= [key].
  int _lowerBound(String key) {
    var lo = 0;
    var hi = _romans.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_romans[mid].compareTo(key) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}
