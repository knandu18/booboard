// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/japanese/japanese_composer.dart';
import 'package:booboard/src/engine/lang/japanese/japanese_dictionary.dart';
import 'package:booboard/src/engine/lang/japanese/japanese_learning.dart';
import 'package:booboard/src/keyboard/input/composer.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import 'japanese_fixture.dart';

class _Clock {
  int now = 0;
}

JapaneseComposer _composer({
  String layout = 'romaji_ja',
  JapaneseDictionary? dictionary,
  BooBoardSettings settings = const BooBoardSettings(),
  bool learningAllowed = true,
  _Clock? clock,
  JapaneseLearning? learning,
  List<String>? log,
}) {
  final c = clock ?? _Clock();
  final composer = JapaneseComposer(
    layoutId: () => layout,
    settings: () => settings,
    learningAllowed: () => learningAllowed,
    clockMs: () => c.now,
    learning: learning,
    onLearned: () => log?.add('learned'),
    onNeedsDictionary: () => log?.add('needs-dictionary'),
  );
  composer.setDictionary(dictionary);
  return composer;
}

/// Types a string one character at a time, the way the controller feeds letters.
void _type(JapaneseComposer c, String s) {
  for (final ch in s.split('')) {
    c.onText(ch);
  }
}

String _commit(ComposerStep step) => step.commit;

