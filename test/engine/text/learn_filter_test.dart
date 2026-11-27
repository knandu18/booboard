// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/learn/learn_filter.dart';
import 'package:booboard/src/engine/learn/learned_data.dart';

void main() {
  group('isLearnableWord', () {
    test('accepts ordinary words, names and other scripts', () {
      for (final w in ['zorbo', 'Kaun', "o'clock", 'well-known', 'naïve', 'नमस्ते', 'привет', 'strengths', 'NASA']) {
        expect(isLearnableWord(w), isTrue, reason: w);
      }
    });

    test('rejects secrets, numbers and noise', () {
      for (final w in [
        'a',
        'hunter2',
        '12345',
        'user@mail',
        'https://x',
        'camelCase',
        'ALLCAPSTOKEN',
        'xkcdqzvbtrnm',
        'aaaaa',
        "trailing'",
        '',
      ]) {
        expect(isLearnableWord(w), isFalse, reason: w);
      }
    });
  });

  group('LearnedData', () {
    test('counts decay by half every 90 days', () {
      final d = LearnedData('en')..commitWord('zorbo', 'zorbo', 100, novel: true);
      expect(d.wordScore('zorbo', 100), closeTo(1, 1e-9));
      expect(d.wordScore('zorbo', 190), closeTo(0.5, 1e-6));
    });

    test('survives an encode/decode round trip', () {
      final d = LearnedData('en')
        ..commitWord('zorbo', 'zorbo', 10, novel: true)
        ..commitWord('zorbo', 'zorbo', 11, novel: true)
        ..commitBigram('my', 'zorbo', 11)
        ..blocked.add('nope');
      final copy = LearnedData.decode('en', d.encode());
      expect(copy.isConfirmed('zorbo'), isTrue);
      expect(copy.bigramScore('my', 'zorbo', 11), greaterThan(0));
      expect(copy.blocked, {'nope'});
    });

    test('prunes to the size caps', () {
      final d = LearnedData('en');
      for (var i = 0; i < kMaxLearnedWords + 1000; i++) {
        d.commitWord('w$i', 'w$i', 1, novel: true);
      }
      expect(d.words.length, lessThanOrEqualTo(kMaxLearnedWords + kMaxLearnedWords ~/ 10));
    });

    test('removeWord drops pairs on both sides', () {
      final d = LearnedData('en')
        ..commitBigram('a', 'b', 1)
        ..commitBigram('b', 'c', 1)
        ..removeWord('b');
      expect(d.bigrams, isEmpty);
    });
  });
}
