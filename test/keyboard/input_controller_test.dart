// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/keyboard/input/input_controller.dart';
import 'package:booboard/src/keyboard/input/keyboard_page.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../support/fake_editor.dart';
import 'support/fakes.dart';

InputFieldInfo textField({int flags = 0, int variation = 0, int ime = 0, String? pkg, int caps = 0}) => InputFieldInfo(
  inputType: AndroidInputType.classText | variation | flags,
  imeOptions: ime,
  packageName: pkg,
  initialCapsMode: caps,
);

class Harness {
  Harness({String text = '', BooBoardSettings? settings}) : settings = settings ?? const BooBoardSettings() {
    editor = FakeEditor(text: text);
    controller = InputController(
      input: editor,
      predictor: predictor,
      gestureDecoder: decoder,
      settings: () => this.settings,
      clock: () => nowMs,
    );
    editor.onSelectionChanged = controller.onSelectionChanged;
  }

  BooBoardSettings settings;
  late final FakeEditor editor;
  final predictor = FakePredictor();
  final decoder = FakeGestureDecoder();
  late final InputController controller;
  int nowMs = 1000;

  Future<void> start([InputFieldInfo? field]) => controller.startInput(field ?? textField());

  /// Types characters like the view does: shift state decides the case.
  Future<void> type(String chars) async {
    for (final ch in chars.split('')) {
      if (ch == ' ') {
        controller.onSpace();
      } else {
        final cased = controller.shift.value == ShiftState.off ? ch : ch.toUpperCase();
        controller.onText(cased);
      }
      nowMs += 80;
      await Future<void>.delayed(Duration.zero);
    }
  }

  String get text => editor.text;
}