void main() {
  group('romaji layout', () {
    test('letters build kana in the preedit; the typing candidates are predictions then kana forms', () {
      final c = _composer(dictionary: fixtureDictionary());
      _type(c, 'ii');
      expect(c.state.preedit, 'いい');
      expect(c.state.candidates.map((x) => x.text), containsAllInOrder(['いい', '良い', 'イイ']));
    });

    test('space converts, a second space steps the focused segment, enter commits', () {
      final c = _composer(dictionary: fixtureDictionary());
      _type(c, 'kyouhaiitenkidesu');
      expect(c.state.preedit, 'きょうはいいてんきです');
      c.onSpace();
      expect(c.state.preedit, '今日はいい天気です');
      expect(c.state.reading, 'きょう');
      final step = c.onEnter();
      expect(step.commit, '今日はいい天気です');
      expect(c.state.isEmpty, isTrue);
    });

    test('a candidate tap in conversion chooses it for the focused segment', () {
      final c = _composer(dictionary: fixtureDictionary());
      _type(c, 'kago');
      c.onSpace();
      expect(c.state.preedit, 'カゴ', reason: 'the cheapest dictionary word');
      final kago = c.state.candidates.indexWhere((x) => x.text == '籠');
      expect(kago, greaterThan(0));
      expect(c.selectCandidate(kago).handled, isTrue);
      expect(c.state.preedit, '籠');
    });

    test('punctuation and digits commit the conversion and are typed after it', () {
      final c = _composer(dictionary: fixtureDictionary());
      _type(c, 'kyou');
      final step = c.onText('、');
      expect(step.commit, 'きょう、');
      expect(c.state.isEmpty, isTrue);
      expect(c.onText('、').handled, isFalse, reason: 'nothing composing: the controller types it');
    });

    test('typing a letter during a conversion commits it and starts a new reading', () {
      final c = _composer(dictionary: fixtureDictionary());
      _type(c, 'kyou');
      c.onSpace();
      expect(c.state.preedit, '今日');
      final step = c.onText('a');
      expect(step.commit, '今日');
      expect(c.state.preedit, 'あ');
    });

    test('backspace leaves a conversion first, then deletes letters', () {
      final c = _composer(dictionary: fixtureDictionary());
      _type(c, 'kyou');
      c.onSpace();
      c.onBackspace();
      expect(c.state.preedit, 'きょう', reason: 'back to the reading');
      c.onBackspace();
      expect(c.state.preedit, 'きょ');
      c.onBackspace();
      c.onBackspace();
      expect(c.state.isEmpty, isTrue);
      expect(c.onBackspace().handled, isFalse, reason: 'empty buffer: the editor deletes');
    });

    test('space with nothing typed types a full-width space, or a half-width one when set', () {
      expect(_commit(_composer().onSpace()), '　');
      final half = _composer(settings: const BooBoardSettings(japanese: JapaneseSettings(halfWidthSpace: true)));
      expect(half.onSpace().handled, isFalse);
    });

    test('without a dictionary, conversion offers hiragana and katakana and asks for the pack', () {
      final log = <String>[];
      final c = _composer(log: log);
      _type(c, 'nihongo');
      c.onSpace();
      expect(log, ['needs-dictionary']);
      expect(c.state.candidates.map((x) => x.text), ['にほんご', 'ニホンゴ']);
      c.onSpace();
      expect(c.state.preedit, 'ニホンゴ');
    });

    test('the composer reports nothing for a reset, and the buffer is gone', () {
      final c = _composer(dictionary: fixtureDictionary());
      _type(c, 'kyou');
      c.reset();
      expect(c.state.isEmpty, isTrue);
    });
  });

  group('12-key layout', () {
    test('tapping the centre again within a second steps the row: あ, い, う', () {
      final clock = _Clock();
      final c = _composer(layout: 'kana12_ja', clock: clock);
      c.onText('あ');
      clock.now = 400;
      c.onText('あ');
      expect(c.state.preedit, 'い');
      clock.now = 800;
      c.onText('あ');
      expect(c.state.preedit, 'う');
    });

    test('after the window the centre key types a new あ', () {
      final clock = _Clock();
      final c = _composer(layout: 'kana12_ja', clock: clock);
      c.onText('あ');
      clock.now = 1500;
      c.onText('あ');
      expect(c.state.preedit, 'ああ');
    });

    test('flick only: no multi-tap', () {
      final clock = _Clock();
      final c = _composer(
        layout: 'kana12_ja',
        clock: clock,
        settings: const BooBoardSettings(japanese: JapaneseSettings(flickOnly: true)),
      );
      c.onText('あ');
      clock.now = 100;
      c.onText('あ');
      expect(c.state.preedit, 'ああ');
    });

    test('a flick types its kana directly', () {
      final c = _composer(layout: 'kana12_ja');
      c.onText('い');
      expect(c.state.preedit, 'い');
    });

    test('kana_modifier steps か→が→か and は→ば→ぱ→は, and does nothing with an empty buffer', () {
      final c = _composer(layout: 'kana12_ja');
      expect(c.onCustomKey(ComposerKeys.kanaModifier).handled, isFalse);
      c.onText('か');
      c.onCustomKey(ComposerKeys.kanaModifier);
      expect(c.state.preedit, 'が');
      c.onCustomKey(ComposerKeys.kanaModifier);
      expect(c.state.preedit, 'か');
      c.onText('は');
      c.onCustomKey(ComposerKeys.kanaModifier);
      c.onCustomKey(ComposerKeys.kanaModifier);
      c.onCustomKey(ComposerKeys.kanaModifier);
      expect(c.state.preedit, 'かは', reason: 'three presses on は return to は');
    });

    test('undo_cycle undoes the last multi-tap step only', () {
      final clock = _Clock();
      final c = _composer(layout: 'kana12_ja', clock: clock);
      expect(c.onCustomKey(ComposerKeys.undoCycle).handled, isFalse);
      c.onText('あ');
      clock.now = 300;
      c.onText('あ');
      expect(c.state.preedit, 'い');
      c.onCustomKey(ComposerKeys.undoCycle);
      expect(c.state.preedit, 'あ');
    });

    test('a 12-key kana with a conversion commits the converted text when a kana key follows', () {
      final c = _composer(layout: 'kana12_ja', dictionary: fixtureDictionary());
      c.onText('き');
      c.onText('ょ');
      c.onText('う');
      c.onSpace();
      expect(c.state.preedit, '今日');
      final step = c.onText('は');
      expect(step.commit, '今日');
      expect(c.state.preedit, 'は');
    });
  });

  group('segments', () {
    test('the cursor keys move the focus; segment longer and shorter resize it', () {
      final c = _composer(dictionary: fixtureDictionary());
      _type(c, 'kyouha');
      c.onSpace();
      expect(c.state.preedit, '今日は');
      expect(c.onCustomKey(ComposerKeys.cursorRight).handled, isTrue);
      expect(c.state.reading, 'は');
      expect(c.onCustomKey(ComposerKeys.cursorLeft).handled, isTrue);
      expect(c.state.reading, 'きょう');
      c.onCustomKey(ComposerKeys.segmentLonger);
      expect(c.state.preedit, 'きょうは');
      c.onCustomKey(ComposerKeys.segmentShorter);
      expect(c.state.preedit, '今日は');
    });

    test('the cursor keys do nothing before a conversion', () {
      final c = _composer(dictionary: fixtureDictionary());
      _type(c, 'kyou');
      expect(c.onCustomKey(ComposerKeys.cursorLeft).handled, isFalse);
      expect(c.onCustomKey(ComposerKeys.segmentLonger).handled, isFalse);
    });

    test('a segment can be resized only within the reading', () {
      final c = _composer(dictionary: fixtureDictionary());
      _type(c, 'ha');
      c.onSpace();
      c.onCustomKey(ComposerKeys.segmentShorter);
      expect(c.state.preedit, 'は', reason: 'a one-character segment cannot shrink');
    });
  });

  group('learning', () {
    test('a picked dictionary word is learned and saved, when learning is allowed', () {
      final log = <String>[];
      final learning = JapaneseLearning();
      final c = _composer(dictionary: fixtureDictionary(), learning: learning, log: log);
      _type(c, 'kyou');
      c.onSpace();
      c.onEnter();
      expect(learning.count('きょう', '今日'), 1);
      expect(log, ['learned']);
    });

    test('nothing is learned when learning is not allowed (password, incognito)', () {
      final learning = JapaneseLearning();
      final c = _composer(dictionary: fixtureDictionary(), learning: learning, learningAllowed: false);
      _type(c, 'kyou');
      c.onSpace();
      c.onEnter();
      expect(learning.isEmpty, isTrue);
    });

    test('a kana form picked for a segment is not learned', () {
      final learning = JapaneseLearning();
      final c = _composer(dictionary: fixtureDictionary(), learning: learning);
      _type(c, 'kyou');
      c.onSpace();
      c.selectCandidate(c.state.candidates.indexWhere((x) => x.text == 'きょう'));
      expect(c.state.preedit, 'きょう');
      c.onEnter();
      expect(learning.isEmpty, isTrue);
    });

    test('learned picks round-trip through the blob bytes', () {
      final learning = JapaneseLearning()
        ..learn('かご', '籠')
        ..learn('かご', '籠')
        ..learn('かご', 'カゴ');
      final back = JapaneseLearning.fromBytes(learning.toBytes());
      expect(back.count('かご', '籠'), 2);
      expect(back.surfacesFor('かご'), ['籠', 'カゴ']);
      expect(JapaneseLearning.fromBytes(null).isEmpty, isTrue);
      expect(JapaneseLearning.fromBytes(learning.toBytes().sublist(0, 5)).isEmpty, isTrue);
    });
  });
}
