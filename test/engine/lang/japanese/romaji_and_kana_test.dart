// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/japanese/kana.dart';
import 'package:booboard/src/engine/lang/japanese/romaji.dart';

String _type(String romaji, {bool flush = true}) {
  final r = RomajiInput();
  for (final ch in romaji.split('')) {
    r.add(ch);
  }
  if (flush) r.flush();
  return r.text;
}

void main() {
  group('romaji to kana', () {
    test('plain syllables and the word nihongo', () {
      expect(_type('nihongo'), 'にほんご');
      expect(_type('aiueo'), 'あいうえお');
      expect(_type('sakura'), 'さくら');
    });

    test('youon and the sh/ch/j families', () {
      expect(_type('kyou'), 'きょう');
      expect(_type('shinkansen'), 'しんかんせん');
      expect(_type('chiisai'), 'ちいさい');
      expect(_type('jaja'), 'じゃじゃ');
      expect(_type('tenkyo'), 'てんきょ');
    });

    test('sokuon: doubled consonant and tchi', () {
      expect(_type('kitte'), 'きって');
      expect(_type('zasshi'), 'ざっし');
      expect(_type('matchi'), 'まっち');
      expect(_type('tt', flush: false), 'っt', reason: 'the second t waits for its vowel');
      expect(_type('tt'), 'っt', reason: 'an unfinished t is committed as typed');
    });

    test('n rules: nn, n apostrophe, n before a consonant, konnichi', () {
      expect(_type('nn'), 'ん');
      expect(_type("n'"), 'ん');
      expect(_type('kanji'), 'かんじ');
      expect(_type('konnichi'), 'こんにち');
      expect(_type('konnnichi'), 'こんんにち', reason: 'three n: ん, then na-row n');
    });

    test('a lone n at the end is ん; pending letters stay raw until they form a kana', () {
      expect(_type('an'), 'あん');
      expect(_type('k', flush: false), 'k');
      expect(_type('ky', flush: false), 'ky');
      expect(_type('kya'), 'きゃ');
    });

    test('dash is the long vowel mark', () {
      expect(_type('ra-men'), 'らーめん');
    });

    test('backspace removes the pending letter, then the last kana', () {
      final r = RomajiInput();
      for (final ch in 'nihk'.split('')) {
        r.add(ch);
      }
      expect(r.kana, 'にh', reason: 'an unmatched letter is kept as typed');
      expect(r.pending, 'k');
      r.backspace();
      expect(r.pending, '');
      expect(r.kana, 'にh');
      r.backspace();
      expect(r.kana, 'に');
    });
  });

  group('kana tools', () {
    test('katakana and full-width ASCII', () {
      expect(toKatakana('にほんご'), 'ニホンゴ');
      expect(toKatakana('ー'), 'ー');
      expect(toFullWidthAscii('ab1 '), 'ａｂ１　');
    });

    test('12-key multi-tap cycles the row in flick order', () {
      expect(tapCycleFor('あ'), ['あ', 'い', 'う', 'え', 'お']);
      expect(nextTapKana('お'), 'あ');
      expect(nextTapKana('ぇ'), isNull, reason: 'a small kana is in no multi-tap cycle');
      expect(nextTapKana('ん'), 'ー', reason: 'ん is in the わ cycle');
    });

    test('dakuten, handakuten and small kana cycles', () {
      expect(nextKanaModifier('か'), 'が');
      expect(nextKanaModifier('が'), 'か');
      expect(nextKanaModifier('は'), 'ば');
      expect(nextKanaModifier('ば'), 'ぱ');
      expect(nextKanaModifier('ぱ'), 'は');
      expect(nextKanaModifier('つ'), 'っ');
      expect(nextKanaModifier('っ'), 'づ');
      expect(nextKanaModifier('づ'), 'つ');
      expect(nextKanaModifier('や'), 'ゃ');
      expect(nextKanaModifier('ん'), isNull);
    });
  });
}
