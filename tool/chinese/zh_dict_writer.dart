// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A. Writes `zh.kdict`, the Chinese dictionary read by ZhDictionary
// (lib/src/engine/lang/chinese/zh_dictionary.dart). The layout is described there; in short:
// magic 'KZD1', version 1, 20 u32 header fields, then sorted pinyin keys (with their entries, best
// first), sorted initials keys (with entry indices), and deduplicated text and syllable blobs.
import 'dart:convert';
import 'dart:typed_data';

import 'package:booboard/src/engine/lang/chinese/zh_dictionary.dart';

/// One word or character to index.
class ZhDictEntryInput {
  const ZhDictEntryInput(this.text, this.syllables, this.logP);

  /// Simplified Chinese text.
  final String text;

  /// Lower-case pinyin syllables joined with apostrophes ("zhong'guo'ren").
  final String syllables;

  /// log10 of the probability of this entry within its source.
  final double logP;
}

/// Thrown for an entry that cannot be stored (bad pinyin, or a text too long for the record).
class ZhDictInputError extends ArgumentError {
  ZhDictInputError(super.message);
}

final RegExp _syllablesRe = RegExp(r"^[a-z]+(?:'[a-z]+)*$");

/// Counts what [buildZhDictionary] kept and dropped.
class ZhDictStats {
  int entries = 0;
  int duplicates = 0;
  int keys = 0;
  int initials = 0;
  int bytes = 0;
}