void main() {
  group('typing and composing', () {
    test('letters are composed and suggestions update', () async {
      final h = Harness();
      await h.start();
      await h.type('hel');
      expect(h.editor.composing, 'hel');
      expect(h.controller.composing, 'hel');
      expect(h.controller.bar.value.isComposing, isTrue);
      expect(h.controller.bar.value.suggestions.first.text, 'hel');
      expect(h.controller.bar.value.typedWordUnknown, isTrue);
    });

    test('a space commits the word and learns it with context', () async {
      final h = Harness();
      await h.start();
      await h.type('hello world ');
      expect(h.text, 'hello world ');
      expect(h.editor.composing, isNull);
      expect(h.predictor.committed, ['hello', 'world']);
      expect(h.predictor.committedContext.last, ['hello']);
    });

    test('backspace edits the composing word, then the committed text', () async {
      final h = Harness();
      await h.start();
      await h.type('hell');
      h.controller.onBackspace();
      expect(h.editor.composing, 'hel');
      h.controller.onBackspace();
      h.controller.onBackspace();
      h.controller.onBackspace();
      expect(h.text, '');
      expect(h.editor.composing == null || h.editor.composing!.isEmpty, isTrue);
      await h.type('ab ');
      h.controller.onBackspace();
      expect(h.text, 'ab');
    });

    test('digits and punctuation are not composed', () async {
      final h = Harness();
      await h.start();
      h.controller.onText('1');
      h.controller.onText('2');
      expect(h.editor.composing, isNull);
      expect(h.text, '12');
      await h.type('ab');
      h.controller.onText('1');
      expect(h.controller.composing, 'ab1');
    });

    test('apostrophes inside words stay in the word', () async {
      final h = Harness();
      await h.start();
      await h.type("don't");
      expect(h.controller.composing, "don't");
    });

    test('multi-character keys commit literally after finishing the word', () async {
      final h = Harness();
      await h.start(textField(variation: AndroidInputType.textVariationEmailAddress));
      await h.type('me');
      h.controller.onText('@');
      await h.type('x');
      h.controller.onText('.com');
      expect(h.text, 'me@x.com');
      expect(h.editor.composing, isNull);
    });
  });

  group('autocorrect', () {
    test('applies on a separator and reverts on backspace', () async {
      final h = Harness();
      await h.start();
      await h.type('teh ');
      expect(h.text, 'the ');
      h.controller.onBackspace();
      expect(h.text, 'teh');
      expect(h.editor.composing, 'teh');
      expect(h.predictor.reverted, [('teh', 'the')]);
      // The reverted word is not corrected again.
      await h.type(' ');
      expect(h.text, 'teh ');
    });

    test('applies before punctuation', () async {
      final h = Harness();
      await h.start();
      await h.type('teh');
      h.controller.onText('.');
      expect(h.text, 'the.');
    });

    test('off when the setting is off or the field forbids it', () async {
      final h = Harness(settings: const BooBoardSettings(typing: TypingSettings(autoCorrect: false)));
      await h.start();
      await h.type('teh ');
      expect(h.text, 'teh ');
      final e = Harness();
      await e.start(textField(variation: AndroidInputType.textVariationEmailAddress));
      await e.type('teh ');
      expect(e.text, 'teh ');
    });

    test('never touches words with digits, handles or camelCase', () async {
      final h = Harness();
      await h.start();
      h.controller.onText('@');
      await h.type('teh ');
      expect(h.text, '@teh ');
      final h2 = Harness();
      await h2.start();
      await h2.type('teh');
      h2.controller.onText('1');
      await h2.type(' ');
      expect(h2.text, 'teh1 ');
    });
  });

  group('suggestions', () {
    test('picking replaces the composing word and adds a space', () async {
      final h = Harness();
      await h.start();
      h.predictor.completions = {
        'hel': ['hello'],
      };
      await h.type('hel');
      h.controller.onSuggestionPicked(h.controller.bar.value.suggestions[1]);
      expect(h.text, 'hello ');
      expect(h.editor.composing, isNull);
      expect(h.predictor.committed.last, 'hello');
    });

    test('next-word predictions show when nothing is composing and can be picked', () async {
      final h = Harness();
      await h.start();
      expect(h.controller.bar.value.suggestions.map((s) => s.text), ['the', 'a', 'I']);
      h.controller.onSuggestionPicked(h.controller.bar.value.suggestions.first);
      expect(h.text, 'the ');
    });

    test('next-word prediction can be switched off', () async {
      final h = Harness(settings: const BooBoardSettings(typing: TypingSettings(nextWordPrediction: false)));
      await h.start();
      expect(h.controller.bar.value.suggestions, isEmpty);
    });

    test('no next-word predictions in email or URL fields, but typed-word suggestions stay', () async {
      for (final v in [AndroidInputType.textVariationEmailAddress, AndroidInputType.textVariationUri]) {
        final h = Harness();
        await h.start(textField(variation: v));
        expect(h.controller.bar.value.suggestions, isEmpty, reason: 'variation $v');
        await h.type('hel');
        expect(h.controller.bar.value.suggestions, isNotEmpty, reason: 'variation $v');
      }
    });

    test('no suggestions in fields that forbid them', () async {
      final h = Harness();
      await h.start(textField(flags: AndroidInputType.textFlagNoSuggestions));
      await h.type('hel');
      expect(h.editor.composing, isNull);
      expect(h.controller.bar.value.suggestions, isEmpty);
      expect(h.text, 'hel');
    });
  });

  group('spacing', () {
    test('double space becomes a period', () async {
      final h = Harness();
      await h.start();
      await h.type('hello  ');
      expect(h.text, 'hello. ');
    });

    test('double space period can be disabled', () async {
      final h = Harness(settings: const BooBoardSettings(typing: TypingSettings(doubleSpacePeriod: false)));
      await h.start();
      await h.type('hello  ');
      expect(h.text, 'hello  ');
    });

    test('a space after punctuation we added is ignored', () async {
      final h = Harness();
      await h.start();
      await h.type('hello  ');
      await h.type(' ');
      expect(h.text, 'hello. ');
    });

    test('punctuation swallows the auto-space after a picked suggestion and adds one', () async {
      final h = Harness();
      await h.start();
      h.predictor.completions = {
        'hel': ['hello'],
      };
      await h.type('hel');
      h.controller.onSuggestionPicked(h.controller.bar.value.suggestions[1]);
      h.controller.onText(',');
      expect(h.text, 'hello, ');
      await h.type('w');
      expect(h.text, 'hello, w');
    });

    test('closing brackets swallow the space but add none', () async {
      final h = Harness();
      await h.start();
      await h.type('(hello');
      h.controller.onSuggestionPicked(const Suggestion('hello', kind: SuggestionKind.completion));
      h.controller.onText(')');
      expect(h.text, '(hello)');
    });

    test('punctuation typed right after a word is left alone', () async {
      final h = Harness();
      await h.start();
      await h.type('hello');
      h.controller.onText(',');
      expect(h.text, 'hello,');
    });

    test('a space on a symbols page returns to letters', () async {
      final h = Harness();
      await h.start();
      h.controller.setPage(KeyboardPage.symbols);
      h.controller.onText('1');
      h.controller.onSpace();
      expect(h.controller.page.value, KeyboardPage.letters);
    });
  });

  group('shift and capitalisation', () {
    test('shift tap is one-shot; a quick second tap locks caps; another unlocks', () async {
      final h = Harness();
      await h.start();
      h.controller.onShiftTap();
      expect(h.controller.shift.value, ShiftState.once);
      h.nowMs += 100;
      h.controller.onShiftTap();
      expect(h.controller.shift.value, ShiftState.caps);
      h.nowMs += 1000;
      h.controller.onShiftTap();
      expect(h.controller.shift.value, ShiftState.off);
      h.nowMs += 1000;
      h.controller.onShiftTap();
      h.nowMs += 1000;
      h.controller.onShiftTap();
      expect(h.controller.shift.value, ShiftState.off, reason: 'slow second tap turns one-shot off');
    });

    test('one-shot shift is used up by one letter; caps lock stays', () async {
      final h = Harness();
      await h.start();
      h.controller.onShiftTap();
      await h.type('ab');
      expect(h.text, 'Ab');
      expect(h.controller.shift.value, ShiftState.off);
      h.controller.onShiftTap();
      h.nowMs += 100;
      h.controller.onShiftTap();
      await h.type('cd');
      expect(h.text, 'AbCD');
      expect(h.controller.shift.value, ShiftState.caps);
    });

    test('auto-capitalises at the start of a sentence field', () async {
      final h = Harness();
      await h.start(textField(flags: AndroidInputType.textFlagCapSentences, caps: AndroidCapsMode.sentences));
      expect(h.controller.shift.value, ShiftState.once);
      await h.type('hi');
      expect(h.text, 'Hi');
      expect(h.controller.shift.value, ShiftState.off);
    });

    test('auto-capitalises after a sentence end and a space', () async {
      final h = Harness();
      await h.start(textField(flags: AndroidInputType.textFlagCapSentences));
      await h.type('hi');
      h.controller.onText('.');
      await Future<void>.delayed(Duration.zero);
      expect(h.controller.shift.value, ShiftState.off, reason: 'no space yet');
      await h.type(' ');
      await Future<void>.delayed(Duration.zero);
      expect(h.controller.shift.value, ShiftState.once);
    });

    test('auto-capitalise setting and fields without cap flags are respected', () async {
      final off = Harness(settings: const BooBoardSettings(typing: TypingSettings(autoCapitalize: false)));
      await off.start(textField(flags: AndroidInputType.textFlagCapSentences, caps: AndroidCapsMode.sentences));
      expect(off.controller.shift.value, ShiftState.off);
      final none = Harness();
      await none.start(textField());
      expect(none.controller.shift.value, ShiftState.off);
    });

    test('cap-characters fields start in caps lock', () async {
      final h = Harness();
      await h.start(textField(flags: AndroidInputType.textFlagCapCharacters, caps: AndroidCapsMode.characters));
      expect(h.controller.shift.value, ShiftState.caps);
    });

    test('auto-caps after enter in a multi-line field', () async {
      final h = Harness();
      await h.start(
        textField(
          flags: AndroidInputType.textFlagCapSentences | AndroidInputType.textFlagMultiLine,
          caps: AndroidCapsMode.sentences,
        ),
      );
      await h.type('hi');
      h.controller.onText('.');
      h.controller.onEnter();
      await Future<void>.delayed(Duration.zero);
      expect(h.text, 'Hi.\n');
      expect(h.controller.shift.value, ShiftState.once);
    });
  });

  group('enter', () {
    test('multi-line fields insert a newline', () async {
      final h = Harness();
      await h.start(textField(flags: AndroidInputType.textFlagMultiLine));
      await h.type('hi');
      h.controller.onEnter();
      expect(h.text, 'hi\n');
      expect(h.editor.editorActions, isEmpty);
    });

    test('single-line fields perform the editor action', () async {
      final h = Harness();
      await h.start(textField(ime: AndroidImeOptions.actionSearch));
      await h.type('cats');
      h.controller.onEnter();
      expect(h.text, 'cats');
      expect(h.editor.editorActions, [AndroidImeOptions.actionSearch]);
      expect(h.editor.composing, isNull);
    });

    test('a custom action id wins', () async {
      final h = Harness();
      await h.start(
        const InputFieldInfo(
          inputType: AndroidInputType.classText,
          imeOptions: AndroidImeOptions.actionGo,
          actionId: 42,
        ),
      );
      h.controller.onEnter();
      expect(h.editor.editorActions, [42]);
    });

    test('long-press on enter in a multi-line field runs the action', () async {
      final h = Harness();
      await h.start(
        textField(
          flags: AndroidInputType.textFlagMultiLine,
          ime: AndroidImeOptions.actionSend | AndroidImeOptions.flagNoEnterAction,
        ),
      );
      h.controller.onEnterLongPress();
      expect(h.editor.editorActions, [AndroidImeOptions.actionSend]);
    });
  });

  group('password fields', () {
    final password = textField(variation: AndroidInputType.textVariationPassword);

    test('no composing, suggestions, learning or capitalisation', () async {
      final h = Harness();
      await h.start(password);
      await h.type('abc ');
      h.controller.onText('1');
      expect(h.text, 'abc 1');
      expect(h.editor.composing, isNull);
      expect(h.controller.bar.value.suggestions, isEmpty);
      expect(h.predictor.suggestCalls, 0);
      expect(h.predictor.committed, isEmpty);
      expect(h.controller.shift.value, ShiftState.off);
    });

    test('no double-space period and no autocorrect', () async {
      final h = Harness();
      await h.start(password);
      await h.type('teh  ');
      expect(h.text, 'teh  ');
    });

    test('swipe is ignored', () async {
      final h = Harness();
      await h.start(password);
      h.decoder.result = ['hello'];
      await h.controller.commitSwipe(const GesturePath([TouchPoint(0, 0, 0)]));
      expect(h.text, '');
      expect(h.decoder.decoded, isEmpty);
    });
  });

  group('raw key mode', () {
    const raw = InputFieldInfo(inputType: AndroidInputType.classNull, imeOptions: 0);

    test('commits text without composing and uses key events for enter and backspace', () async {
      final h = Harness();
      await h.start(raw);
      await h.type('ls -l');
      expect(h.text, 'ls -l');
      expect(h.editor.composing, isNull);
      h.controller.onBackspace();
      expect(h.text, 'ls -');
      h.controller.onEnter();
      expect(h.text, 'ls -\n');
      expect(h.editor.log, containsAll(['key(${AndroidKeyCode.del})', 'key(${AndroidKeyCode.enter})']));
      expect(h.editor.editorActions, isEmpty);
    });
  });

  group('learning permission', () {
    test('allowed by default', () async {
      final h = Harness();
      await h.start();
      await h.type('hello ');
      expect(h.predictor.committedAllowLearning, [true]);
    });

    test('off for incognito, learning toggle, incognito apps and no-personalised-learning fields', () async {
      Future<bool> learns(BooBoardSettings s, InputFieldInfo f) async {
        final h = Harness(settings: s);
        await h.start(f);
        await h.type('hello ');
        return h.predictor.committedAllowLearning.single;
      }

      expect(await learns(const BooBoardSettings(privacy: PrivacySettings(incognito: true)), textField()), isFalse);
      expect(await learns(const BooBoardSettings(privacy: PrivacySettings(learning: false)), textField()), isFalse);
      expect(
        await learns(
          const BooBoardSettings(privacy: PrivacySettings(incognitoApps: ['com.bank'])),
          textField(pkg: 'com.bank'),
        ),
        isFalse,
      );
      expect(
        await learns(const BooBoardSettings(), textField(ime: AndroidImeOptions.flagNoPersonalizedLearning)),
        isFalse,
      );
      expect(await learns(const BooBoardSettings(), textField(pkg: 'com.other')), isTrue);
    });

    test('incognito indicator', () async {
      final h = Harness(
        settings: const BooBoardSettings(privacy: PrivacySettings(incognitoApps: ['com.bank'])),
      );
      await h.start(textField(pkg: 'com.bank'));
      expect(h.controller.isIncognito, isTrue);
    });

    test('shouldSecureWindow follows password fields and the privacy setting', () {
      final pw = textField(variation: AndroidInputType.textVariationPassword);
      expect(shouldSecureWindow(pw, const PrivacySettings()), isTrue);
      expect(shouldSecureWindow(textField(), const PrivacySettings()), isFalse);
      expect(shouldSecureWindow(textField(), const PrivacySettings(hideFromScreenshots: true)), isTrue);
      expect(
        shouldSecureWindow(textField(ime: AndroidImeOptions.flagNoPersonalizedLearning), const PrivacySettings()),
        isTrue,
      );
    });
  });

  group('editor events', () {
    test('a cursor jump finishes composing and resets state', () async {
      final h = Harness(text: 'one two three');
      await h.start();
      await h.type('hel');
      expect(h.editor.composing, isNotNull);
      h.nowMs += 500;
      await h.editor.setSelection(0, 0);
      expect(h.controller.composing, '');
      expect(h.editor.composing, isNull);
      expect(h.text, 'one two threehel');
      // Backspace after a jump deletes plainly, it does not revert anything.
      h.controller.onBackspace();
      expect(h.predictor.reverted, isEmpty);
    });

    test('our own edits are not mistaken for jumps', () async {
      final h = Harness();
      await h.start();
      await h.type('hello wor');
      expect(h.controller.composing, 'wor');
      expect(h.editor.composing, 'wor');
    });

    test('startInput reads up to three previous words', () async {
      final h = Harness(text: 'good morning my dear friend ');
      await h.start();
      expect(h.controller.previousWords, ['my', 'dear', 'friend']);
    });

    test('startInput picks the page for the field', () async {
      final h = Harness();
      await h.start(const InputFieldInfo(inputType: AndroidInputType.classNumber, imeOptions: 0));
      expect(h.controller.page.value, KeyboardPage.numpad);
      await h.start(const InputFieldInfo(inputType: AndroidInputType.classPhone, imeOptions: 0));
      expect(h.controller.page.value, KeyboardPage.phone);
      await h.start(textField());
      expect(h.controller.page.value, KeyboardPage.letters);
    });

    test('a restart of the same field keeps the symbols page', () async {
      final h = Harness();
      final f = textField();
      await h.controller.startInput(f);
      h.controller.setPage(KeyboardPage.symbols);
      await h.controller.startInput(f, restarting: true);
      expect(h.controller.page.value, KeyboardPage.symbols);
      await h.controller.startInput(textField(ime: AndroidImeOptions.actionDone), restarting: true);
      expect(h.controller.page.value, KeyboardPage.letters);
    });

    test('finishInput commits the composing word', () async {
      final h = Harness();
      await h.start();
      await h.type('hel');
      h.controller.finishInput();
      expect(h.editor.composing, isNull);
      expect(h.text, 'hel');
    });
  });

  group('backspace words', () {
    test('deleteWordBackward removes the last word and the spaces after it', () async {
      final h = Harness();
      await h.start();
      await h.type('one two ');
      h.controller.deleteWordBackward();
      expect(h.text, 'one ');
      h.controller.deleteWordBackward();
      expect(h.text, '');
    });

    test('deleteWordBackward clears the composing word first', () async {
      final h = Harness();
      await h.start();
      await h.type('one tw');
      h.controller.deleteWordBackward();
      expect(h.text, 'one ');
    });

    test('moveCursor finishes composing and moves', () async {
      final h = Harness();
      await h.start();
      await h.type('abc');
      h.controller.moveCursor(-1);
      expect(h.editor.selectionStart, 2);
      expect(h.editor.composing, isNull);
    });
  });

  group('gesture typing', () {
    const path = GesturePath([TouchPoint(0, 0, 0), TouchPoint(50, 0, 20)]);

    test('commits the top candidate with a trailing space and shows the alternatives', () async {
      final h = Harness();
      await h.start();
      h.decoder.result = ['hello', 'help', 'hell'];
      await h.controller.commitSwipe(path);
      expect(h.text, 'hello ');
      expect(h.controller.bar.value.fromSwipe, isTrue);
      expect(h.controller.bar.value.suggestions.map((s) => s.text), ['hello', 'help', 'hell']);
      expect(h.predictor.committed, ['hello']);
    });

    test('adds a space before the word when the previous character is a letter', () async {
      final h = Harness();
      await h.start();
      await h.type('hi');
      h.decoder.result = ['there'];
      await h.controller.commitSwipe(path);
      expect(h.text, 'hi there ');
    });

    test('no extra space after a space', () async {
      final h = Harness(text: 'hi ');
      await h.start();
      h.decoder.result = ['there'];
      await h.controller.commitSwipe(path);
      expect(h.text, 'hi there ');
    });

    test('backspace right after a swipe deletes the whole word', () async {
      final h = Harness();
      await h.start();
      await h.type('hi');
      h.decoder.result = ['there'];
      await h.controller.commitSwipe(path);
      h.controller.onBackspace();
      expect(h.text, 'hi');
      // A second backspace is an ordinary one.
      h.controller.onBackspace();
      expect(h.text, 'h');
    });

    test('a swipe after shift is capitalised', () async {
      final h = Harness();
      await h.start();
      h.controller.onShiftTap();
      h.decoder.result = ['hello'];
      await h.controller.commitSwipe(path);
      expect(h.text, 'Hello ');
      expect(h.controller.shift.value, ShiftState.off);
    });

    test('picking an alternative replaces the swiped word', () async {
      final h = Harness();
      await h.start();
      h.decoder.result = ['hello', 'help'];
      await h.controller.commitSwipe(path);
      h.controller.onSuggestionPicked(h.controller.bar.value.suggestions[1]);
      expect(h.text, 'help ');
    });

    test('punctuation after a swipe swallows its space', () async {
      final h = Harness();
      await h.start();
      h.decoder.result = ['hello'];
      await h.controller.commitSwipe(path);
      h.controller.onText('!');
      expect(h.text, 'hello! ');
    });

    test('the previous words are passed to the decoder', () async {
      final h = Harness(text: 'good morning ');
      await h.start();
      h.decoder.result = ['sunshine'];
      await h.controller.commitSwipe(path);
      expect(h.decoder.decodedContext.single, ['good', 'morning']);
    });

    test('does nothing when the decoder has no candidates or swipe is off', () async {
      final h = Harness();
      await h.start();
      await h.controller.commitSwipe(path);
      expect(h.text, '');
      final off = Harness(settings: const BooBoardSettings(swipe: SwipeSettings(enabled: false)));
      await off.start();
      off.decoder.result = ['hello'];
      await off.controller.commitSwipe(path);
      expect(off.text, '');
    });
  });

  test('multi-step edits are batched', () async {
    final h = Harness();
    await h.start();
    await h.type('teh ');
    h.controller.onBackspace();
    expect(h.editor.log, containsAllInOrder(['delete(4,0)', 'compose("teh")']));
  });

  test('selection messages for our own batch edits do not reset composing', () async {
    final h = Harness();
    await h.start();
    h.editor.onSelectionChanged = (SelectionMessage m) => h.controller.onSelectionChanged(m);
    await h.type('a');
    expect(h.controller.composing, 'a');
  });
}
