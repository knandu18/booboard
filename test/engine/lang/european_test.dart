// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wave 3-A: language info and punctuation rules of the European languages.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/engine/lang/registry.dart';
import 'package:booboard/src/features/emoji/emoji_repository.dart';
import 'package:booboard/src/settings/sections/language_settings.dart';

void main() {
  group('European language info', () {
    test('every language is in the registry with its currency and domains', () {
      for (final id in ['es', 'fr', 'de', 'pt-BR', 'pt-PT', 'id', 'fil', 'ru', 'uk']) {
        final info = languageInfo(id);
        expect(info.id, id);
        expect(isKnownLanguage(id), isTrue, reason: id);
        expect(info.domains, isNotEmpty, reason: id);
        expect(info.currency, isNotEmpty, reason: id);
        expect(info.layouts, isNotEmpty, reason: id);
      }
    });

    test('pt-BR and pt-PT each get their own entry and dictionary id', () {
      expect(languageInfo('pt-BR').nativeName, isNot(languageInfo('pt-PT').nativeName));
      expect(languageInfo('pt-BR').currency, r'R$');
    });

    test('the default layout is the first one and the layout lookup falls back to it', () {
      expect(languageInfo('fr').defaultLayout.id, 'azerty');
      expect(languageInfo('de').defaultLayout.id, 'qwertz');
      expect(languageInfo('de').layout('qwertz_umlaut')?.name, 'QWERTZ (ÄÖÜ keys)');
      expect(languageInfo('de').layout('no-such-layout'), isNull);
    });

    test('Cyrillic languages type Cyrillic and are not right-to-left', () {
      expect(languageInfo('ru').script, 'Cyrl');
      expect(languageInfo('uk').script, 'Cyrl');
      expect(languageInfo('ru').isRtl, isFalse);
    });

    test('blending: European languages that share a script are blended with English-like layouts', () {
      final settings = _settings(active: 'de', enabled: ['de', 'en', 'fr'], multilingual: true);
      expect(blendedLanguages(settings), ['de', 'en', 'fr']);
      final off = _settings(active: 'de', enabled: ['de', 'en', 'fr'], multilingual: false);
      expect(blendedLanguages(off), ['de']);
    });

    test('blending never mixes Latin and Cyrillic', () {
      final settings = _settings(active: 'ru', enabled: ['ru', 'en', 'uk'], multilingual: true);
      expect(blendedLanguages(settings), ['ru', 'uk']);
    });
  });

  group('European punctuation rules', () {
    test('French: a narrow no-break space before ; : ! ? and inside « »', () {
      final fr = rulesForLanguage('fr');
      for (final mark in [';', ':', '!', '?']) {
        expect(fr.spaceBefore(mark), ' ', reason: mark);
        expect(fr.removesSpaceBefore(mark), isFalse, reason: mark);
      }
      expect(fr.spaceBefore('.'), isNull);
      expect(fr.quotes.$1, '« ');
      expect(fr.quotes.$2, ' »');
    });

    test('French: elisions are part of words', () {
      final fr = rulesForLanguage('fr');
      expect(fr.isWordChar("'"), isTrue);
      expect(fr.isWordChar('’'), isTrue);
      expect(fr.isWordChar('é'), isTrue);
    });

    test('German: „ and “ quotes; sentence ends like English', () {
      final de = rulesForLanguage('de');
      expect(de.quotes, ('„', '“'));
      expect(de.endsSentence('.'), isTrue);
      expect(de.addsSpaceAfter(','), isTrue);
    });

    test('Spanish: ¿ and ¡ never take a space after them; “ ” quotes', () {
      final es = rulesForLanguage('es');
      expect(es.addsSpaceAfter('¿'), isFalse);
      expect(es.addsSpaceAfter('¡'), isFalse);
      expect(es.addsSpaceAfter('.'), isTrue);
      expect(es.quotes, ('“', '”'));
      expect(es.spaceBefore('?'), isNull);
    });

    test('Portuguese: “ ” quotes for both variants', () {
      expect(rulesForLanguage('pt-BR').quotes, ('“', '”'));
      expect(rulesForLanguage('pt-PT').quotes, ('“', '”'));
    });

    test('Russian and Ukrainian: « » quotes and the apostrophe inside Ukrainian words', () {
      expect(rulesForLanguage('ru').quotes, ('«', '»'));
      final uk = rulesForLanguage('uk');
      expect(uk.quotes, ('«', '»'));
      expect(uk.isWordChar('ʼ'), isTrue);
      expect(uk.isWordChar("'"), isTrue);
      expect(uk.isWordChar('і'), isTrue);
      expect(uk.isWordChar('ї'), isTrue);
    });

    test('Filipino: QWERTY with Ñ by default, plain QWERTY too, plain quotes, peso and .ph', () {
      final fil = languageInfo('fil');
      expect(fil.englishName, 'Filipino');
      expect(fil.defaultLayout.id, 'qwerty_es');
      expect(fil.layout('qwerty'), isNotNull);
      expect(fil.currency, '₱');
      expect(fil.domains, contains('.ph'));
      expect(rulesForLanguage('fil').quotes, ('"', '"'));
      expect(rulesForLanguage('fil').isWordChar('ñ'), isTrue);
      expect(rulesForLanguage('fil').isWordChar('-'), isTrue, reason: 'pag-ibig, mag-aral');
    });

    test('Filipino ships its dictionary and emoji keywords', () {
      expect(File('assets/dict/fil.mdict').existsSync(), isTrue);
      expect(File('assets/emoji/keywords_fil.dat').existsSync(), isTrue);
      expect(EmojiRepository.supports('fil'), isTrue);
    });
    test('every European language ends sentences like English and has case', () {
      for (final id in ['es', 'fr', 'de', 'pt-BR', 'pt-PT', 'id', 'fil', 'ru', 'uk']) {
        final rules = rulesForLanguage(id);
        expect(rules.language, id);
        expect(rules.hasCase, isTrue, reason: id);
        expect(rules.endsSentence('!'), isTrue, reason: id);
        expect(rules.endsSentence('?'), isTrue, reason: id);
      }
    });
  });
}

LanguageSettings _settings({
  required LanguageId active,
  required List<LanguageId> enabled,
  required bool multilingual,
}) => LanguageSettings(enabled: enabled, active: active, multilingual: multilingual);
