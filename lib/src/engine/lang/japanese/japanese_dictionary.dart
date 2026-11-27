// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-B (Japanese). The compact dictionary of the dict-ja-mozc pack, read in place.
//
// Two files (little-endian throughout), written by tool/japanese/build_mozc_lexicon.dart and stored in the
// pack gzip-compressed as japanese.lex.gz and japanese.conn.gz (the pack budget is 45 MB; uncompressed the
// two files are about 62 MB, compressed about 16 MB):
//
// japanese.lex, "KJLX":
//   0   magic "KJLX", u16 version (1), u16 reserved
//   8   u32 readingCount R, u32 entryCount N, u32 unknownId (the 名詞,一般 id for unknown words)
//   20  u32 readingBytes RB, u32 surfaceBytes SB
//   28  u32 readingOffset[R+1]   byte offsets into the reading bytes, sorted by reading (UTF-8)
//       u32 entryStart[R+1]      the entries of reading r are entryStart[r] .. entryStart[r+1]-1
//       u32 surfaceOffset[N+1]   byte offsets into the surface bytes, in entry order
//       u16 lid[N], u16 rid[N], u16 cost[N]
//       reading bytes, surface bytes
//
// japanese.conn, "KJCN":
//   0   magic "KJCN", u16 version (1), u16 N (number of ids)
//   8   u16 cost[N*N]: the transition cost from a node whose right id is p to a node whose left id is
//       n is cost[p * N + n]. Lower is more likely.
//
// Nothing here is fetched from the network. The files come from a staged pack and are read off the
// UI isolate by [JapaneseDictionary.load].
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Format constants shared with the builder.
abstract final class JapaneseLexiconFormat {
  static const int version = 1;
  static const String lexMagic = 'KJLX';
  static const String connMagic = 'KJCN';
  static const int lexHeaderBytes = 28;
  static const int connHeaderBytes = 8;

  /// Cost given to a node the builder cannot place (no dictionary entry for a character).
  static const int unknownCost = 9000;

  /// Words longer than this (in characters) are not looked up.
  static const int maxReadingLength = 24;
}

/// A dictionary entry: a surface form and its word costs.
typedef JapaneseEntry = ({String surface, int lid, int rid, int cost});

class JapaneseDictionary {
  JapaneseDictionary._(this._lex, this._conn)
    : _bd = ByteData.sublistView(_lex),
      _connBd = ByteData.sublistView(_conn),
      readingCount = _lex.lengthInBytes >= 28 ? ByteData.sublistView(_lex).getUint32(8, Endian.little) : 0,
      entryCount = _lex.lengthInBytes >= 28 ? ByteData.sublistView(_lex).getUint32(12, Endian.little) : 0,
      unknownId = _lex.lengthInBytes >= 28 ? ByteData.sublistView(_lex).getUint32(16, Endian.little) : 0,
      connIds = _conn.lengthInBytes >= 8 ? ByteData.sublistView(_conn).getUint16(6, Endian.little) : 0 {
    final rb = _bd.getUint32(20, Endian.little);
    final sb = _bd.getUint32(24, Endian.little);
    var pos = JapaneseLexiconFormat.lexHeaderBytes;
    _readingOffsetAt = pos;
    pos += 4 * (readingCount + 1);
    _entryStartAt = pos;
    pos += 4 * (readingCount + 1);
    _surfaceOffsetAt = pos;
    pos += 4 * (entryCount + 1);
    _lidAt = pos;
    pos += 2 * entryCount;
    _ridAt = pos;
    pos += 2 * entryCount;
    _costAt = pos;
    pos += 2 * entryCount;
    _readingBase = pos;
    _surfaceBase = pos + rb;
    if (_surfaceBase + sb != _lex.lengthInBytes) {
      throw const FormatException('japanese.lex: size does not match its header');
    }
  }

  /// Reads the two files. Throws [FormatException] for files that are not this format.
  factory JapaneseDictionary.fromBytes(Uint8List lex, Uint8List conn) {
    if (lex.lengthInBytes < JapaneseLexiconFormat.lexHeaderBytes ||
        utf8.decode(lex.sublist(0, 4), allowMalformed: true) != JapaneseLexiconFormat.lexMagic) {
      throw const FormatException('japanese.lex: bad magic');
    }
    if (ByteData.sublistView(lex).getUint16(4, Endian.little) != JapaneseLexiconFormat.version) {
      throw const FormatException('japanese.lex: unsupported version');
    }
    if (conn.lengthInBytes < JapaneseLexiconFormat.connHeaderBytes ||
        utf8.decode(conn.sublist(0, 4), allowMalformed: true) != JapaneseLexiconFormat.connMagic) {
      throw const FormatException('japanese.conn: bad magic');
    }
    final n = ByteData.sublistView(conn).getUint16(6, Endian.little);
    if (conn.lengthInBytes != JapaneseLexiconFormat.connHeaderBytes + 2 * n * n) {
      throw const FormatException('japanese.conn: size does not match its header');
    }
    return JapaneseDictionary._(lex, conn);
  }

