// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/keyboard/layout/layout_engine.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/keyboard/layout/layout_repository.dart';

import 'support/fakes.dart';

Future<KeyboardLayoutDef> load(String id) => KeyboardLayoutDef.load(DiskPackRepository(), id);

Set<String> outputs(KeyboardLayoutDef l) => {
  for (final k in l.keys)
    if (k.output != null) k.output!,
};

void main() {
  group('layout assets', () {
    test('every layout parses and rows fit', () async {
      for (final id in ['qwerty', 'symbols', 'symbols2', 'numpad', 'phone', 'datetime']) {
        final l = await load(id);
        expect(l.id, id);
        expect(l.rows.length, 4, reason: id);
        final widest = l.rows.map((r) => r.totalUnits).reduce((a, b) => a > b ? a : b);
        for (final r in l.rows) {
          expect(r.totalUnits, lessThanOrEqualTo(widest + 1e-9));
        }
      }
    });

    test('qwerty: letters, digit hints and accent popups', () async {
      final l = await load('qwerty');
      final letters = [
        for (final k in l.keys)
          if (k.isCharacter) k.output!,
      ];
      expect(letters.join(), 'qwertyuiopasdfghjklzxcvbnm');
      final byOut = {
        for (final k in l.keys)
          if (k.output != null) k.output!: k,
      };
      expect(byOut['q']!.hint, '1');
      expect(byOut['p']!.hint, '0');
      expect(byOut['e']!.popup, ['3', 'é', 'è', 'ê', 'ë', 'ē', 'ė', 'ę']);
      expect(byOut['a']!.popup, containsAll(['á', 'à', 'â', 'ä', 'æ', 'ã', 'å', 'ā']));
      expect(byOut['o']!.popup, containsAll(['ó', 'ò', 'ô', 'ö', 'õ', 'ø', 'ō', 'œ']));
      expect(byOut['s']!.popup, containsAll(['ß', 'ś', 'š']));
      expect(byOut['n']!.popup, ['ñ', 'ń']);
      expect(byOut['z']!.popup, ['ž', 'ź', 'ż']);
      expect(byOut['y']!.popup, ['6', 'ý', 'ÿ']);
    });

    test('qwerty bottom row: symbols, emoji, comma, space, period, enter; period popup', () async {
      final l = await load('qwerty');
      final bottom = l.rows.last.keys;
      expect(bottom.map((k) => k.type), [
        KeyType.symbols,
        KeyType.emoji,
        KeyType.comma,
        KeyType.space,
        KeyType.period,
        KeyType.enter,
      ]);
      expect(bottom[4].popup, [',', '?', '!', "'", '"', ':', ';', '-', '(', ')', '@', '#']);
    });

    test('the emoji key sits between ?123 and the comma in qwerty and symbols, taking its width from space', () async {
      for (final id in ['qwerty', 'symbols']) {
        final bottom = (await load(id)).rows.last.keys;
        final i = bottom.indexWhere((k) => k.type == KeyType.emoji);
        expect(i, 1, reason: id);
        expect(bottom[i].width, 1, reason: id);
        expect(bottom[i + 1].type, KeyType.comma, reason: id);
        final space = bottom.firstWhere((k) => k.type == KeyType.space);
        expect(space.width, 4, reason: id);
      }
    });

    test('symbols and symbols2 contain the required characters', () async {
      final s = outputs(await load('symbols'));
      for (final c in '1234567890@#\$%&-+()/*"\':;!?'.split('')) {
        expect(s, contains(c));
      }
      final cur = (await load('symbols')).keys.firstWhere((k) => k.id == 'currency');
      expect(cur.popup, ['₹', '€', '£', '¥', '₩', '₽', '₴', 'R\$', 'Rp', '¢']);
      final s2 = outputs(await load('symbols2'));
      for (final c in [
        '~',
        '`',
        '|',
        '•',
        '√',
        'π',
        '÷',
        '×',
        '¶',
        '∆',
        '£',
        '¥',
        '€',
        '¢',
        '^',
        '°',
        '=',
        '{',
        '}',
        '\\',
        '©',
        '®',
        '™',
        '✓',
        '[',
        ']',
        '<',
        '>',
      ]) {
        expect(s2, contains(c));
      }
    });

    test('numpad has digits, decimal and minus; phone has + * # , ;', () async {
      final n = outputs(await load('numpad'));
      expect(n, containsAll(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '-', ',']));
      final p = await load('phone');
      final all = {...outputs(p), for (final k in p.keys) ...k.popup};
      expect(all, containsAll(['+', '*', '#', ',', ';']));
    });
  });

  group('field variants', () {
    test('email: @ replaces the comma and a .com key is added', () async {
      final base = await load('qwerty');
      final l = LayoutVariants.forField(base, PreferredPage.email);
      final bottom = l.rows.last.keys;
      expect(bottom.any((k) => k.type == KeyType.comma), isFalse);
      expect(bottom[2].output, '@');
      final dotCom = bottom.firstWhere((k) => k.output == '.com');
      expect(dotCom.popup, [
        '.net',
        '.org',
        '.in',
        '.co.id',
        '.de',
        '.fr',
        '.es',
        '.com.br',
        '.ru',
        '.ua',
        '.jp',
        '.cn',
      ]);
      expect(l.rows.last.totalUnits, closeTo(base.rows.last.totalUnits, 1e-9));
    });

    test('url: / replaces the comma and a .com key is added', () async {
      final l = LayoutVariants.forField(await load('qwerty'), PreferredPage.url);
      expect(l.rows.last.keys[2].output, '/');
      expect(l.rows.last.keys.any((k) => k.output == '.com'), isTrue);
    });

    test('emoji key stays next to ?123 in email and url fields (the @ and .com keys are kept)', () async {
      final base = await load('qwerty');
      for (final page in [PreferredPage.email, PreferredPage.url]) {
        final bottom = LayoutVariants.forField(base, page).rows.last.keys;
        expect(bottom.map((k) => k.type).take(2), [KeyType.symbols, KeyType.emoji], reason: page.name);
        expect(bottom.any((k) => k.type == KeyType.emoji), isTrue, reason: page.name);
        expect(bottom.any((k) => k.output == '.com'), isTrue, reason: page.name);
        expect(bottom.any((k) => k.type == KeyType.space), isTrue, reason: page.name);
      }
    });

    test('ordinary fields keep the layout', () async {
      final base = await load('qwerty');
      expect(identical(LayoutVariants.forField(base, PreferredPage.letters), base), isTrue);
    });

    test('number row adds a digit row and removes the digit hints', () async {
      final base = await load('qwerty');
      final l = LayoutVariants.withNumberRow(base);
      expect(l.rows.length, 5);
      expect(l.rows.first.keys.map((k) => k.output).join(), '1234567890');
      expect(l.rows.first.height, lessThan(1));
      expect(l.rows[1].keys.every((k) => k.hint == null), isTrue);
      // Popups keep working.
      expect(l.rows[1].keys[2].popup, contains('é'));
    });

    test('built-in fallback is a usable qwerty', () {
      final l = LayoutRepository.builtInQwerty();
      expect(l.rows.length, 4);
      final laid = KeyboardLayoutEngine.layout(l, const Size(360, 224));
      expect(laid.toGeometry().keys.length, 26);
    });
  });

  group('layout engine', () {
    const size = Size(360, 224);

    test('rows tile the height and keys stay inside', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), size, keyGap: 6);
      expect(l.rows.length, 4);
      expect(l.rows.first.top, 0);
      expect(l.rows.last.bottom, closeTo(224, 1e-9));
      for (final k in l.keys) {
        expect(k.rect.left, greaterThanOrEqualTo(0));
        expect(k.rect.right, lessThanOrEqualTo(360 + 1e-9));
        expect(k.rect.top, greaterThanOrEqualTo(0));
        expect(k.rect.bottom, lessThanOrEqualTo(224 + 1e-9));
        expect(k.cell.contains(k.rect.center), isTrue);
      }
    });

    test('letter keys in the top row are equal, with the theme gap between them', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), size, keyGap: 6);
      final top = l.rows.first.keys;
      expect(top.length, 10);
      for (var i = 1; i < top.length; i++) {
        expect(top[i].rect.width, closeTo(top[0].rect.width, 1e-9));
        expect(top[i].rect.left - top[i - 1].rect.right, closeTo(6, 1e-9));
      }
      expect(top[0].rect.height, closeTo(224 / 4 - 6, 1e-9));
    });

    test('padding centres the home row; widths follow units', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), size, keyGap: 0);
      final home = l.rows[1].keys;
      expect(home.first.rect.left, closeTo(18, 1e-9), reason: '0.5 units of 36 px');
      final bottom = l.rows[3].keys;
      final space = bottom[3];
      expect(space.def.type, KeyType.space);
      expect(space.rect.width, closeTo(4 * 36, 1e-9));
      expect(bottom[0].rect.width, closeTo(1.5 * 36, 1e-9));
    });

    test('there are no dead zones: every point maps to a key cell', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), size, keyGap: 8);
      for (var x = 0.0; x < 360; x += 3) {
        for (var y = 0.0; y < 224; y += 3) {
          final k = l.hitTest(Offset(x, y));
          expect(k, isNotNull);
          expect(k!.cell.contains(Offset(x, y)), isTrue, reason: '($x, $y)');
        }
      }
    });

    test('a touch in a gap picks a neighbouring key of the same row', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), size, keyGap: 10);
      final q = l.rows.first.keys[0];
      final w = l.rows.first.keys[1];
      final gap = Offset((q.rect.right + w.rect.left) / 2, q.rect.center.dy);
      final hit = l.hitTest(gap)!;
      expect(['q', 'w'], contains(hit.def.output));
      // Touches above the keys and below them still hit the first and last rows.
      expect(l.hitTest(const Offset(100, -30))!.row, 0);
      expect(l.hitTest(const Offset(100, 500))!.row, 3);
    });

    test('touches beyond the left edge of the padded home row hit the first key', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), size, keyGap: 6);
      final y = l.rows[1].keys.first.rect.center.dy;
      expect(l.hitTest(Offset(1, y))!.def.output, 'a');
      expect(l.hitTest(Offset(359, y))!.def.output, 'l');
    });

    test('geometry maps lower-case letters to key rects', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), size, keyGap: 6);
      final g = l.toGeometry();
      expect(g.keys.length, 26);
      expect(g.keys.keys.toSet(), 'abcdefghijklmnopqrstuvwxyz'.split('').toSet());
      expect(g.size, size);
      expect(g.keys['q']!.center.dx, lessThan(g.keys['w']!.center.dx));
      expect(g.keys['a']!.center.dy, greaterThan(g.keys['q']!.center.dy));
      expect(g.keyWidth, closeTo(l.keyWidth, 1e-9));
    });

    test('with a number row the letter keys shrink and move down', () async {
      final base = await load('qwerty');
      final plain = KeyboardLayoutEngine.layout(base, size).toGeometry();
      final withNr = KeyboardLayoutEngine.layout(LayoutVariants.withNumberRow(base), size).toGeometry();
      expect(withNr.keys['q']!.height, lessThan(plain.keys['q']!.height));
      expect(withNr.keys['q']!.top, greaterThan(plain.keys['q']!.top));
      expect(withNr.keys.length, 26, reason: 'digits are not part of the spatial model');
    });

    test('numpad keys are wide', () async {
      final l = KeyboardLayoutEngine.layout(await load('numpad'), size, keyGap: 6);
      expect(l.keys.first.rect.width, greaterThan(70));
    });

    test('an empty layout is harmless', () {
      final l = KeyboardLayoutEngine.layout(const KeyboardLayoutDef(id: 'x', name: 'x', rows: []), size);
      expect(l.keys, isEmpty);
      expect(l.hitTest(const Offset(1, 1)), isNull);
    });
  });

  group('split and compact layouts', () {
    const tablet = Size(800, 280);

    test('split: each half keeps its keys, the centre gap is 20% of the width, nothing overlaps', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), tablet, keyGap: 6, split: true);
      final mid = tablet.width / 2;
      // The top row is 10 units wide, so its gap is exactly 20% (plus the 3 dp inset on each key).
      final top = l.rows.first.keys;
      expect(top[5].rect.left - top[4].rect.right, closeTo(tablet.width * 0.2 + 6, 1e-6));
      expect(top[4].rect.right, lessThan(mid));
      expect(top[5].rect.left, greaterThan(mid));
      for (final row in l.rows) {
        for (var i = 0; i < row.keys.length; i++) {
          for (var j = i + 1; j < row.keys.length; j++) {
            expect(row.keys[i].rect.overlaps(row.keys[j].rect), isFalse, reason: 'row ${row.keys[i].row}');
          }
        }
      }
      for (final k in l.keys) {
        expect(k.rect.left, greaterThanOrEqualTo(0));
        expect(k.rect.right, lessThanOrEqualTo(tablet.width + 1e-9));
        expect(k.cell.contains(k.rect.center), isTrue);
      }
    });

    test('split: top row is q..t on the left and y..p on the right, with a touch in the gap picking a side', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), tablet, keyGap: 6, split: true);
      final top = l.rows.first.keys.map((k) => k.def.output).toList();
      expect(top, ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']);
      final mid = tablet.width / 2;
      final y = l.rows.first.keys.first.rect.center.dy;
      expect(l.hitTest(Offset(mid - 2, y))!.def.output, 't');
      expect(l.hitTest(Offset(mid + 2, y))!.def.output, 'y');
      expect(l.hitTest(Offset(150, y))!.def.output, 'e');
      expect(l.hitTest(Offset(tablet.width * 0.75, y))!.def.output, 'u');
    });

    test('split: the space bar becomes two halves that both type a space, and there are no dead zones', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), tablet, keyGap: 6, split: true);
      final spaces = l.keys.where((k) => k.def.type == KeyType.space).toList();
      expect(spaces, hasLength(2));
      expect(spaces.first.rect.center.dx, lessThan(tablet.width / 2));
      expect(spaces.last.rect.center.dx, greaterThan(tablet.width / 2));
      expect(spaces.first.rect.width, closeTo(spaces.last.rect.width, 1e-9));
      for (var x = 0.0; x < tablet.width; x += 5) {
        for (var y = 0.0; y < tablet.height; y += 5) {
          final k = l.hitTest(Offset(x, y));
          expect(k!.cell.contains(Offset(x, y)), isTrue, reason: '($x, $y)');
        }
      }
    });

    test('split: geometry still maps every letter, and each letter stays on its side of the gap', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), tablet, keyGap: 6, split: true);
      final g = l.toGeometry();
      expect(g.keys.length, 26);
      final mid = tablet.width / 2;
      expect(g.keys['q']!.center.dx, lessThan(mid));
      expect(g.keys['p']!.center.dx, greaterThan(mid));
      expect(g.keys['a']!.center.dx, lessThan(mid));
      expect(g.keys['l']!.center.dx, greaterThan(mid));
    });

    test('split is off by default: letters keep the single centred row', () async {
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), tablet, keyGap: 6);
      final top = l.rows.first.keys;
      expect(top.first.rect.left, lessThan(tablet.width / 2));
      expect(top.last.rect.right, greaterThan(tablet.width / 2));
      expect(l.keys.where((k) => k.def.type == KeyType.space), hasLength(1));
    });

    test('compact: keys are no taller than 44 dp, and the rows still reach the bottom', () async {
      const landscape = Size(640, 200);
      final l = KeyboardLayoutEngine.layout(await load('qwerty'), landscape, keyGap: 6, compact: true);
      expect(l.rows.first.bottom - l.rows.first.top, lessThanOrEqualTo(kCompactKeyHeight + 1e-9));
      expect(l.rows[1].bottom - l.rows[1].top, lessThanOrEqualTo(kCompactKeyHeight + 1e-9));
      expect(l.rows.last.bottom, closeTo(landscape.height, 1e-9));
      expect(l.hitTest(Offset(10, landscape.height - 2))!.row, 3);
    });

    test('compact leaves a tall area alone when the keys already fit', () async {
      const short = Size(640, 120);
      final plain = KeyboardLayoutEngine.layout(await load('qwerty'), short, keyGap: 6);
      final compact = KeyboardLayoutEngine.layout(await load('qwerty'), short, keyGap: 6, compact: true);
      expect(compact.rows.first.bottom, closeTo(plain.rows.first.bottom, 1e-9));
    });
  });
}
