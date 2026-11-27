// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/chinese/learned_phrases.dart';
import 'package:booboard/src/engine/lang/chinese/pinyin_composer.dart';
import 'package:booboard/src/engine/lang/chinese/zh_lexicon.dart';
import 'package:booboard/src/keyboard/input/composer.dart';

import 'zh_fixture.dart';

class _Harness {
  _Harness({
    ZhLexicon? lexicon,
    this.fuzzy = false,
    this.traditional = false,
    this.learning = true,
    LearnedPhrases? learned,
  }) : lexicon = lexicon ?? fixtureLexicon(),
       learned = learned ?? LearnedPhrases() {
    composer = PinyinComposer(
      lexicon: this.lexicon,
      options: () => PinyinOptions(fuzzy: fuzzy, traditional: traditional),
      learned: this.learned,
      learningAllowed: () => learning,
      onLearned: () => saves++,
    );
  }

  final ZhLexicon lexicon;
  final LearnedPhrases learned;
  late final PinyinComposer composer;
  bool fuzzy;
  bool traditional;
  bool learning;
  int saves = 0;

  /// Types [s]; a space is a space key, an apostrophe an apostrophe, anything else a character.
  List<ComposerStep> type(String s) => [
    for (final ch in s.split('')) ch == ' ' ? composer.onSpace() : composer.onText(ch),
  ];

  List<String> get texts => [for (final c in composer.state.candidates) c.text];
}

