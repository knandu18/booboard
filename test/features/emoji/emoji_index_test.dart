// SPDX-License-Identifier: GPL-3.0-or-later
//
// Emoji data and search, against the real assets in assets/emoji (built by tool/build_emoji.dart).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/features/emoji/emoji_data.dart';
import 'package:booboard/src/features/emoji/emoji_index.dart';

Uint8List _asset(String name) => File('assets/emoji/$name').readAsBytesSync();

int _itemOf(EmojiData data, String text) => data.items.indexWhere((i) => i.text == text);

void main() {
  late EmojiData data;

  setUpAll(() {
    data = decodeEmojiData(_asset('emoji.dat'));
  });

  group('emoji catalogue', () {
    test('reads the Unicode version and groups, with skin tones under the base', () {
      expect(data.unicodeVersion, '18.0');
      expect(data.items.length, greaterThan(2000));
      expect(data.groups, contains('Smileys & Emotion'));
      expect(data.groupIndex('Flags'), greaterThanOrEqualTo(0));
      final wave = _itemOf(data, '👋');
      expect(wave, greaterThanOrEqualTo(0));
      expect(data.textOf(wave * refStride), '👋');
      expect(data.textOf(wave * refStride + 3), '👋🏽');
      expect(data.nameOf(wave * refStride + 3), 'waving hand: medium skin tone');
      expect(data.hasRef(wave * refStride + 3), isTrue);
    });

    test('a tone the item does not have is not a ref, and falls back to the base text', () {
      final pizza = _itemOf(data, '🍕');
      expect(data.hasRef(pizza * refStride + 2), isFalse);
      expect(data.textOf(pizza * refStride + 2), '🍕');
      expect(data.hasRef(pizza * refStride + 1), isFalse);
    });

    test('no skin-tone swatch is offered as an emoji of its own', () {
      expect(data.items.any((i) => i.text == '🏻'), isFalse);
      // An item with exactly one skin-tone modifier is always a variant of a base, never an item of its own.
      // Couples and same-tone pairs carry two modifiers and are items.
      bool singleTone(String text) => text.runes.where((r) => r >= 0x1F3FB && r <= 0x1F3FF).length == 1;
      expect(data.items.where((i) => i.tones == null && singleTone(i.text)), isEmpty);
    });

    test('rejects an unknown format version', () {
      final bytes = gzip.encode(utf8.encode(jsonEncode({'format': 2, 'groups': [], 'subgroups': [], 'items': []})));
      expect(() => decodeEmojiData(Uint8List.fromList(bytes)), throwsFormatException);
    });
  });

  group('keyword table', () {
    test('keys are sorted and every keyword has refs', () {
      final en = decodeKeywordTable('en', _asset('keywords_en.dat'));
      expect(en.keys.length, greaterThan(5000));
      for (var i = 1; i < en.keys.length; i++) {
        expect(en.keys[i - 1].compareTo(en.keys[i]), lessThan(0), reason: 'key ${en.keys[i]} out of order');
      }
      for (final refs in en.refs) {
        expect(refs, isNotEmpty);
      }
      final pizza = _itemOf(data, '🍕');
      expect(en.shortNames[pizza * refStride], 'pizza');
    });
  });

  group('search', () {
    late EmojiIndex en;
    late EmojiIndex enAndEs;

    setUpAll(() {
      en = buildEmojiIndex(
        emojiGz: _asset('emoji.dat'),
        languages: const ['en'],
        keywordGz: [_asset('keywords_en.dat')],
      );
      enAndEs = buildEmojiIndex(
        emojiGz: _asset('emoji.dat'),
        languages: const ['en', 'es'],
        keywordGz: [_asset('keywords_en.dat'), _asset('keywords_es.dat')],
      );
    });

    test('a whole keyword finds its emoji first', () {
      final results = en.search('pizza');
      expect(results, isNotEmpty);
      expect(data.items[results.first].text, '🍕');
    });

    test('a prefix finds emoji, and a word inside a phrase counts too', () {
      final pizza = _itemOf(data, '🍕');
      expect(en.search('pizz'), contains(pizza));
      expect(en.search('grinning'), contains(_itemOf(data, '😀')));
    });

    test('search is case-insensitive, and blank input finds nothing', () {
      expect(en.search('PIZZA').first, en.search('pizza').first);
      expect(en.search('   '), isEmpty);
      expect(en.search(''), isEmpty);
    });

    test('results are capped and each item appears once', () {
      final results = en.search('a', limit: 25);
      expect(results.length, lessThanOrEqualTo(25));
      expect(results.toSet().length, results.length);
    });

    test('a language only matches when it is in the index', () {
      expect(en.search('perro'), isEmpty);
      expect(enAndEs.search('perro'), isNotEmpty);
    });

    test('exactRef gives the base emoji for a whole word, and -1 otherwise', () {
      final pizza = _itemOf(data, '🍕');
      expect(en.exactRef('pizza'), pizza * refStride);
      expect(en.exactRef('pizz'), -1);
      expect(enAndEs.exactRef('perro'), greaterThanOrEqualTo(0));
    });

    test('an exact keyword never suggests a skin-tone variant', () {
      for (final ref in en.exact.values) {
        expect(ref % refStride, 0);
      }
    });

    test('a prefix search over every language stays well under the 5 ms budget (generous in debug builds)', () {
      final sw = Stopwatch();
      var worst = 0;
      for (final q in ['a', 'ch', 'lov', 'smi', 'pizza', 'fa']) {
        sw
          ..reset()
          ..start();
        enAndEs.search(q);
        sw.stop();
        if (sw.elapsedMicroseconds > worst) worst = sw.elapsedMicroseconds;
      }
      expect(worst, lessThan(50000), reason: 'worst search took $worst us');
    });
  });
}
