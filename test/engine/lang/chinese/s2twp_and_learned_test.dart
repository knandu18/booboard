// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/chinese/learned_phrases.dart';
import 'package:booboard/src/engine/lang/chinese/s2twp.dart';

import 'zh_fixture.dart';

void main() {
  group('s2twp', () {
    final conv = S2twpConverter.parse(fixtureTsv);

    test('phrases win over characters, and the Taiwan phrases follow', () {
      expect(conv.convert('软件'), '軟體');
      expect(conv.convert('中国'), '中國');
    });

    test('characters without a table entry pass through', () {
      expect(conv.convert('你好abc'), '你好abc');
      expect(conv.convert(''), '');
    });

    test('a malformed or unknown line is skipped', () {
      final c = S2twpConverter.parse('Z\tx\ty\nA\tonly-two\nA\t\tempty\nB\t猫\t貓\n');
      expect(c.convert('猫'), '貓');
      expect(c.convert('x'), 'x');
    });

    test('an empty table still converts nothing', () {
      expect(S2twpConverter.parse('').convert('国'), '国');
    });
  });

  group('learned phrases', () {
    test('counts picks and keeps the most picked first', () {
      final l = LearnedPhrases();
      l.add('nihao', '你好');
      l.add('nihao', '你好');
      l.add('nihao', '尼好');
      expect(l.countFor('nihao', '你好'), 2);
      expect(l.wordsFor('nihao').map((w) => w.$1), ['你好', '尼好']);
      expect(l.dirty, isTrue);
      expect(l.length, 2);
    });

    test('empty letters or text are ignored', () {
      final l = LearnedPhrases()
        ..add('', '你')
        ..add('ni', '');
      expect(l.length, 0);
    });

    test('round-trips through the encoded blob', () {
      final l = LearnedPhrases()
        ..add('guoren', '国人')
        ..add('guoren', '国人');
      final back = LearnedPhrases.decode(l.encode());
      expect(back.countFor('guoren', '国人'), 2);
      expect(back.dirty, isFalse);
    });

    test('an unreadable blob gives an empty store', () {
      expect(LearnedPhrases.decode(null).length, 0);
      expect(LearnedPhrases.decode(Uint8List(0)).length, 0);
      expect(LearnedPhrases.decode(Uint8List.fromList('not json'.codeUnits)).length, 0);
      expect(LearnedPhrases.decode(Uint8List.fromList('{"v":2,"p":{}}'.codeUnits)).length, 0);
    });

    test('the least picked go first when the store is full', () {
      final l = LearnedPhrases();
      for (var i = 0; i < LearnedPhrases.capacity; i++) {
        l.add('k$i', '字$i');
      }
      l.add('k0', '字0');
      l.add('extra', '新词');
      expect(l.length, LearnedPhrases.capacity);
      expect(l.countFor('extra', '新词'), 1);
      expect(l.countFor('k0', '字0'), 2, reason: 'the picked-twice word survives');
    });

    test('replaceWith copies another store in place', () {
      final l = LearnedPhrases()..add('a', '甲');
      final other = LearnedPhrases()..add('b', '乙');
      l.replaceWith(other);
      expect(l.countFor('a', '甲'), 0);
      expect(l.countFor('b', '乙'), 1);
      expect(l.dirty, isFalse);
    });
  });
}
