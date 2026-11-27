// SPDX-License-Identifier: GPL-3.0-or-later
//
// The Indic layouts (assets/layouts/{translit,phonetic,inscript}_<lang>.json): they parse, their script
// matches the language registry, every row fits, every letter of the script is typed somewhere, and the
// punctuation keys carry the Indic marks.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart' show TextDirection;
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/registry.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';

KeyboardLayoutDef _layout(String id) =>
    KeyboardLayoutDef.fromJson(jsonDecode(File('assets/layouts/$id.json').readAsStringSync()) as Map<String, Object?>);

/// Every string a layout can type: outputs, shifted outputs and popups.
Set<String> _typed(KeyboardLayoutDef l) {
  final out = <String>{};
  for (final k in l.keys) {
    if (k.output != null) out.add(k.output!);
    if (k.shiftedOutput != null) out.add(k.shiftedOutput!);
    out.addAll(k.popup);
  }
  return out;
}

/// The letters, vowel signs, viramas and marks of each script that a native layout must type.
const Map<String, List<String>> _letters = {
  'hi': [
    'अ', 'आ', 'इ', 'ई', 'उ', 'ऊ', 'ऋ', 'ए', 'ऐ', 'ओ', 'औ', //
    'ा', 'ि', 'ी', 'ु', 'ू', 'े', 'ै', 'ो', 'ौ', //
    'क', 'ख', 'ग', 'घ', 'ङ', 'च', 'छ', 'ज', 'झ', 'ञ', 'ट', 'ठ', 'ड', 'ढ', 'ण', 'त', 'थ', 'द', 'ध', 'न', //
    'प', 'फ', 'ब', 'भ', 'म', 'य', 'र', 'ल', 'व', 'श', 'ष', 'स', 'ह', 'ळ', 'ड़', 'क्ष', 'ज्ञ', //
    '्', 'ं', 'ँ', 'ः', '़', 'ऽ',
  ],
  'bn': [
    'অ', 'আ', 'ই', 'ঈ', 'উ', 'ঊ', 'ঋ', 'এ', 'ঐ', 'ও', 'ঔ', //
    'া', 'ি', 'ী', 'ু', 'ূ', 'ে', 'ৈ', 'ো', 'ৌ', //
    'ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ', 'ছ', 'জ', 'ঝ', 'ঞ', 'ট', 'ঠ', 'ড', 'ঢ', 'ণ', 'ত', 'থ', 'দ', 'ধ', 'ন', //
    'প', 'ফ', 'ব', 'ভ', 'ম', 'য', 'র', 'ল', 'শ', 'ষ', 'স', 'হ', 'ড়', 'য়', 'ক্ষ', 'জ্ঞ', //
    '্', 'ং', 'ঁ', 'ঃ', '়', 'ঽ',
  ],
  'ta': [
    'அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ', //
    'ா', 'ி', 'ீ', 'ு', 'ூ', 'ெ', 'ே', 'ை', 'ொ', 'ோ', 'ௌ', //
    'க', 'ங', 'ச', 'ஜ', 'ஞ', 'ட', 'ண', 'த', 'ந', 'ப', 'ம', 'ய', 'ர', 'ற', 'ல', 'ள', 'ழ', 'ன', 'வ', //
    'ஷ', 'ஸ', 'ஹ', 'க்ஷ', '்', 'ஂ',
  ],
  'te': [
    'అ', 'ఆ', 'ఇ', 'ఈ', 'ఉ', 'ఊ', 'ఋ', 'ఎ', 'ఏ', 'ఐ', 'ఒ', 'ఓ', 'ఔ', //
    'ా', 'ి', 'ీ', 'ు', 'ూ', 'ృ', 'ె', 'ే', 'ై', 'ొ', 'ో', 'ౌ', //
    'క', 'ఖ', 'గ', 'ఘ', 'ఙ', 'చ', 'ఛ', 'జ', 'ఝ', 'ఞ', 'ట', 'ఠ', 'డ', 'ఢ', 'ణ', 'త', 'థ', 'ద', 'ధ', 'న', //
    'ప', 'ఫ', 'బ', 'భ', 'మ', 'య', 'ర', 'ఱ', 'ల', 'ళ', 'వ', 'శ', 'ష', 'స', 'హ', 'క్ష', 'జ్ఞ', //
    '్', 'ం', 'ఁ', 'ః', 'ఽ',
  ],
};

