// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A. The Chinese dictionary (`zh.kdict` in the dict-zh-rime-ice pack): a sorted binary
// index of pinyin keys that is read in place, never expanded into Dart objects. The writer is
// tool/chinese/zh_dict_writer.dart; keep the two in step (the layout is documented there too).
//
// Layout, little-endian, offsets from the start of the file:
//   0    'KZD1'
//   4    u32 version (1)
//   8    20 u32 header fields, in the order of the `_F` constants below
//   ...  sections, in any order; their offsets are in the header
//
// A key is the pinyin of a word with no separators, lower case ASCII ("nihao"). Keys are sorted by
// byte; key k spans keyBlob[keyOffs[k] .. keyOffs[k+1]) and its entries are the indices
// keyStart[k] .. keyStart[k+1]. Entries are sorted by score, best first.
// An entry is 12 bytes: u32 textOff (text blob), u32 sylOff (syllable blob), i16 score (1000 times
// log10 of the probability of the entry within its source), u8 textLen, u8 sylLen (bytes).
// The syllable blob holds the segmented pinyin with apostrophes ("ni'hao").
// Initials keys ("nh" for 你好) index the entries of two or more syllables the same way, with
// initIdx holding entry indices (not keys).
import 'dart:convert';
import 'dart:typed_data';

/// One dictionary entry as the composer sees it.
class ZhEntry {
  const ZhEntry({required this.text, required this.syllables, required this.logP});

  /// Simplified Chinese text (一个字 or a word).
  final String text;

  /// Segmented pinyin with apostrophes, for example "zhong'guo'ren".
  final String syllables;

  /// log10 of the entry's probability within its source. Higher is more common.
  final double logP;
}

/// Header field indices (each a u32 after the magic and version).
abstract final class ZhDictFormat {
  static const int version = 1;
  static const int headerStart = 8;
  static const int headerFields = 20;
  static const int dataStart = headerStart + headerFields * 4;
  static const int entryBytes = 12;

  static const int fKeyCount = 0;
  static const int fEntryCount = 1;
  static const int fInitCount = 2;
  static const int fInitIdxCount = 3;
  static const int fMaxKeyLen = 4;
  static const int fKeyBlob = 5;
  static const int fKeyOffs = 6;
  static const int fKeyStart = 7;
  static const int fEntries = 8;
  static const int fTextBlob = 9;
  static const int fSylBlob = 10;
  static const int fInitBlob = 11;
  static const int fInitOffs = 12;
  static const int fInitStart = 13;
  static const int fInitIdx = 14;
  static const int fTotalLength = 15;
}

/// A read-only view of a `zh.kdict` file.
class ZhDictionary {
  ZhDictionary._(this._bytes) : _data = ByteData.sublistView(_bytes);

  /// Opens [bytes] (the whole file). Throws [FormatException] when the file is not a valid dictionary.
  factory ZhDictionary.fromBytes(Uint8List bytes) {
    if (bytes.length < ZhDictFormat.dataStart) throw const FormatException('zh.kdict is truncated');
    if (bytes[0] != 0x4B || bytes[1] != 0x5A || bytes[2] != 0x44 || bytes[3] != 0x31) {
      throw const FormatException('zh.kdict has the wrong magic');
    }
    final dict = ZhDictionary._(bytes);
    if (dict._u32(4) != ZhDictFormat.version) throw const FormatException('zh.kdict has an unknown version');
    if (dict._field(ZhDictFormat.fTotalLength) != bytes.length) {
      throw const FormatException('zh.kdict length does not match its header');
    }
    dict._checkTables();
    return dict;
  }

  final Uint8List _bytes;
  final ByteData _data;

  /// Every table the header points to must lie inside the file (SEC-11), so a lookup can never read past
  /// the end. Blobs have no stored size: their start must be inside the file. Tables have sizes from counts.
  void _checkTables() {
    final end = _bytes.length;
    void blob(int field, String what) {
      if (_field(field) > end) throw FormatException('zh.kdict $what starts past the end of the file');
    }

    // [n] items, plus [extra] closing items. A table with no items is not read, so it is not checked.
    void table(int field, int n, int itemBytes, String what, {int extra = 0}) {
      if (n == 0) return;
      final off = _field(field);
      if (off < ZhDictFormat.dataStart || off + (n + extra) * itemBytes > end) {
        throw FormatException('zh.kdict $what lies outside the file');
      }
    }

    final keys = _field(ZhDictFormat.fKeyCount);
    final inits = _field(ZhDictFormat.fInitCount);
    blob(ZhDictFormat.fKeyBlob, 'key text');
    blob(ZhDictFormat.fTextBlob, 'entry text');
    blob(ZhDictFormat.fSylBlob, 'syllable text');
    blob(ZhDictFormat.fInitBlob, 'initials text');
    table(ZhDictFormat.fKeyOffs, keys, 4, 'key offsets', extra: 1);
    table(ZhDictFormat.fKeyStart, keys, 4, 'key starts', extra: 1);
    table(ZhDictFormat.fEntries, _field(ZhDictFormat.fEntryCount), ZhDictFormat.entryBytes, 'entries');
    table(ZhDictFormat.fInitOffs, inits, 4, 'initials offsets', extra: 1);
    table(ZhDictFormat.fInitStart, inits, 4, 'initials starts', extra: 1);
    table(ZhDictFormat.fInitIdx, _field(ZhDictFormat.fInitIdxCount), 4, 'initials index');
  }

