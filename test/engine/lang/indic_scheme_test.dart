// SPDX-License-Identifier: GPL-3.0-or-later
//
// The rule-based romanisation (English letters to native script) and the Indic punctuation rules.
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/indic.dart';
import 'package:booboard/src/engine/lang/indic/scheme.dart';
import 'package:booboard/src/engine/lang/registry.dart';

void main() {
  group('Hindi scheme', () {
    test('common words convert', () {
      expect(hindiScheme.convert('namaste'), 'नमस्ते');
      expect(hindiScheme.convert('kya'), 'क्या');
      expect(hindiScheme.convert('dhanyavaad'), 'धन्यवाद');
      expect(hindiScheme.convert('hai'), 'है');
      expect(hindiScheme.convert('bharat'), 'भरत', reason: 'the rules alone; the table knows भारत');
    });

    test('a word-final consonant keeps no virama (schwa is silent)', () {
      expect(hindiScheme.convert('namak'), 'नमक');
    });

    test('anusvara before a consonant, not before y or v', () {
      expect(hindiScheme.convert('ganga'), 'गंगा');
      expect(hindiScheme.convert('sangh'), 'संघ');
      expect(hindiScheme.convert('dhanyavaad'), isNot(contains('ं')));
    });

    test('digraphs and retroflex letters', () {
      expect(hindiScheme.convert('chhotta'), 'छोटा');
      expect(hindiScheme.convert('shabd'), 'शब्द');
      expect(hindiScheme.convert('tt'), 'ट');
    });

    test('non-letters pass through, empty stays empty', () {
      expect(hindiScheme.convert('a1-b'), contains('1'));
      expect(hindiScheme.convert('a1-b'), contains('-'));
      expect(hindiScheme.convert(''), '');
    });

    test('any typed word converts to something', () {
      for (final w in ['zzz', 'qwerty', 'xyz', 'a', 'ok']) {
        expect(hindiScheme.convert(w), isNotEmpty, reason: w);
      }
    });
  });

  group('other scripts', () {
    test('Marathi has its own lateral', () {
      expect(marathiScheme.convert('lh'), 'ळ');
    });

    test('Bengali, Tamil and Telugu write native letters with their own viramas', () {
      expect(bengaliScheme.convert('namaste'), 'নমস্তে');
      expect(tamilScheme.convert('tamil'), 'தமில்', reason: 'a final consonant takes a pulli');
      expect(teluguScheme.convert('namaste'), 'నమస్తే');
    });

    test('schemeFor covers exactly the five languages', () {
      for (final l in ['hi', 'mr', 'bn', 'ta', 'te']) {
        expect(schemeFor(l), isNotNull, reason: l);
        expect(schemeFor(l)!.language, l);
      }
      expect(schemeFor('en'), isNull);
    });
  });

  group('punctuation and word rules', () {
    test('danda ends a sentence in Hindi, Marathi and Bengali only', () {
      for (final l in ['hi', 'mr', 'bn']) {
        final r = rulesForLanguage(l);
        expect(r.endsSentence('।'), isTrue, reason: l);
        expect(r.removesSpaceBefore('।'), isTrue, reason: l);
        expect(r.addsSpaceAfter('॥'), isTrue, reason: l);
      }
      final ta = rulesForLanguage('ta');
      expect(ta.endsSentence('।'), isFalse);
      expect(ta.endsSentence('.'), isTrue);
    });

    test('no case, and Latin letters count as word characters (English-letter typing)', () {
      final r = rulesForLanguage('hi');
      expect(r.hasCase, isFalse);
      expect(r.isWordChar('a'), isTrue);
      expect(r.isWordChar('ह'), isTrue);
      expect(r.isWordChar('ा'), isTrue, reason: 'vowel sign');
      expect(r.isWordChar(' '), isFalse);
    });

    test('indicRules is null for non-Indic languages', () {
      expect(indicRules('de'), isNull);
      expect(indicRules('hi'), isNotNull);
    });
  });
}
