// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-B (Japanese). Writes japanese.lex and japanese.conn in the format documented in
// lib/src/engine/lang/japanese/japanese_dictionary.dart. Pure Dart, used by build_mozc_lexicon.dart
// and by the tests (with a small fixture instead of the real dictionary).
import 'dart:convert';
import 'dart:typed_data';

import 'package:booboard/src/engine/lang/japanese/japanese_dictionary.dart';

/// One dictionary word before it is packed.
class LexiconEntry {
  const LexiconEntry({
    required this.reading,
    required this.surface,
    required this.lid,
    required this.rid,
    required this.cost,
  });

  /// Hiragana (the builder converts katakana readings first).
  final String reading;
  final String surface;
  final int lid;
  final int rid;
  final int cost;
}

/// Sorts [entries] by reading (UTF-8 byte order, the order the reader searches in), then by cost, and
/// packs them into japanese.lex bytes. Duplicates (same reading, ids and surface) keep the lowest cost.
Uint8List buildLexiconBytes(List<LexiconEntry> entries, {required int unknownId}) {
  final best = <String, LexiconEntry>{};
  for (final e in entries) {
    final key = '${e.reading}\u0000${e.lid}\u0000${e.rid}\u0000${e.surface}';
    final prev = best[key];
    if (prev == null || e.cost < prev.cost) best[key] = e;
  }
  // Encode each reading once: the sort compares bytes.
  final keyed = [for (final e in best.values) (bytes: utf8.encode(e.reading), entry: e)]
    ..sort((a, b) {
      final c = _compareBytes(a.bytes, b.bytes);
      return c != 0 ? c : a.entry.cost.compareTo(b.entry.cost);
    });
  final sorted = [for (final k in keyed) k.entry];

  // Readings: one per distinct reading, in order, with the entries that carry it.
  final readingBytes = <Uint8List>[];
  final entryStart = <int>[];
  for (var i = 0; i < keyed.length; i++) {
    if (i == 0 || _compareBytes(keyed[i].bytes, keyed[i - 1].bytes) != 0) {
      readingBytes.add(keyed[i].bytes);
      entryStart.add(i);
    }
  }
  entryStart.add(sorted.length);
  final readingCount = readingBytes.length;
  final entryCount = sorted.length;

  final surfaceBytes = [for (final e in sorted) utf8.encode(e.surface)];

  final readingOffset = <int>[0];
  for (final b in readingBytes) {
    readingOffset.add(readingOffset.last + b.length);
  }
  final surfaceOffset = <int>[0];
  for (final b in surfaceBytes) {
    surfaceOffset.add(surfaceOffset.last + b.length);
  }
  final readingTotal = readingOffset.last;
  final surfaceTotal = surfaceOffset.last;

  final total =
      JapaneseLexiconFormat.lexHeaderBytes +
      4 * (readingCount + 1) * 2 +
      4 * (entryCount + 1) +
      6 * entryCount +
      readingTotal +
      surfaceTotal;
  final out = ByteData(total);
  final bytes = out.buffer.asUint8List();
  bytes.setRange(0, 4, ascii.encode(JapaneseLexiconFormat.lexMagic));
  out.setUint16(4, JapaneseLexiconFormat.version, Endian.little);
  out.setUint32(8, readingCount, Endian.little);
  out.setUint32(12, entryCount, Endian.little);
  out.setUint32(16, unknownId, Endian.little);
  out.setUint32(20, readingTotal, Endian.little);
  out.setUint32(24, surfaceTotal, Endian.little);

  var pos = JapaneseLexiconFormat.lexHeaderBytes;
  for (final v in readingOffset) {
    out.setUint32(pos, v, Endian.little);
    pos += 4;
  }
  for (final v in entryStart) {
    out.setUint32(pos, v, Endian.little);
    pos += 4;
  }
  for (final v in surfaceOffset) {
    out.setUint32(pos, v, Endian.little);
    pos += 4;
  }
  for (final e in sorted) {
    out.setUint16(pos, _u16(e.lid), Endian.little);
    pos += 2;
  }
  for (final e in sorted) {
    out.setUint16(pos, _u16(e.rid), Endian.little);
    pos += 2;
  }
  for (final e in sorted) {
    out.setUint16(pos, _u16(e.cost), Endian.little);
    pos += 2;
  }
  for (final b in readingBytes) {
    bytes.setRange(pos, pos + b.length, b);
    pos += b.length;
  }
  for (final b in surfaceBytes) {
    bytes.setRange(pos, pos + b.length, b);
    pos += b.length;
  }
  assert(pos == total);
  return bytes;
}

/// Packs an N×N connection matrix: [costs] holds N*N values, row by row (row = previous right id).
Uint8List buildConnectionBytes(int n, List<int> costs) {
  if (costs.length != n * n) throw ArgumentError('expected ${n * n} costs, got ${costs.length}');
  final out = ByteData(JapaneseLexiconFormat.connHeaderBytes + 2 * n * n);
  out.buffer.asUint8List().setRange(0, 4, ascii.encode(JapaneseLexiconFormat.connMagic));
  out.setUint16(4, JapaneseLexiconFormat.version, Endian.little);
  out.setUint16(6, n, Endian.little);
  var pos = JapaneseLexiconFormat.connHeaderBytes;
  for (final c in costs) {
    out.setUint16(pos, _u16(c), Endian.little);
    pos += 2;
  }
  return out.buffer.asUint8List();
}

int _u16(int v) => v < 0 ? 0 : (v > 65535 ? 65535 : v);

int _compareBytes(List<int> a, List<int> b) {
  final n = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return a.length - b.length;
}