void main() {
  group('composing', () {
    test('letters compose; the preedit is what was typed; candidates come whole buffer first', () {
      final h = _Harness();
      h.type('nihao');
      final s = h.composer.state;
      expect(s.preedit, 'nihao');
      expect(s.reading, "ni'hao");
      expect(s.highlighted, 0);
      expect(h.texts, ['你好', '你', '尼', 'nihao'], reason: 'whole, then the prefix ni, then the letters as typed');
      expect(s.candidates.first.consumes, 5);
      expect(s.candidates[1].consumes, 2);
      expect(s.candidates.first.annotation, "ni'hao");
    });

    test('space commits the best candidate', () {
      final h = _Harness();
      h.type('nihao');
      final step = h.composer.onSpace();
      expect(step.commit, '你好');
      expect(h.composer.state.isEmpty, isTrue);
    });

    test('space with nothing typed is not handled, so it types a space', () {
      final h = _Harness();
      expect(h.composer.onSpace().handled, isFalse);
    });

    test('a partial pick converts the first syllable and leaves the rest composing', () {
      final h = _Harness();
      h.type('nihao');
      final step = h.composer.selectCandidate(1);
      expect(step.commit, '你');
      expect(h.composer.state.preedit, 'hao');
      expect(h.texts.first, '好');
      expect(h.composer.onSpace().commit, '好');
    });

    test('enter commits the letters as typed', () {
      final h = _Harness();
      h.type('nih');
      expect(h.composer.onEnter().commit, 'nih');
      expect(h.composer.state.isEmpty, isTrue);
      expect(h.composer.onEnter().handled, isFalse);
    });

    test('backspace removes a letter, and is not handled when nothing is typed', () {
      final h = _Harness();
      h.type('nih');
      h.composer.onBackspace();
      expect(h.composer.state.preedit, 'ni');
      h.composer.onBackspace();
      h.composer.onBackspace();
      expect(h.composer.state.isEmpty, isTrue);
      expect(h.composer.onBackspace().handled, isFalse);
    });

    test('letters the dictionary lacks stay as typed, and space commits them', () {
      final h = _Harness();
      h.type('qx');
      expect(h.texts, ['qx']);
      expect(h.composer.onSpace().commit, 'qx');
    });

    test('reset forgets the buffer', () {
      final h = _Harness();
      h.type('ni');
      h.composer.reset();
      expect(h.composer.state.isEmpty, isTrue);
    });
  });

  group('apostrophes', () {
    test('an apostrophe forces a syllable break', () {
      final h = _Harness();
      h.type("xi'an");
      expect(h.composer.state.preedit, "xi'an");
      expect(h.composer.state.reading, "xi'an");
      expect(h.texts.first, '西安', reason: 'the two segments, each converted, make 西安');
      expect(h.composer.state.candidates.first.consumes, 5);
    });

    test('with a break, a prefix stops at the break', () {
      final h = _Harness();
      h.type("xi'an");
      final texts = h.texts;
      expect(texts, isNot(contains('先')), reason: 'xian is not one unit across the break');
      expect(texts.contains('西'), isTrue);
      final step = h.composer.selectCandidate(texts.indexOf('西'));
      expect(step.commit, '西');
      expect(h.composer.state.preedit, 'an', reason: 'the apostrophe before the rest is dropped');
    });

    test('an apostrophe with nothing before it is not handled', () {
      final h = _Harness();
      expect(h.composer.onText("'").handled, isFalse);
    });

    test('a doubled apostrophe is one break', () {
      final h = _Harness();
      h.type("xi''an");
      expect(h.composer.state.preedit, "xi'an");
    });
  });

  group('punctuation', () {
    test('with nothing typed, the full-width mark is committed', () {
      final h = _Harness();
      expect(h.composer.onText(',').commit, '，');
      expect(h.composer.onText('.').commit, '。');
      expect(h.composer.onText('?').commit, '？');
      expect(h.composer.onText('!').commit, '！');
      expect(h.composer.onText(':').commit, '：');
      expect(h.composer.onText(';').commit, '；');
      expect(h.composer.onText('(').commit, '（');
      expect(h.composer.onText(')').commit, '）');
      expect(h.composer.onText('，').handled, isFalse, reason: 'already full-width: the controller types it');
    });

    test('double quotes alternate', () {
      final h = _Harness();
      expect(h.composer.onText('"').commit, '“');
      expect(h.composer.onText('"').commit, '”');
      expect(h.composer.onText('"').commit, '“');
    });

    test('with letters typed, the best candidate is committed before the mark', () {
      final h = _Harness();
      h.type('ni');
      expect(h.composer.onText(',').commit, '你，');
      expect(h.composer.state.isEmpty, isTrue);
    });

    test('a digit with letters typed commits the best candidate and then the digit', () {
      final h = _Harness();
      h.type('ni');
      expect(h.composer.onText('1').commit, '你1');
    });

    test('a digit with nothing typed is not handled, so it types normally', () {
      final h = _Harness();
      expect(h.composer.onText('1').handled, isFalse);
    });
  });

  group('options', () {
    test('traditional output converts every candidate', () {
      final h = _Harness(traditional: true);
      h.type('zhongguo');
      expect(h.texts.first, '中國');
      h.composer.reset();
      h.type('ruanjian');
      expect(h.texts.first, '軟體', reason: 'the phrase table, then the Taiwan phrases');
    });

    test('fuzzy pinyin finds the confusable syllable only when it is on', () {
      final off = _Harness();
      off.type('shi');
      expect(off.texts, isNot(contains('思')));
      final on = _Harness(fuzzy: true);
      on.type('shi');
      expect(on.texts.first, '思');
    });
  });

  group('learning', () {
    test('two picks in a row make a new word, which then ranks first', () {
      final h = _Harness();
      h.type('guo');
      h.composer.selectCandidate(0);
      h.type('ren');
      h.composer.selectCandidate(0);
      expect(h.learned.countFor('guoren', '国人'), 1);
      expect(h.saves, greaterThan(0));
      h.type('guoren');
      expect(h.texts.first, '国人');
    });

    test('a dictionary word picked counts as a pick, and is not learned again as a new word', () {
      final h = _Harness();
      h.type('nihao');
      h.composer.selectCandidate(0);
      expect(h.learned.countFor('nihao', '你好'), 1);
      expect(h.learned.length, 1, reason: 'one pick is not a run of picks');
    });

    test('a multi-character pick is counted', () {
      final h = _Harness();
      h.type('zhongguo');
      h.composer.selectCandidate(0);
      expect(h.learned.countFor('zhongguo', '中国'), 1);
    });

    test('nothing is learned when learning is not allowed', () {
      final h = _Harness(learning: false);
      h.type('guo');
      h.composer.selectCandidate(0);
      h.type('ren');
      h.composer.selectCandidate(0);
      expect(h.learned.length, 0);
      expect(h.saves, 0);
    });

    test('learned phrases are kept through the encoded blob', () {
      final h = _Harness();
      h.type('guo');
      h.composer.selectCandidate(0);
      h.type('ren');
      h.composer.selectCandidate(0);
      final again = LearnedPhrases.decode(h.learned.encode());
      expect(again.countFor('guoren', '国人'), 1);
    });
  });

  group('loading', () {
    test('while the dictionary is not loaded, letters are kept and the state says so', () {
      final lexicon = ZhLexicon();
      final h = _Harness(lexicon: lexicon);
      h.type('nihao');
      final s = h.composer.state;
      expect(s.preedit, 'nihao');
      expect(s.loading, isTrue);
      expect(s.candidates, isEmpty);
      expect(h.composer.changes, same(lexicon));
    });

    test('when the dictionary arrives, the candidates appear', () {
      final lexicon = ZhLexicon();
      final h = _Harness(lexicon: lexicon);
      h.type('nihao');
      var notified = 0;
      h.composer.changes.addListener(() => notified++);
      lexicon.install(
        ZhLoaded(
          dictionary: fixtureDictionary(),
          converter: fixtureLexicon().converter!,
          pack: const ZhPackInfo(id: 'x', name: 'x', sizeBytes: 0),
        ),
      );
      expect(notified, 1);
      expect(h.composer.state.loading, isFalse);
      expect(h.texts.first, '你好');
    });
  });
}
