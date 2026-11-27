// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wave 5-A corrupt-input tests. Every parser that reads a file the app ships or a file the user can
// import is fed truncated, mutated and random input. The contract under test: a parser returns a value
// or throws a typed error (FormatException, RangeError from a bounds check, or BackupFormatException).
// It never throws anything else, and it returns quickly.
//
// SEC-09, SEC-10 and SEC-11 (docs/security/audit.md) are fixed: their tests run. A test with
// `skip: 'SEC-..'` would pin a finding that is still open.
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/dictionary/mdict_lexicon.dart';
import 'package:booboard/src/engine/dictionary/mdict_writer.dart';
import 'package:booboard/src/engine/lang/chinese/zh_dictionary.dart';
import 'package:booboard/src/engine/lang/indic/translit_table.dart';
import 'package:booboard/src/engine/lang/japanese/japanese_dictionary.dart';
import 'package:booboard/src/engine/learn/learned_data.dart';
import 'package:booboard/src/features/emoji/emoji_data.dart';
import 'package:booboard/src/security/backup/backup_collect.dart';
import 'package:booboard/src/security/backup/backup_payload.dart';

/// Passes when [body] returns or throws one of the typed errors a parser may use. Anything else fails.
void expectContained(void Function() body) {
  try {
    body();
  } on FormatException {
    return;
  } on RangeError {
    return;
  } on BackupFormatException {
    return;
  } on Object catch (e) {
    fail('parser threw ${e.runtimeType}, not a typed error: $e');
  }
}

Uint8List _randomBytes(Random r, int length) => Uint8List.fromList([for (var i = 0; i < length; i++) r.nextInt(256)]);