  /// Unique pinyin keys.
  int get keyCount => _field(ZhDictFormat.fKeyCount);

  /// All entries.
  int get entryCount => _field(ZhDictFormat.fEntryCount);

  /// Unique initials keys.
  int get initCount => _field(ZhDictFormat.fInitCount);

  /// The longest key in bytes; the segmenter never looks for longer runs of letters.
  int get maxKeyLen => _field(ZhDictFormat.fMaxKeyLen);

  int _u32(int offset) => _data.getUint32(offset, Endian.little);

  int _field(int index) => _u32(ZhDictFormat.headerStart + index * 4);

  /// Entries whose pinyin key is exactly [key] (letters only), best first. Empty when none.
  List<ZhEntry> entriesFor(String key) {
    if (key.isEmpty) return const [];
    final count = keyCount;
    if (count == 0) return const [];
    final k = _search(_field(ZhDictFormat.fKeyBlob), _field(ZhDictFormat.fKeyOffs), count, key);
    if (k < 0) return const [];
    final startsOff = _field(ZhDictFormat.fKeyStart);
    final from = _u32(startsOff + 4 * k);
    final to = _u32(startsOff + 4 * (k + 1));
    return [for (var i = from; i < to; i++) _entry(i)];
  }

  /// Multi-syllable entries whose initials are exactly [initials] ("nh" for 你好), best first.
  List<ZhEntry> entriesForInitials(String initials) {
    if (initials.isEmpty) return const [];
    final count = initCount;
    if (count == 0) return const [];
    final k = _search(_field(ZhDictFormat.fInitBlob), _field(ZhDictFormat.fInitOffs), count, initials);
    if (k < 0) return const [];
    final startsOff = _field(ZhDictFormat.fInitStart);
    final idxOff = _field(ZhDictFormat.fInitIdx);
    final from = _u32(startsOff + 4 * k);
    final to = _u32(startsOff + 4 * (k + 1));
    return [for (var i = from; i < to; i++) _entry(_u32(idxOff + 4 * i))];
  }

  /// True when some entry has exactly this key.
  bool hasKey(String key) => entriesFor(key).isNotEmpty;

  /// Binary search over a sorted blob of byte strings. Returns the index or -1.
  int _search(int blobOffset, int offsOffset, int count, String query) {
    var lo = 0;
    var hi = count - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final c = _compare(blobOffset, offsOffset, mid, query);
      if (c == 0) return mid;
      if (c < 0) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return -1;
  }

  /// Compares stored string [index] with [query] by bytes (both ASCII).
  int _compare(int blobOffset, int offsOffset, int index, String query) {
    final start = _u32(offsOffset + 4 * index);
    final end = _u32(offsOffset + 4 * (index + 1));
    final base = blobOffset + start;
    final n = end - start;
    final m = n < query.length ? n : query.length;
    for (var i = 0; i < m; i++) {
      final d = _bytes[base + i] - query.codeUnitAt(i);
      if (d != 0) return d;
    }
    return n - query.length;
  }

  ZhEntry _entry(int index) {
    final off = _field(ZhDictFormat.fEntries) + index * ZhDictFormat.entryBytes;
    final textOff = _field(ZhDictFormat.fTextBlob) + _u32(off);
    final sylOff = _field(ZhDictFormat.fSylBlob) + _u32(off + 4);
    final score = _data.getInt16(off + 8, Endian.little);
    final textLen = _bytes[off + 10];
    final sylLen = _bytes[off + 11];
    return ZhEntry(
      text: utf8.decode(Uint8List.sublistView(_bytes, textOff, textOff + textLen)),
      syllables: ascii.decode(Uint8List.sublistView(_bytes, sylOff, sylOff + sylLen)),
      logP: score / 1000.0,
    );
  }
}
