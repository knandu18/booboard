// SPDX-License-Identifier: GPL-3.0-or-later
//
// The Arabic and Urdu layouts (Wave 3-C): they parse, their rows fit, they type every letter, and
// the variants the keyboard adds (native digits, the email/URL .com key) still work on them.

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/lang/registry.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/keyboard/layout/layout_repository.dart';

import '../keyboard/support/app_harness.dart';

/// Arabic letters (with the hamza forms and ta marbuta) that an Arabic phone layout must type.
const _arabicLetters =
    'ابتثجحخدذرزسشصضطظعغفقكلمنهوي'
    'ءأإآؤئةى';

/// Urdu letters that the phonetic layout must type, including the ones that sit on a popup.
const _urduLetters = 'اآأإبپتٹثجچحخدڈذرڑزژسشصضطظعغفقکگلمنںوہھیےئءؤ';

Iterable<String> _typed(KeyboardLayoutDef l) sync* {
  for (final k in l.keys) {
    if (k.output != null) yield k.output!;
    yield* k.popup;
  }
}

void main() {
  final arabic = loadLayoutSync('arabic');
  final urdu = loadLayoutSync('urdu_phonetic');

  group('arabic', () {
    test('parses as Arab and matches its language entry', () {
      expect(arabic.id, 'arabic');
      expect(arabic.script, 'Arab');
      expect(arabic.direction.name, 'ltr', reason: 'keys keep the physical order of the file');
      final choice = languageInfo('ar').layouts.single;
      expect(choice.id, arabic.id);
      expect(choice.script, arabic.script);
    });

    test('three letter rows and a bottom row, all the same width', () {
      expect(arabic.rows, hasLength(4));
      final widths = arabic.rows.map((KeyRowDef r) => r.totalUnits).toSet();
      expect(widths, hasLength(1), reason: 'rows must fit the same width: $widths');
      for (final r in arabic.rows.take(3)) {
        final letters = r.keys.where((k) => k.isCharacter);
        expect(letters.length, 11, reason: 'letter row');
      }
    });

    test('types every Arabic letter, with the alef and punctuation forms', () {
      final typed = _typed(arabic).toSet();
      for (final ch in _arabicLetters.split('')) {
        expect(typed, contains(ch), reason: 'missing $ch');
      }
      expect(arabic.keys.firstWhere((k) => k.output == 'ا').popup, containsAll(['أ', 'إ', 'آ', 'ٱ']));
      final period = arabic.keys.firstWhere((k) => k.type == KeyType.period);
      expect(period.popup, containsAll(['؟', '!', '؛']));
      final comma = arabic.keys.firstWhere((k) => k.type == KeyType.comma);
      expect(comma.output, '،');
    });

    test('harakat are on one key, with every mark on its long press', () {
      final harakat = arabic.keys.firstWhere((k) => k.output == 'َ');
      expect(harakat.popup, containsAll(['ُ', 'ِ', 'ً', 'ٌ', 'ٍ', 'ْ', 'ّ']));
    });

    test('the email variant swaps the comma for @ and adds a .com key', () {
      final l = LayoutVariants.forField(arabic, PreferredPage.email, domains: ['.sa']);
      final dotcom = l.keys.firstWhere((k) => k.id == 'dotcom');
      expect(dotcom.popup.first, '.sa');
      expect(l.rows.expand((r) => r.keys).any((k) => k.output == '@'), isTrue);
    });

    test('no Latin number row is added (the digits come from the symbols page)', () {
      expect(identical(LayoutVariants.withNumberRow(arabic), arabic), isTrue);
    });
  });

  group('urdu phonetic', () {
    test('parses as Arab and matches its language entry', () {
      expect(urdu.id, 'urdu_phonetic');
      expect(urdu.script, 'Arab');
      final choice = languageInfo('ur').layouts.single;
      expect(choice.id, urdu.id);
      expect(choice.script, urdu.script);
    });

    test('rows fit the same width', () {
      expect(urdu.rows, hasLength(4));
      expect(urdu.rows.map((KeyRowDef r) => r.totalUnits).toSet(), hasLength(1));
    });

    test('types every Urdu letter, the extra ones on popups', () {
      final typed = _typed(urdu).toSet();
      for (final ch in _urduLetters.split('')) {
        expect(typed, contains(ch), reason: 'missing $ch');
      }
      final period = urdu.keys.firstWhere((k) => k.type == KeyType.period);
      expect(period.output, '۔', reason: 'Urdu full stop on the period key');
      expect(urdu.keys.firstWhere((k) => k.type == KeyType.comma).output, '،');
    });

    test('uses the Urdu yeh and kaf, not the Arabic ones', () {
      final typed = _typed(urdu).toSet();
      expect(typed, contains('ی'));
      expect(typed, contains('ک'));
      expect(typed, isNot(contains('ي')));
      expect(typed, isNot(contains('ك')));
    });

    test('shin is a base key and no non-Urdu letters slip in', () {
      expect(urdu.keys.map((k) => k.output), contains('ش'), reason: 'ش is too common for a long press only');
      // ۇ (U+06C7) is Uyghur/Kyrgyz; it was once on the v key by mistake.
      expect(_typed(urdu), isNot(contains('ۇ')));
    });
  });
}