  /// Reads the two files from [directory] (a pack folder): japanese.lex.gz and japanese.conn.gz,
  /// inflated here. Runs synchronously: call it inside `Isolate.run`, never on the UI isolate.
  static JapaneseDictionary load(String directory) {
    // gzip.decode returns a Uint8List at run time (its static type is List<int>); the cast keeps it unboxed.
    final lex = gzip.decode(File('$directory/japanese.lex.gz').readAsBytesSync()) as Uint8List;
    final conn = gzip.decode(File('$directory/japanese.conn.gz').readAsBytesSync()) as Uint8List;
    return JapaneseDictionary.fromBytes(lex, conn);
  }

  final Uint8List _lex;
  final Uint8List _conn;
  final ByteData _bd;
  final ByteData _connBd;

  final int readingCount;
  final int entryCount;

  /// The id used for characters with no dictionary entry (名詞,一般).
  final int unknownId;

  /// The number of ids in the connection matrix.
  final int connIds;

  late final int _readingOffsetAt;
  late final int _entryStartAt;
  late final int _surfaceOffsetAt;
  late final int _lidAt;
  late final int _ridAt;
  late final int _costAt;
  late final int _readingBase;
  late final int _surfaceBase;

  /// Bytes held by the two files.
  int get sizeInBytes => _lex.lengthInBytes + _conn.lengthInBytes;

  int _readingStart(int r) => _bd.getUint32(_readingOffsetAt + 4 * r, Endian.little);
  int _readingEnd(int r) => _bd.getUint32(_readingOffsetAt + 4 * (r + 1), Endian.little);

  /// The first entry index of reading [r].
  int entryStart(int r) => _bd.getUint32(_entryStartAt + 4 * r, Endian.little);

  /// One past the last entry index of reading [r].
  int entryEnd(int r) => _bd.getUint32(_entryStartAt + 4 * (r + 1), Endian.little);

  /// The reading of reading [r] (hiragana).
  String readingAt(int r) => utf8.decode(_lex.sublist(_readingBase + _readingStart(r), _readingBase + _readingEnd(r)));

  String surface(int e) => utf8.decode(
    _lex.sublist(
      _surfaceBase + _bd.getUint32(_surfaceOffsetAt + 4 * e, Endian.little),
      _surfaceBase + _bd.getUint32(_surfaceOffsetAt + 4 * (e + 1), Endian.little),
    ),
  );

  int lid(int e) => _bd.getUint16(_lidAt + 2 * e, Endian.little);
  int rid(int e) => _bd.getUint16(_ridAt + 2 * e, Endian.little);
  int cost(int e) => _bd.getUint16(_costAt + 2 * e, Endian.little);

  /// Transition cost from a node whose right id is [prevRid] to one whose left id is [nextLid].
  int connection(int prevRid, int nextLid) {
    if (prevRid >= connIds || nextLid >= connIds) return 0;
    return _connBd.getUint16(JapaneseLexiconFormat.connHeaderBytes + 2 * (prevRid * connIds + nextLid), Endian.little);
  }

  /// Compares reading [r] with [key] (UTF-8): negative, zero or positive.
  int _compare(int r, Uint8List key) {
    final start = _readingBase + _readingStart(r);
    final len = _readingEnd(r) - _readingStart(r);
    final n = len < key.length ? len : key.length;
    for (var i = 0; i < n; i++) {
      final d = _lex[start + i] - key[i];
      if (d != 0) return d;
    }
    return len - key.length;
  }

  /// The reading index whose reading is exactly [reading], or null.
  int? readingIndex(String reading) {
    final key = utf8.encode(reading);
    var lo = 0;
    var hi = readingCount - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final c = _compare(mid, key);
      if (c == 0) return mid;
      if (c < 0) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return null;
  }

  /// The first reading index whose reading starts with [prefix], or [readingCount] when none does.
  /// Readings starting with [prefix] are the run from this index while [readingStartsWith] holds.
  int firstReadingWithPrefix(String prefix) {
    final key = utf8.encode(prefix);
    var lo = 0;
    var hi = readingCount;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_compare(mid, key) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// True when reading [r] starts with [prefix].
  bool readingStartsWith(int r, String prefix) {
    final key = utf8.encode(prefix);
    final start = _readingBase + _readingStart(r);
    if (_readingEnd(r) - _readingStart(r) < key.length) return false;
    for (var i = 0; i < key.length; i++) {
      if (_lex[start + i] != key[i]) return false;
    }
    return true;
  }

  /// All entries of reading [r] as records (used by the tests and the pack check).
  List<JapaneseEntry> entriesOf(int r) => [
    for (var e = entryStart(r); e < entryEnd(r); e++) (surface: surface(e), lid: lid(e), rid: rid(e), cost: cost(e)),
  ];
}