const _scriptOf = {'hi': 'Deva', 'mr': 'Deva', 'bn': 'Beng', 'ta': 'Taml', 'te': 'Telu'};

List<String> _lettersOf(String lang) => _letters[lang == 'mr' ? 'hi' : lang]!;

void main() {
  group('files', () {
    test('every Indic language has three layouts that parse, with the registry script', () {
      for (final lang in ['hi', 'mr', 'bn', 'ta', 'te']) {
        for (final kind in ['translit', 'phonetic', 'inscript']) {
          final id = '${kind}_$lang';
          final l = _layout(id);
          expect(l.id, id);
          final choice = languageInfo(lang).layouts.firstWhere((c) => c.id == id);
          expect(l.script, choice.script, reason: id);
          expect(l.script, kind == 'translit' ? 'Latn' : _scriptOf[lang], reason: id);
          expect(l.direction, TextDirection.ltr, reason: id);
        }
      }
    });

    test('translit and phonetic rows fit in ten key units like QWERTY; InScript rows in eleven', () {
      for (final file in Directory('assets/layouts').listSync().whereType<File>()) {
        final name = file.uri.pathSegments.last;
        if (!RegExp(r'^(translit|phonetic|inscript)_').hasMatch(name)) continue;
        final l = _layout(name.replaceAll('.json', ''));
        for (final row in l.rows) {
          final limit = name.startsWith('inscript_') ? 11.0001 : 10.0001;
          expect(row.totalUnits, lessThanOrEqualTo(limit), reason: '$name row');
        }
      }
    });
  });

  group('English letters', () {
    test('types only ASCII letters, with no accents in the popups', () {
      for (final lang in ['hi', 'mr', 'bn', 'ta', 'te']) {
        final typed = _typed(_layout('translit_$lang'));
        for (final s in typed) {
          if (s == '।' || s == '॥') continue; // the danda on the period key
          expect(s.runes.every((r) => r < 0x80), isTrue, reason: 'translit_$lang types "$s"');
        }
      }
    });

    test('keeps the QWERTY letters and the symbols path', () {
      final l = _layout('translit_hi');
      final letters = l.keys.where((k) => k.isCharacter && k.output != null).map((k) => k.output!).toSet();
      expect(letters, containsAll('qwertyuiopasdfghjklzxcvbnm'.split('')));
    });
  });

  group('native layouts', () {
    for (final lang in ['hi', 'mr', 'bn', 'ta', 'te']) {
      for (final kind in ['phonetic', 'inscript']) {
        test('${kind}_$lang types every letter of the script', () {
          final typed = _typed(_layout('${kind}_$lang'));
          final missing = [
            for (final s in _lettersOf(lang))
              if (!typed.contains(s)) s,
          ];
          expect(missing, isEmpty, reason: '${kind}_$lang is missing letters');
        });

        test('${kind}_$lang has shift, backspace, enter and space, and long-press ZWNJ and ZWJ on the virama key', () {
          final l = _layout('${kind}_$lang');
          final types = l.keys.map((k) => k.type).toSet();
          expect(types, containsAll([KeyType.shift, KeyType.backspace, KeyType.space, KeyType.enter]));
          final virama = l.keys.firstWhere((k) => const {'्', '্', '்', '్'}.contains(k.output));
          expect(virama.popup, containsAll(['‌', '‍']));
        });
      }
    }

    test('the danda and double danda are on the period key for Hindi, Marathi and Bengali only', () {
      for (final id in ['phonetic_hi', 'inscript_hi', 'phonetic_mr', 'inscript_bn', 'translit_hi']) {
        final period = _layout(id).rows.last.keys.firstWhere((k) => k.type == KeyType.period);
        expect(period.popup.take(2), ['।', '॥'], reason: id);
      }
      for (final id in ['phonetic_ta', 'inscript_te', 'translit_ta', 'translit_te']) {
        final period = _layout(id).rows.last.keys.firstWhere((k) => k.type == KeyType.period);
        expect(period.popup, isNot(contains('।')), reason: id);
      }
    });

    test('the bottom row keeps the symbols key (the QWERTY bottom row is reused)', () {
      final symbols = _layout('phonetic_hi').rows.last.keys.map((k) => k.type).toList();
      expect(symbols, contains(KeyType.symbols));
    });
  });
}