/// Builds the file bytes. Entries with the same text and syllables are merged (the higher score wins).
Uint8List buildZhDictionary(Iterable<ZhDictEntryInput> input, {ZhDictStats? stats}) {
  final byId = <String, ZhDictEntryInput>{};
  var duplicates = 0;
  for (final e in input) {
    if (!_syllablesRe.hasMatch(e.syllables)) {
      throw ZhDictInputError('bad syllables for an entry');
    }
    final textBytes = utf8.encode(e.text);
    final sylBytes = ascii.encode(e.syllables);
    if (textBytes.isEmpty || textBytes.length > 255 || sylBytes.length > 255) {
      throw ZhDictInputError('entry too long for the record');
    }
    final id = '${e.syllables}\u0000${e.text}';
    final prev = byId[id];
    if (prev == null) {
      byId[id] = e;
    } else {
      duplicates++;
      if (e.logP > prev.logP) byId[id] = e;
    }
  }

  final entries = byId.values.toList()
    ..sort((a, b) {
      final ka = _key(a.syllables);
      final kb = _key(b.syllables);
      final c = ka.compareTo(kb);
      if (c != 0) return c;
      final s = b.logP.compareTo(a.logP);
      if (s != 0) return s;
      return a.text.compareTo(b.text);
    });

  // Keys and their entry ranges.
  final keys = <String>[];
  final keyStart = <int>[];
  for (var i = 0; i < entries.length; i++) {
    final k = _key(entries[i].syllables);
    if (keys.isEmpty || keys.last != k) {
      keys.add(k);
      keyStart.add(i);
    }
  }
  keyStart.add(entries.length);

  // Text and syllable blobs, deduplicated.
  final textOffs = <String, int>{};
  final textBlob = BytesBuilder(copy: false);
  final sylOffs = <String, int>{};
  final sylBlob = BytesBuilder(copy: false);
  final textRef = <int>[];
  final sylRef = <int>[];
  for (final e in entries) {
    final t = textOffs.putIfAbsent(e.text, () {
      final at = textBlob.length;
      textBlob.add(utf8.encode(e.text));
      return at;
    });
    final s = sylOffs.putIfAbsent(e.syllables, () {
      final at = sylBlob.length;
      sylBlob.add(ascii.encode(e.syllables));
      return at;
    });
    textRef.add(t);
    sylRef.add(s);
  }

  // Initials: multi-syllable entries, grouped by initials, best first.
  final initGroups = <String, List<int>>{};
  for (var i = 0; i < entries.length; i++) {
    final parts = entries[i].syllables.split("'");
    if (parts.length < 2) continue;
    final initials = parts.map((p) => p[0]).join();
    (initGroups[initials] ??= []).add(i);
  }
  final initKeys = initGroups.keys.toList()..sort();
  final initIdx = <int>[];
  final initStart = <int>[];
  for (final k in initKeys) {
    initStart.add(initIdx.length);
    final group = initGroups[k]!
      ..sort((a, b) {
        final s = entries[b].logP.compareTo(entries[a].logP);
        return s != 0 ? s : a.compareTo(b);
      });
    initIdx.addAll(group);
  }
  initStart.add(initIdx.length);
  final initBlob = BytesBuilder(copy: false);
  final initOffs = <int>[];
  for (final k in initKeys) {
    initOffs.add(initBlob.length);
    initBlob.add(ascii.encode(k));
  }
  initOffs.add(initBlob.length);

  // Key blob and offsets.
  final keyBlob = BytesBuilder(copy: false);
  final keyOffs = <int>[];
  for (final k in keys) {
    keyOffs.add(keyBlob.length);
    keyBlob.add(ascii.encode(k));
  }
  keyOffs.add(keyBlob.length);

  final maxKeyLen = keys.fold<int>(0, (m, k) => k.length > m ? k.length : m);

  // Layout.
  final headerEnd = ZhDictFormat.dataStart;
  var at = headerEnd;
  int place(int size) {
    final start = at;
    at += size;
    return start;
  }

  final keyBlobOff = place(keyBlob.length);
  final keyOffsOff = place(keyOffs.length * 4);
  final keyStartOff = place(keyStart.length * 4);
  final entriesOff = place(entries.length * ZhDictFormat.entryBytes);
  final textBlobOff = place(textBlob.length);
  final sylBlobOff = place(sylBlob.length);
  final initBlobOff = place(initBlob.length);
  final initOffsOff = place(initOffs.length * 4);
  final initStartOff = place(initStart.length * 4);
  final initIdxOff = place(initIdx.length * 4);
  final total = at;

  final out = Uint8List(total);
  final bd = ByteData.sublistView(out);
  out.setRange(0, 4, const [0x4B, 0x5A, 0x44, 0x31]);
  bd.setUint32(4, ZhDictFormat.version, Endian.little);
  final header = List<int>.filled(ZhDictFormat.headerFields, 0);
  header[ZhDictFormat.fKeyCount] = keys.length;
  header[ZhDictFormat.fEntryCount] = entries.length;
  header[ZhDictFormat.fInitCount] = initKeys.length;
  header[ZhDictFormat.fInitIdxCount] = initIdx.length;
  header[ZhDictFormat.fMaxKeyLen] = maxKeyLen;
  header[ZhDictFormat.fKeyBlob] = keyBlobOff;
  header[ZhDictFormat.fKeyOffs] = keyOffsOff;
  header[ZhDictFormat.fKeyStart] = keyStartOff;
  header[ZhDictFormat.fEntries] = entriesOff;
  header[ZhDictFormat.fTextBlob] = textBlobOff;
  header[ZhDictFormat.fSylBlob] = sylBlobOff;
  header[ZhDictFormat.fInitBlob] = initBlobOff;
  header[ZhDictFormat.fInitOffs] = initOffsOff;
  header[ZhDictFormat.fInitStart] = initStartOff;
  header[ZhDictFormat.fInitIdx] = initIdxOff;
  header[ZhDictFormat.fTotalLength] = total;
  for (var i = 0; i < header.length; i++) {
    bd.setUint32(ZhDictFormat.headerStart + i * 4, header[i], Endian.little);
  }

  out.setRange(keyBlobOff, keyBlobOff + keyBlob.length, keyBlob.toBytes());
  for (var i = 0; i < keyOffs.length; i++) {
    bd.setUint32(keyOffsOff + i * 4, keyOffs[i], Endian.little);
  }
  for (var i = 0; i < keyStart.length; i++) {
    bd.setUint32(keyStartOff + i * 4, keyStart[i], Endian.little);
  }
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    final off = entriesOff + i * ZhDictFormat.entryBytes;
    bd.setUint32(off, textRef[i], Endian.little);
    bd.setUint32(off + 4, sylRef[i], Endian.little);
    final score = (e.logP * 1000).round().clamp(-32000, 0);
    bd.setInt16(off + 8, score, Endian.little);
    out[off + 10] = utf8.encode(e.text).length;
    out[off + 11] = ascii.encode(e.syllables).length;
  }
  out.setRange(textBlobOff, textBlobOff + textBlob.length, textBlob.toBytes());
  out.setRange(sylBlobOff, sylBlobOff + sylBlob.length, sylBlob.toBytes());
  out.setRange(initBlobOff, initBlobOff + initBlob.length, initBlob.toBytes());
  for (var i = 0; i < initOffs.length; i++) {
    bd.setUint32(initOffsOff + i * 4, initOffs[i], Endian.little);
  }
  for (var i = 0; i < initStart.length; i++) {
    bd.setUint32(initStartOff + i * 4, initStart[i], Endian.little);
  }
  for (var i = 0; i < initIdx.length; i++) {
    bd.setUint32(initIdxOff + i * 4, initIdx[i], Endian.little);
  }

  if (stats != null) {
    stats
      ..entries = entries.length
      ..duplicates = duplicates
      ..keys = keys.length
      ..initials = initKeys.length
      ..bytes = total;
  }
  return out;
}

String _key(String syllables) => syllables.replaceAll("'", '');
