// SPDX-License-Identifier: GPL-3.0-or-later
//
// The InScript layouts follow the BIS key tables in tool/indic/make_inscript.dart: the files are what
// the generator writes, rows 1 and 2 are the PC rows in BIS order with BIS shift levels, every
// character of the table is typed somewhere, and no character sits on two keys.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';

import '../../tool/indic/make_inscript.dart';

KeyboardLayoutDef _layout(String lang) => KeyboardLayoutDef.fromJson(
  jsonDecode(File('assets/layouts/inscript_$lang.json').readAsStringSync()) as Map<String, Object?>,
);

List<KeyDef> _letters(KeyRowDef r) => r.keys.where((k) => k.isCharacter).toList();

void main() {
  for (final spec in specs) {
    final lang = spec.lang;
    group('inscript_$lang', () {
      final layout = _layout(lang);

      test('the file is what the generator writes (run dart run tool/indic/make_inscript.dart)', () {
        expect(File('assets/layouts/inscript_$lang.json').readAsStringSync(), encodeLayout(buildLayout(spec)));
      });

      test('letter rows follow the BIS keys in order, with their BIS shift levels', () {
        final rows = letterRows(spec);
        for (var r = 0; r < 3; r++) {
          final keys = _letters(layout.rows[r]);
          expect(keys, hasLength(rows[r].length), reason: 'row ${r + 1}');
          for (var i = 0; i < keys.length; i++) {
            final levels = spec.table[rows[r][i]]!;
            final shiftOnly = levels[0] == null || levels[0] == ',' || levels[0] == '.';
            expect(keys[i].output, shiftOnly ? levels[1] : levels[0], reason: rows[r][i]);
            expect(keys[i].shiftedOutput, shiftOnly ? null : levels[1], reason: '${rows[r][i]} shifted');
          }
        }
      });

      test('every character of the BIS table can be typed', () {
        final typed = <String>{
          for (final k in layout.keys) ...[?k.output, ?k.shiftedOutput, ...k.popup],
        };
        final missing = [
          for (final levels in spec.table.values)
            for (final c in levels)
              if (c != null && c != ',' && c != '.' && !typed.contains(c)) c,
        ];
        expect(missing, isEmpty);
      });

      test('no character is on two keys (outputs and shift levels)', () {
        final seen = <String, int>{};
        for (final k in layout.keys.where((k) => k.isCharacter)) {
          for (final c in [?k.output, ?k.shiftedOutput]) {
            seen[c] = (seen[c] ?? 0) + 1;
          }
        }
        expect(seen.entries.where((e) => e.value > 1).map((e) => e.key), isEmpty);
      });

      test('every row is 11 units wide', () {
        for (final row in layout.rows) {
          expect(row.totalUnits, closeTo(11, 0.001));
        }
      });

      test('nukta letters use the NFC sequences, like the dictionaries', () {
        final precomposed = RegExp('[क़-य़ড়ঢ়য়]');
        for (final k in layout.keys) {
          for (final c in [?k.output, ?k.shiftedOutput, ...k.popup]) {
            expect(precomposed.hasMatch(c), isFalse, reason: c);
          }
        }
      });
    });
  }

  test('Hindi: the bottom row and the virama shift level match the BIS chart', () {
    final l = _layout('hi');
    expect(_letters(l.rows[2]).map((k) => k.output).join(' '), 'ं म न व ल स य ़');
    expect(_letters(l.rows[2]).map((k) => k.shiftedOutput).join(' '), 'ँ ण ऩ ऴ ळ श य़ ञ');
    final virama = l.keys.firstWhere((k) => k.output == '्');
    expect(virama.shiftedOutput, 'अ');
    expect(l.keys.firstWhere((k) => k.output == 'र').shiftedOutput, 'ऱ');
  });

  test('Tamil: one key per letter, short o on the long press of long o', () {
    final l = _layout('ta');
    expect(_letters(l.rows[0]).map((k) => k.output).join(), 'ௌைாீூஹஜஞஃ');
    expect(l.keys.firstWhere((k) => k.output == 'ோ').popup, ['ொ', 'ஒ']);
  });

  test('Marathi offers ॲ, Hindi does not', () {
    expect(_layout('mr').keys.firstWhere((k) => k.output == 'ा').popup.first, 'ॲ');
    expect(_layout('hi').keys.firstWhere((k) => k.output == 'ा').popup, isNot(contains('ॲ')));
  });
}