Uint8List _u32le(int v) => Uint8List.fromList([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);

Uint8List _concat(List<Uint8List> parts) {
  final out = BytesBuilder(copy: false);
  for (final p in parts) {
    out.add(p);
  }
  return out.toBytes();
}

void main() {
  group('backup payload (.boobackup plain text)', () {
    final learned = LearnedData('en')
      ..commitWord('hello', 'hello', 1000, novel: false)
      ..blocked.add('spam');
    final valid = BackupPayload(
      createdAt: DateTime.utc(2026, 11, 21),
      appVersion: '1.0.0+1',
      contents: BackupContents(learned: {'learned_en': learned.encode()}),
    ).encode();

    test('a valid payload round-trips', () {
      final decoded = BackupPayload.decode(valid);
      expect(decoded.contents.learned.keys, ['learned_en']);
    });

    test('every truncation is rejected with BackupFormatException', () {
      for (var n = 0; n < valid.length; n++) {
        expect(
          () => BackupPayload.decode(Uint8List.sublistView(valid, 0, n)),
          throwsA(isA<BackupFormatException>()),
          reason: 'prefix of $n bytes',
        );
      }
    });

    test('random bytes and random mutations never throw anything but BackupFormatException', () {
      final r = Random(20261123);
      for (var i = 0; i < 2000; i++) {
        final bytes = _randomBytes(r, r.nextInt(200));
        expectContained(() => BackupPayload.decode(bytes));
      }
      for (var i = 0; i < 1000; i++) {
        final bytes = Uint8List.fromList(valid);
        bytes[r.nextInt(bytes.length)] = r.nextInt(256);
        expectContained(() => BackupPayload.decode(bytes));
      }
    });

    test('a payload over the 64 MiB limit is refused before parsing', () {
      expect(
        () => BackupPayload.decode(Uint8List(kMaxBackupBytes + 1)),
        throwsA(isA<BackupFormatException>().having((e) => e.rule, 'rule', 'too_large')),
      );
    });
  });

  group('learned data and clipboard codecs (they must never throw)', () {
    test('LearnedData.decode returns empty data for random bytes', () {
      final r = Random(7);
      for (var i = 0; i < 1000; i++) {
        final decoded = LearnedData.decode('en', _randomBytes(r, r.nextInt(300)));
        expect(decoded.words, isA<Map<String, LearnedWord>>());
      }
    });

    test('ClipboardBackupCodec.decodeEntries returns null or a list for random bytes', () {
      final r = Random(11);
      for (var i = 0; i < 1000; i++) {
        expectContained(() => ClipboardBackupCodec.decodeEntries(_randomBytes(r, r.nextInt(300))));
      }
    });
  });

  group('mdict dictionary (assets/dict, all languages)', () {
    final source = DictSource(
      language: 'en',
      words: [DictWord('hello', -5.0), DictWord('world', -6.0, offensive: true), DictWord('the', -2.0)],
      bigrams: [DictBigram('hello', 'world', -1.0)],
    );

    test('a valid dictionary opens with its word count', () {
      final lexicon = MdictLexicon.fromBytes(buildMdict(source));
      expect(lexicon.size, 3);
    });

    test('every truncation of the raw and the zlib forms is a typed error', () {
      for (final compress in [false, true]) {
        final bytes = buildMdict(source, compress: compress);
        for (var n = 0; n < bytes.length; n++) {
          expectContained(() => MdictLexicon.fromBytes(Uint8List.sublistView(bytes, 0, n)));
        }
      }
    });

    test('mutating each header byte never throws anything but a typed error', () {
      final bytes = buildMdict(source);
      for (var i = 0; i < 40 && i < bytes.length; i++) {
        for (final v in [0x00, 0x7f, 0xff]) {
          final copy = Uint8List.fromList(bytes)..[i] = v;
          expectContained(() => MdictLexicon.fromBytes(copy));
        }
      }
    });

    test('a truncated file is reported as FormatException', () {
      final bytes = buildMdict(source);
      expect(
        () => MdictLexicon.fromBytes(Uint8List.sublistView(bytes, 0, bytes.length - 1)),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('translit table (assets/translit)', () {
    /// One entry: roman "ka" to native "क" with score 1, in the format tool/indic/build_data.py writes.
    Uint8List table({int count = 1}) => _concat([
      Uint8List.fromList('MYTL'.codeUnits),
      Uint8List.fromList([1]),
      _u32le(count),
      Uint8List.fromList([2, 0x6b, 0x61, 3, 0xe0, 0xa4, 0x95, 1]),
    ]);

    test('a valid table parses', () {
      expect(() => TranslitTable.fromBytes(table()), returnsNormally);
    });

    test('bad magic and unsupported versions are FormatException', () {
      expect(() => TranslitTable.fromBytes(Uint8List(16)), throwsFormatException);
      final badVersion = table()..[4] = 9;
      expect(() => TranslitTable.fromBytes(badVersion), throwsFormatException);
    });

    test('every truncation of a valid table is a typed error', () {
      final bytes = table();
      for (var n = 0; n < bytes.length; n++) {
        expectContained(() => TranslitTable.fromBytes(Uint8List.sublistView(bytes, 0, n)));
      }
    });

    test('a truncated table is reported as FormatException', () {
      final bytes = table();
      expect(() => TranslitTable.fromBytes(Uint8List.sublistView(bytes, 0, bytes.length - 2)), throwsFormatException);
    });

    test('a count header far beyond the data is refused without a large allocation', () {
      // SEC-09: the count is checked against the file size before anything is allocated.
      expect(() => TranslitTable.fromBytes(table(count: 0xFFFFFFFF)), throwsFormatException);
    });
  });

  group('zh.kdict (Chinese pack)', () {
    // ZhDictFormat: 8-byte magic and version, then 20 u32 header fields; total length is field 15.
    Uint8List zhFile({int length = ZhDictFormat.dataStart, List<int> fields = const []}) {
      final bytes = Uint8List(length);
      bytes.setRange(0, 4, [0x4b, 0x5a, 0x44, 0x31]);
      bytes.setRange(4, 8, _u32le(ZhDictFormat.version));
      for (var i = 0; i < fields.length; i++) {
        bytes.setRange(ZhDictFormat.headerStart + i * 4, ZhDictFormat.headerStart + i * 4 + 4, _u32le(fields[i]));
      }
      bytes.setRange(
        ZhDictFormat.headerStart + ZhDictFormat.fTotalLength * 4,
        ZhDictFormat.headerStart + ZhDictFormat.fTotalLength * 4 + 4,
        _u32le(length),
      );
      return bytes;
    }

    test('a header-only dictionary opens and has no entries', () {
      final dict = ZhDictionary.fromBytes(zhFile());
      expect(dict.entriesFor('ni'), isEmpty);
    });

    test('short files, wrong magic, wrong version and a length mismatch are FormatException', () {
      expect(() => ZhDictionary.fromBytes(Uint8List(10)), throwsFormatException);
      final magic = zhFile()..[0] = 0x00;
      expect(() => ZhDictionary.fromBytes(magic), throwsFormatException);
      final version = zhFile()..setRange(4, 8, _u32le(99));
      expect(() => ZhDictionary.fromBytes(version), throwsFormatException);
      final mismatch = zhFile();
      expect(() => ZhDictionary.fromBytes(Uint8List.fromList([...mismatch, 0])), throwsFormatException);
    });

    test('random bytes are a typed error or a dictionary, never another error', () {
      final r = Random(3);
      for (var i = 0; i < 500; i++) {
        final bytes = _randomBytes(r, r.nextInt(200));
        expectContained(() => ZhDictionary.fromBytes(bytes));
      }
    });

    test('header counts that point past the end are rejected when the file opens', () {
      // SEC-11: every table must lie inside the file when it opens.
      final bytes = zhFile(fields: [5, 5, 5, 5, 4, 1000000, 1000000, 1000000]);
      expect(() => ZhDictionary.fromBytes(bytes), throwsFormatException);
    });
  });

  group('japanese lexicon (japanese.lex.gz + japanese.conn.gz)', () {
    /// The smallest valid pair: no readings, no entries, no connection costs.
    Uint8List emptyLex({int extra = 0}) {
      final lex = Uint8List(40 + extra);
      lex.setRange(0, 4, 'KJLX'.codeUnits);
      lex[4] = JapaneseLexiconFormat.version;
      return lex;
    }

    Uint8List emptyConn({int extra = 0}) {
      final conn = Uint8List(8 + extra);
      conn.setRange(0, 4, 'KJCN'.codeUnits);
      return conn;
    }

    test('the smallest valid pair opens', () {
      expect(() => JapaneseDictionary.fromBytes(emptyLex(), emptyConn()), returnsNormally);
    });

    test('bad magic, wrong version and size mismatches are FormatException', () {
      expect(() => JapaneseDictionary.fromBytes(Uint8List(8), emptyConn()), throwsFormatException);
      final badLex = emptyLex()..[0] = 0x00;
      expect(() => JapaneseDictionary.fromBytes(badLex, emptyConn()), throwsFormatException);
      final badVersion = emptyLex()..[4] = 7;
      expect(() => JapaneseDictionary.fromBytes(badVersion, emptyConn()), throwsFormatException);
      expect(() => JapaneseDictionary.fromBytes(emptyLex(extra: 1), emptyConn()), throwsFormatException);
      expect(() => JapaneseDictionary.fromBytes(emptyLex(), emptyConn(extra: 1)), throwsFormatException);
      final badConn = emptyConn()..[0] = 0x00;
      expect(() => JapaneseDictionary.fromBytes(emptyLex(), badConn), throwsFormatException);
    });

    test('random bodies behind the right magic are a typed error or a dictionary', () {
      final r = Random(5);
      for (var i = 0; i < 500; i++) {
        final lex = _randomBytes(r, 28 + r.nextInt(64))..setRange(0, 4, 'KJLX'.codeUnits);
        lex[4] = JapaneseLexiconFormat.version;
        final conn = _randomBytes(r, 8 + r.nextInt(16))..setRange(0, 4, 'KJCN'.codeUnits);
        expectContained(() => JapaneseDictionary.fromBytes(lex, conn));
      }
    });
  });

  group('emoji data (emoji.dat, keyword tables)', () {
    test('random bytes are refused as a typed error', () {
      final r = Random(9);
      for (var i = 0; i < 200; i++) {
        expectContained(() => decodeEmojiData(_randomBytes(r, r.nextInt(128))));
      }
    });
  });
}
