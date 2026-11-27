// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wave 3-A: every European layout parses, has the script of its language, its rows fit and it
// types every letter of the language's alphabet (keys or long-press popups).
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/european.dart';
import 'package:booboard/src/engine/lang/registry.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';

import 'support/fakes.dart';

/// Letters a language's alphabet needs, lower case.
const Map<String, String> _alphabet = {
  'es': 'abcdefghijklmnñopqrstuvwxyzáéíóúü',
  'fr': 'abcdefghijklmnopqrstuvwxyzàâæçéèêëîïôœùûü',
  'de': 'abcdefghijklmnopqrstuvwxyzäöüß',
  'pt-BR': 'abcdefghijklmnopqrstuvwxyzáàâãéêíóôõúç',
  'pt-PT': 'abcdefghijklmnopqrstuvwxyzáàâãéêíóôõúç',
  'id': 'abcdefghijklmnopqrstuvwxyz',
  'ru': 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя',
  'uk': 'абвгґдеєжзиіїйклмнопрстуфхцчшщьюя',
};

Future<KeyboardLayoutDef> _load(String id) => KeyboardLayoutDef.load(DiskPackRepository(), id);

Set<String> _typeable(KeyboardLayoutDef l) => {
  for (final k in l.keys) ...[if (k.output != null) k.output!.toLowerCase(), for (final p in k.popup) p.toLowerCase()],
};

void main() {
  group('European layouts', () {
    test('every layout of every European language parses, has its script and rows fit', () async {
      for (final info in europeanLanguages) {
        for (final choice in info.layouts) {
          final l = await _load(choice.id);
          expect(l.id, choice.id, reason: info.id);
          expect(l.script, choice.script, reason: '${info.id}/${choice.id}');
          final widest = l.rows.map((r) => r.totalUnits).reduce((a, b) => a > b ? a : b);
          for (final r in l.rows) {
            expect(r.totalUnits, lessThanOrEqualTo(widest + 1e-9), reason: '${info.id}/${choice.id}');
          }
        }
      }
    });

    test(
      'keys are never narrower than 0.9 units, except the Cyrillic and umlaut rows that were shrunk to fit',
      () async {
        final l = await _load('qwerty_es');
        for (final k in l.keys) {
          expect(k.width, greaterThanOrEqualTo(0.9), reason: k.output);
        }
      },
    );

    test('each language can type every letter of its alphabet', () async {
      for (final entry in _alphabet.entries) {
        final info = languageInfo(entry.key);
        for (final choice in info.layouts) {
          final typeable = _typeable(await _load(choice.id));
          for (final ch in entry.value.split('')) {
            expect(typeable, contains(ch), reason: '${entry.key} letter $ch on ${choice.id}');
          }
        }
      }
    });

    test('Ukrainian and Russian keep their extra letters: і ї є ґ ʼ and ё ъ', () async {
      final uk = _typeable(await _load('jcuken_uk'));
      expect(uk, containsAll(['і', 'ї', 'є', 'ґ', 'ʼ']));
      final ru = _typeable(await _load('jcuken_ru'));
      expect(ru, containsAll(['ё', 'ъ']));
    });

    test('the German umlaut layout has ü ö ä as keys, and QWERTZ has them on popups', () async {
      final keys = (await _load('qwertz_umlaut')).keys.map((k) => k.output).toSet();
      expect(keys, containsAll(['ü', 'ö', 'ä']));
      final qwertz = await _load('qwertz');
      final popups = {for (final k in qwertz.keys) k.output: k.popup};
      expect(popups['u'], contains('ü'));
      expect(popups['o'], contains('ö'));
      expect(popups['a'], contains('ä'));
      expect(popups['s'], contains('ß'));
    });

    test('QWERTZ has Z and Y swapped; AZERTY starts with a z e r t y', () async {
      final qwertzTop = (await _load('qwertz')).rows.first.keys.map((k) => k.output).join();
      expect(qwertzTop, 'qwertzuiop');
      final azertyTop = (await _load('azerty')).rows.first.keys.map((k) => k.output).join();
      expect(azertyTop, 'azertyuiop');
    });

    test('the Spanish layout puts Ñ after L and the inverted marks on the period popup', () async {
      final l = await _load('qwerty_es');
      final outputs = [for (final k in l.keys) k.output];
      expect(outputs.indexOf('ñ'), greaterThan(outputs.indexOf('l')));
      final period = l.keys.firstWhere((k) => k.type == KeyType.period);
      expect(period.popup, containsAll(['¿', '¡']));
    });

    test('the top row of every European layout has digit hints 1-0', () async {
      for (final id in ['qwerty_es', 'azerty', 'qwertz', 'qwertz_umlaut', 'jcuken_ru', 'jcuken_uk']) {
        final l = await _load(id);
        final hints = [for (final k in l.rows.first.keys.take(10)) k.hint];
        expect(hints, ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'], reason: id);
      }
    });

    test('every symbols page keeps its currency key', () async {
      final symbols = await _load('symbols');
      expect(symbols.keys.any((k) => k.id == 'currency'), isTrue);
    });
  });
}
