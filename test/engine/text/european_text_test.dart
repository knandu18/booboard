// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wave 3-A: multilingual blending, missing dictionaries, accent and apostrophe folding, Cyrillic
// typing and the three-language timing.
import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/engine/dictionary/lexicon_factory.dart';
import 'package:booboard/src/engine/dictionary/text_fold.dart';
import 'package:booboard/src/engine/suggest/text_predictor.dart';

import 'support.dart';

/// Keys for rows of letters, each key 36 x 48 dp with 2 dp gaps and row offsets in key widths.
KeyboardGeometry _rowsGeometry(String layoutId, List<String> rows, List<double> offsets) {
  const w = 36.0;
  const h = 48.0;
  final keys = <String, Rect>{};
  for (var r = 0; r < rows.length; r++) {
    final chars = rows[r].runes.toList();
    for (var c = 0; c < chars.length; c++) {
      final ch = String.fromCharCode(chars[c]);
      keys[ch] = Rect.fromLTWH((offsets[r] + c) * w + 1, r * h + 2, w - 2, h - 4);
    }
  }
  return KeyboardGeometry(layoutId: layoutId, size: Size(w * 12, rows.length * h), keys: keys);
}

final KeyboardGeometry _jcuken = _rowsGeometry('test-jcuken', ['йцукенгшщзх', 'фывапролджэ', 'ячсмитьбю'], [0, 0, 0.5]);

void main() {
  late LexiconSource lexicons;
  final english = qwertyGeometry();

  Future<BooBoardTextPredictor> predictorFor(List<LanguageId> languages, {KeyboardGeometry? geometry}) async {
    final p = BooBoardTextPredictor(
      lexicons: lexicons,
      store: InMemorySecureBlobStore(),
      saveDelay: const Duration(hours: 1),
    );
    await p.setActiveLanguages(languages);
    p.setGeometry(geometry ?? english);
    return p;
  }

  setUpAll(() {
    lexicons = createLexiconSource(packs: FilePackRepository());
  });

  group('languages without a dictionary', () {
    test('a language with no dictionary is skipped and the others still suggest', () async {
      final p = await predictorFor(['xx', 'es']);
      expect(p.isKnownWord('hola'), isTrue);
      final result = p.suggest(typing('graci', taps: centreTaps(english, 'graci')));
      expect(result.suggestions.map((s) => s.text), contains('gracias'));
    });

    test('nothing usable falls back to English', () async {
      final p = await predictorFor(['xx']);
      expect(p.isKnownWord('the'), isTrue);
    });
  });

  group('blending', () {
    test('a word that any active dictionary knows is never auto-corrected', () async {
      // "die" is German and English: it must stay, whichever language is first.
      for (final languages in [
        ['de', 'en'],
        ['en', 'de'],
      ]) {
        final p = await predictorFor(languages);
        final result = p.suggest(typing('die', taps: centreTaps(english, 'die')));
        expect(result.autoCorrection, isNull, reason: '$languages');
      }
    });

    test('words from the second active language are suggested too', () async {
      // "tambien" is only a Spanish word (with its accent); English has no candidate for it.
      final p = await predictorFor(['en', 'es']);
      final result = p.suggest(typing('tambien', taps: centreTaps(english, 'tambien')));
      final found = result.suggestions.firstWhere((s) => s.text == 'también', orElse: () => result.suggestions.first);
      expect(found.text, 'también');
      expect(found.language, 'es');
    });

    test('typed words that are valid in English are kept with a Spanish blend', () async {
      final p = await predictorFor(['es', 'en']);
      final result = p.suggest(typing('the', taps: centreTaps(english, 'the')));
      expect(result.autoCorrection, isNull);
      expect(result.suggestions.first.text, 'the');
    });
  });

  group('learning', () {
    test('a word no dictionary knows is learned in the active (first) language', () async {
      final p = await predictorFor(['es', 'en']);
      p.onWordCommitted('zorblax', previousWords: const [], allowLearning: true);
      p.onWordCommitted('zorblax', previousWords: const [], allowLearning: true);
      expect(p.learnedWords('es').map((e) => e.word), contains('zorblax'));
      expect(p.learnedWords('en').map((e) => e.word), isNot(contains('zorblax')));
    });
  });

  group('accents and apostrophes', () {
    test('typing without accents finds accented words', () async {
      final p = await predictorFor(['fr']);
      final result = p.suggest(typing('cafe', taps: centreTaps(english, 'cafe')));
      expect(result.suggestions.map((s) => s.text), contains('café'));
    });

    test('ß folds to ss for lookup only, and a typed ss is never rewritten to ß', () async {
      final p = await predictorFor(['de']);
      final result = p.suggest(typing('strasse', taps: centreTaps(english, 'strasse')));
      expect(result.autoCorrection?.text, isNot(contains('ß')));
      expect(result.suggestions.first.text, 'strasse');
    });

    test('ё and е stay different letters', () {
      expect(foldKey('ё'), 'ё');
      expect(foldKey('е'), 'е');
      expect(foldKey('Ёж'), isNot(foldKey('еж')));
    });

    test('Arabic harakat and tatweel fold away; the letters stay', () {
      expect(foldKey('مُحَمَّد'), 'محمد');
      expect(foldKey('كتـــاب'), 'كتاب');
      expect(foldKey('أ'), isNot(foldKey('ا')));
    });

    test('Ukrainian apostrophes match each other', () {
      expect(foldKey('п’ять'), foldKey("п'ять"));
      expect(foldKey('пʼять'), foldKey("п'ять"));
    });

    test('Cyrillic and Devanagari are folded as their own letters', () {
      expect(foldKey('Привет'), 'привет');
      expect(foldKey('नमस्ते'), 'नमस्ते');
    });
  });

  group('Cyrillic typing', () {
    test('a Russian prefix completes from the Russian dictionary', () async {
      final p = await predictorFor(['ru'], geometry: _jcuken);
      expect(p.isKnownWord('приветствие'), isTrue);
      final result = p.suggest(typing('приветст', taps: centreTaps(_jcuken, 'приветст')));
      expect(result.suggestions.map((s) => s.text), contains('приветствие'));
    });

    test('Ukrainian words with і and ї are known', () async {
      final p = await predictorFor(['uk'], geometry: _jcuken);
      expect(p.isKnownWord('ніч'), isTrue);
    });
  });

  group('timing', () {
    test('suggest with three blended languages stays fast', () async {
      final p = await predictorFor(['en', 'de', 'fr']);
      final words = ['hun', 'ich', 'bon', 'the', 'tage', 'maison', 'hallo', 'wor'];
      final taps = {for (final w in words) w: centreTaps(english, w)};
      // Warm up, then time many calls.
      for (final w in words) {
        p.suggest(typing(w, taps: taps[w]!));
      }
      final stopwatch = Stopwatch()..start();
      const rounds = 50;
      for (var i = 0; i < rounds; i++) {
        for (final w in words) {
          p.suggest(typing(w, taps: taps[w]!));
        }
      }
      stopwatch.stop();
      final perCall = stopwatch.elapsedMicroseconds / (rounds * words.length) / 1000;
      // ignore: avoid_print
      print('suggest with 3 languages: ${perCall.toStringAsFixed(2)} ms per call (debug test build)');
      expect(perCall, lessThan(50), reason: 'debug build; release is measured in the report');
    });
  });
}
