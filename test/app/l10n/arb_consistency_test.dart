// SPDX-License-Identifier: GPL-3.0-or-later
//
// Every translation has every key of the English template, with the same placeholders, and no
// empty text. Translations flagged for a native-speaker check say so with "x-review".
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _locales = ['es', 'fr', 'de', 'pt', 'id', 'hi'];
final _placeholder = RegExp(r'\{(\w+)[,}]');

Map<String, Object?> _arb(String locale) {
  final file = File('lib/l10n/app_$locale.arb');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

Iterable<String> _messageKeys(Map<String, Object?> arb) => arb.keys.where((k) => !k.startsWith('@'));

Set<String> _names(String message) {
  // Plural branches are not placeholders, but their count is: "{count, plural, ...}" is the only
  // form with a comma after the name, and the branch texts never hold "{name}" without a space.
  return _placeholder.allMatches(message).map((m) => m.group(1)!).toSet();
}

void main() {
  final template = _arb('en');
  final keys = _messageKeys(template).toList();

  test('the template has a usable number of strings', () {
    expect(keys.length, greaterThan(500));
    expect(template['@@locale'], 'en');
  });

  test('the template describes every string for translators', () {
    for (final key in keys) {
      final meta = template['@$key'] as Map<String, Object?>?;
      expect(meta?['description'], isNotEmpty, reason: 'no @$key description');
    }
  });

  for (final locale in _locales) {
    group('app_$locale.arb', () {
      final arb = _arb(locale);

      test('has exactly the template keys', () {
        expect(arb['@@locale'], locale);
        expect(_messageKeys(arb).toSet(), keys.toSet());
      });

      test('has the same placeholders as the template, and no empty text', () {
        for (final key in keys) {
          final value = arb[key];
          expect(value, isA<String>(), reason: '$locale.$key');
          expect((value as String).trim(), isNotEmpty, reason: '$locale.$key is empty');
          expect(_names(value), _names(template[key] as String), reason: '$locale.$key placeholders');
        }
      });

      test('flags its uncertain strings for review', () {
        final flagged = [
          for (final key in keys)
            if ((arb['@$key'] as Map<String, Object?>?)?['x-review'] == true) key,
        ];
        expect(flagged, isNotEmpty);
      });
    });
  }
}
