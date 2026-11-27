// SPDX-License-Identifier: GPL-3.0-or-later
//
// Arabic and Urdu language rules (Wave 3-C) and the word normalisation the dictionary converter
// uses (tool/arabic/normalize.dart).

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/arabic.dart';
import 'package:booboard/src/engine/lang/registry.dart';

import '../../../tool/arabic/normalize.dart';

void main() {
  group('rules', () {
    final ar = arabicRules('ar')!;
    final ur = arabicRules('ur')!;

    test('only ar and ur have Arabic rules', () {
      expect(arabicRules('en'), isNull);
      expect(arabicRules('hi'), isNull);
      expect(rulesForLanguage('ar').language, 'ar');
      expect(rulesForLanguage('ur').hasCase, isFalse);
    });

    test('Arabic has no case', () {
      expect(ar.hasCase, isFalse);
      expect(ur.hasCase, isFalse);
    });

    test('letters, harakat, tatweel and ZWNJ are word characters; spaces and digits are not', () {
      for (final ch in ['ب', 'ً', 'ـ', 'ی', '‌']) {
        expect(ar.isWordChar(ch), isTrue, reason: ch);
      }
      expect(ur.isWordChar('‌'), isTrue, reason: 'Urdu joins words with ZWNJ');
      for (final ch in [' ', '.', '،', '؟']) {
        expect(ar.isWordChar(ch), isFalse, reason: ch);
      }
    });

    test('Arabic punctuation swallows a preceding space and takes one after it', () {
      for (final p in ['،', '؛', '؟', '۔', '.', '!']) {
        expect(ar.removesSpaceBefore(p), isTrue, reason: p);
      }
      for (final p in ['،', '؛', '؟', '۔']) {
        expect(ar.addsSpaceAfter(p), isTrue, reason: p);
      }
      expect(ar.addsSpaceAfter(')'), isFalse, reason: 'no space after a closing bracket');
      expect(ar.spaceBefore('؟'), isNull, reason: 'no thin space before the question mark');
    });

    test('sentence ends: . ! ? ؟ and the Urdu full stop', () {
      for (final p in ['.', '!', '?', '؟', '۔']) {
        expect(ar.endsSentence(p), isTrue, reason: p);
      }
      expect(ar.endsSentence('،'), isFalse);
    });

    test('quotes: guillemets for Arabic, curly quotes for Urdu', () {
      expect(ar.quotes, ('«', '»'));
      expect(ur.quotes, ('“', '”'));
    });
  });

  group('normalisation', () {
    test('removes harakat and tatweel, keeps the letters', () {
      expect(normalizeArabicWord('مَرْحَبًا', 'ar'), 'مرحبا');
      expect(normalizeArabicWord('مـــرحبا', 'ar'), 'مرحبا');
      expect(normalizeArabicWord('اللّٰه', 'ar'), 'الله');
    });

    test('Arabic uses the Arabic yeh and kaf, Urdu the Persian ones', () {
      expect(normalizeArabicWord('كتاب', 'ar'), 'كتاب');
      expect(normalizeArabicWord('کتاب', 'ar'), 'كتاب');
      expect(normalizeArabicWord('كتاب', 'ur'), 'کتاب');
      expect(normalizeArabicWord('علي', 'ur'), 'علی');
      expect(normalizeArabicWord('علي', 'ar'), 'علي');
    });

    test('rejects Latin, digits, punctuation and single letters', () {
      expect(normalizeArabicWord('hello', 'ar'), isNull);
      expect(normalizeArabicWord('مرحبا2', 'ar'), isNull);
      expect(normalizeArabicWord('ب', 'ar'), isNull);
      expect(normalizeArabicWord('ـ', 'ar'), isNull);
      expect(normalizeArabicWord('ab', 'ur'), isNull);
    });

    test('words in running text, without punctuation or Latin', () {
      final words = arabicWordsIn('مرحبا بكم، هذا نص؟ hello 2024 اردو۔', 'ar').toList();
      expect(words, ['مرحبا', 'بكم', 'هذا', 'نص', 'اردو']);
      expect(arabicWordsIn('آپ کیسے ہیں۔', 'ur').toList(), ['آپ', 'کیسے', 'ہیں']);
    });

    test('an unknown language is an error', () {
      expect(() => normalizeArabicWord('كتاب', 'en'), throwsArgumentError);
    });
  });
}
