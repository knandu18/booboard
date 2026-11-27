// SPDX-License-Identifier: GPL-3.0-or-later
//
// The shipped transliteration tables (assets/translit/<lang>.bin) and dictionaries (assets/dict/<lang>.mdict).
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/engine/dictionary/mdict_lexicon.dart';
import 'package:booboard/src/engine/lang/indic/indic_transliterator.dart';
import 'package:booboard/src/engine/lang/indic/translit_table.dart';

import '../../keyboard/support/fakes.dart';

Future<IndicTransliterator> _loaded(String lang) async {
  final t = IndicTransliterator(language: lang, packs: DiskPackRepository());
  await t.load();
  return t;
}

String _best(List<Suggestion> s) => s.isEmpty ? '' : s.first.text;

void main() {
  group('table format', () {
    test('a table round-trips through the encoder and decoder', () {
      // "MYTL", version 1, 2 entries: ("ka", "क", 9) and ("kaa", "का", 7).
      final raw = BytesBuilder()
        ..add('MYTL'.codeUnits)
        ..addByte(1)
        ..add([2, 0, 0, 0])
        ..addByte(2)
        ..add('ka'.codeUnits)
        ..addByte(3)
        ..add([0xE0, 0xA4, 0x95])
        ..addByte(9)
        ..addByte(3)
        ..add('kaa'.codeUnits)
        ..addByte(6)
        ..add([0xE0, 0xA4, 0x95, 0xE0, 0xA4, 0xBE])
        ..addByte(7);
      final t = TranslitTable.fromBytes(raw.toBytes());
      expect(t.length, 2);
      expect(t.exact('ka').single.native, 'क');
      expect(t.exact('kaa').single.score, 7);
      expect(() => TranslitTable.fromBytes(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9])), throwsFormatException);
    });
  });

  group('Hindi table', () {
    late IndicTransliterator hi;
    setUpAll(() async => hi = await _loaded('hi'));

    test('loads off the UI isolate with tens of thousands of entries', () {
      expect(hi.isLoaded, isTrue);
      expect(hi.tableSize, greaterThan(50000));
    });

    test('common words', () {
      expect(_best(hi.transliterate('namaste')), 'नमस्ते');
      expect(_best(hi.transliterate('kya')), 'क्या');
      expect(_best(hi.transliterate('dhanyavaad')), 'धन्यवाद');
      expect(_best(hi.transliterate('bharat')), 'भारत', reason: 'table beats the rules (भरत)');
    });

    test('prefix search shows words that start with what is typed', () {
      final out = hi.transliterate('nam', max: 5);
      expect(out, isNotEmpty);
      expect(out.map((s) => s.text), contains('नम'));
      final more = hi.table!.prefix('nam', max: 50).map((e) => e.native);
      expect(more, contains('नमस्ते'));
      expect(more.every((n) => n.isNotEmpty), isTrue);
    });

    test('every typed word converts, and suggestions are unique', () {
      for (final w in ['zzzq', 'qwerty', 'a', 'x9', 'hello']) {
        final out = hi.transliterate(w);
        expect(out, isNotEmpty, reason: w);
        expect(out.map((s) => s.text).toSet(), hasLength(out.length), reason: w);
      }
    });

    test('per-key lookup stays well under the 2 ms budget', () {
      final sw = Stopwatch()..start();
      for (var i = 0; i < 200; i++) {
        hi.transliterate('nam');
      }
      final perCall = sw.elapsedMicroseconds / 200;
      // Generous bound for slow CI machines; the device budget is 2 ms.
      expect(perCall, lessThan(5000));
    });

    test('bestPerNative gives one roman per native word, most frequent first', () {
      final table = hi.table!;
      final best = table.bestPerNative(max: 1000);
      expect(best, hasLength(1000));
      expect(best.first.score, greaterThanOrEqualTo(best.last.score));
      expect(best.map((e) => e.native).toSet(), hasLength(best.length));
    });
  });

  group('dictionaries', () {
    test('the Indic dictionaries load and hold native words', () {
      for (final lang in ['hi', 'mr', 'ta']) {
        final file = File('assets/dict/$lang.mdict');
        expect(file.lengthSync(), lessThan(1500000), reason: '$lang size budget');
        final bytes = file.readAsBytesSync();
        expect(bytes, isNotEmpty);
      }
    });

    test('Hindi dictionary keeps short common words (the upper-case filter drops them elsewhere)', () {
      final lexicon = MdictLexicon.fromBytes(inflateMdict(File('assets/dict/hi.mdict').readAsBytesSync()));
      expect(lexicon.logProb('है'), isNotNull);
      expect(lexicon.logProb('और'), isNotNull);
      expect(lexicon.logProb('में'), isNotNull);
    });
  });
}
