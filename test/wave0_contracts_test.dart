// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/in_memory_lexicon.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/settings/booboard_settings.dart';
import 'package:booboard/src/settings/settings_store.dart';

import 'support/fake_editor.dart';

void main() {
  group('InputFieldInfo', () {
    InputFieldInfo field(int inputType, [int imeOptions = 0]) =>
        InputFieldInfo(inputType: inputType, imeOptions: imeOptions);

    test('password fields are sensitive and never learn', () {
      final f = field(AndroidInputType.classText | AndroidInputType.textVariationPassword);
      expect(f.isPassword, isTrue);
      expect(f.isSensitive, isTrue);
      expect(f.allowsLearning, isFalse);
      expect(f.allowsSuggestions, isFalse);
    });

    test('number password is a password', () {
      expect(field(AndroidInputType.classNumber | AndroidInputType.numberVariationPassword).isPassword, isTrue);
    });

    test('incognito flag disables learning but not suggestions', () {
      final f = field(AndroidInputType.classText, AndroidImeOptions.flagNoPersonalizedLearning);
      expect(f.allowsLearning, isFalse);
      expect(f.allowsSuggestions, isTrue);
    });

    test('email fields get the email page and no autocorrect', () {
      final f = field(AndroidInputType.classText | AndroidInputType.textVariationEmailAddress);
      expect(f.preferredPage, PreferredPage.email);
      expect(f.allowsAutoCorrect, isFalse);
    });

    test('multi-line fields insert newlines; search fields run the action', () {
      expect(field(AndroidInputType.classText | AndroidInputType.textFlagMultiLine).enterInsertsNewline, isTrue);
      final search = field(AndroidInputType.classText, AndroidImeOptions.actionSearch);
      expect(search.enterInsertsNewline, isFalse);
      expect(search.action, ImeAction.search);
      expect(search.editorActionId, AndroidImeOptions.actionSearch);
    });

    test('phone and number pages', () {
      expect(field(AndroidInputType.classPhone).preferredPage, PreferredPage.phone);
      expect(field(AndroidInputType.classNumber).preferredPage, PreferredPage.number);
      expect(field(AndroidInputType.classNull).isRawKeyMode, isTrue);
    });
  });

  group('Layout JSON', () {
    test('parses shorthand and full keys', () {
      final layout = KeyboardLayoutDef.fromJson(
        jsonDecode('''
        {"id": "t", "name": "Test", "rows": [
          {"keys": ["q", {"output": "e", "popup": ["é", "è"], "hint": "3"}]},
          {"padding": 0.5, "keys": [{"type": "shift", "width": 1.5}, {"type": "space", "width": 5}]}
        ]}''') as Map<String, Object?>,
      );
      expect(layout.rows, hasLength(2));
      expect(layout.rows[0].keys[0].output, 'q');
      expect(layout.rows[0].keys[1].popup, ['é', 'è']);
      expect(layout.rows[0].keys[1].labelFor(shifted: true), 'E');
      expect(layout.rows[1].keys[0].type, KeyType.shift);
      expect(layout.rows[1].totalUnits, 7.5);
    });

    test('rejects unknown key types', () {
      expect(() => KeyDef.fromJson({'type': 'nope'}), throwsFormatException);
    });
  });

  group('Settings', () {
    test('round-trips and tolerates junk', () {
      const s = BooBoardSettings(typing: TypingSettings(autoCorrect: false));
      final back = BooBoardSettings.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>);
      expect(back.typing.autoCorrect, isFalse);
      final junk = BooBoardSettings.fromJson({
        'typing': 'oops',
        'languages': {'enabled': <String>[], 'active': 'xx'},
      });
      expect(junk.typing.autoCorrect, isTrue);
      expect(junk.languages.enabled, ['en']);
      expect(junk.languages.active, 'en');
    });

    test('store persists atomically and notifies the other engine', () async {
      final dir = await Directory.systemTemp.createTemp('booboard_settings');
      final notified = <String>[];
      final store = await SettingsStore.open(directory: dir.path, notifyOther: (s) async => notified.addAll(s));
      await store.update((v) => v.copyWith(swipe: v.swipe.copyWith(enabled: false)), sections: [SettingsSection.swipe]);
      final reopened = await SettingsStore.open(directory: dir.path);
      expect(reopened.value.swipe.enabled, isFalse);
      expect(notified, [SettingsSection.swipe]);
      await dir.delete(recursive: true);
    });
  });

  group('FakeEditor', () {
    test('composing then commit replaces the composing region', () async {
      final e = FakeEditor(text: 'say ');
      await e.setComposingText('helo');
      expect(e.debugView, 'say <helo>|');
      await e.commitText('hello ');
      expect(e.debugView, 'say hello |');
    });

    test('backspace deletes a whole emoji grapheme', () async {
      final e = FakeEditor(text: 'hi 👍🏽');
      await e.sendDownUpKeyEvent(AndroidKeyCode.del);
      expect(e.text, 'hi ');
    });

    test('caps mode at sentence start', () async {
      final e = FakeEditor(text: 'Done. ');
      expect(await e.getCursorCapsMode(AndroidCapsMode.sentences), AndroidCapsMode.sentences);
      final f = FakeEditor(text: 'Done and ');
      expect(await f.getCursorCapsMode(AndroidCapsMode.sentences), 0);
    });

    test('reports selection updates', () async {
      final updates = <SelectionMessage>[];
      final e = FakeEditor()..onSelectionChanged = updates.add;
      await e.commitText('abc');
      expect(updates.single.newSelStart, 3);
    });
  });

  test('in-memory lexicon ranks by frequency', () {
    final lex = InMemoryLexicon('en', kStarterEnglishWords);
    expect(lex.logProb('the')! > lex.logProb('keyboard')!, isTrue);
    expect(lex.logProb('zzz'), isNull);
  });
}
