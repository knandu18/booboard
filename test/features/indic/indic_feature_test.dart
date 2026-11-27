// SPDX-License-Identifier: GPL-3.0-or-later
//
// The Indic feature: English-letter typing in Hindi (transform on and off with the layout, Hinglish output,
// swipe mapping, no transform in URL fields), through a pumped KeyboardApp.
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/features/indic/indic_feature.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../../keyboard/support/app_harness.dart';

const _hindi = BooBoardSettings(
  languages: LanguageSettings(enabled: ['en', 'hi'], active: 'hi', layouts: {'hi': 'translit_hi'}),
);

const _hinglish = BooBoardSettings(
  languages: LanguageSettings(
    enabled: ['en', 'hi'],
    active: 'hi',
    layouts: {'hi': 'translit_hi'},
    hinglishOutput: true,
  ),
);

class _Probe extends KeyboardFeature {
  KeyboardSession? session;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return const KeyboardHooks();
  }
}

/// The table loads off the UI isolate; wait for it so the transform has candidates.
Future<void> _settle(WidgetTester tester, KeyboardSession s) async {
  for (var i = 0; i < 400; i++) {
    final ready = s.input.bar.value.suggestions.any((e) => e.kind == SuggestionKind.transliteration);
    if (ready) return;
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump();
  }
}

void _type(KeyboardSession s, String word) {
  for (final ch in word.split('')) {
    s.input.onText(ch);
  }
}

Future<(AppHarness, KeyboardSession)> _boot(
  WidgetTester tester, {
  BooBoardSettings settings = _hindi,
  EditorInfoMessage? field,
}) async {
  final h = AppHarness(settings: settings);
  final probe = _Probe();
  await h.pump(tester, features: [createIndicFeature(), probe]);
  await h.focus(tester, field);
  return (h, probe.session!);
}

void main() {
  testWidgets('English letters in Hindi: the strip offers the native word first', (tester) async {
    final (h, s) = await _boot(tester);
    expect(s.activeLanguage.value, 'hi');
    _type(s, 'namaste');
    await _settle(tester, s);
    expect(s.input.bar.value.suggestions.first.text, 'नमस्ते');
    expect(s.input.bar.value.suggestions.map((e) => e.text), contains('namaste'));
    expect(s.spaceLabelOverride.value, isNull);
  });

  testWidgets('space commits the native word, even with autocorrect off', (tester) async {
    final (h, s) = await _boot(
      tester,
      settings: const BooBoardSettings(
        typing: TypingSettings(autoCorrect: false),
        languages: LanguageSettings(enabled: ['en', 'hi'], active: 'hi', layouts: {'hi': 'translit_hi'}),
      ),
    );
    _type(s, 'namaste');
    await _settle(tester, s);
    s.input.onSpace();
    await tester.pump();
    expect(h.editor.text, 'नमस्ते ');
  });

  testWidgets('a known English word commits as typed, with the native word offered', (tester) async {
    final (h, s) = await _boot(tester);
    h.predictor.known = {'time'};
    _type(s, 'time');
    await _settle(tester, s);
    expect(s.input.bar.value.suggestions.map((e) => e.text), containsAll(['time', 'टाइम']));
    s.input.onSpace();
    await tester.pump();
    expect(h.editor.text, 'time ');
  });

  testWidgets('Hinglish output: the Latin word commits, the native word is only offered', (tester) async {
    final (h, s) = await _boot(tester, settings: _hinglish);
    expect(s.spaceLabelOverride.value, 'Hinglish');
    _type(s, 'dosto');
    await _settle(tester, s);
    expect(s.input.bar.value.suggestions.map((e) => e.text), contains('दोस्तों'));
    s.input.onSpace();
    await tester.pump();
    expect(h.editor.text, 'dosto ');
  });

  testWidgets('never in URL fields: no native candidates and no autocorrection', (tester) async {
    final (h, s) = await _boot(
      tester,
      field: editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationUri),
    );
    _type(s, 'namaste');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(s.input.bar.value.suggestions.where((e) => e.kind == SuggestionKind.transliteration), isEmpty);
    s.input.onSpace();
    await tester.pump();
    expect(h.editor.text, 'namaste ');
  });

  testWidgets('a native layout turns the transform off', (tester) async {
    final (h, s) = await _boot(tester);
    expect(s.input.transform.value, isNotNull);
    await h.store.update(
      (m) => m.copyWith(languages: m.languages.copyWith(layouts: {'hi': 'phonetic_hi'})),
      sections: [SettingsSection.languages],
    );
    await tester.pump();
    expect(s.input.transform.value, isNull);
    expect(s.input.swipeTransform.value, isNull);
    expect(s.spaceLabelOverride.value, isNull);
  });

  testWidgets('English is untouched: no transform for an English layout', (tester) async {
    final h = AppHarness();
    final probe = _Probe();
    await h.pump(tester, features: [createIndicFeature(), probe]);
    await h.focus(tester);
    expect(probe.session!.input.transform.value, isNull);
  });

  testWidgets('swipe: romanised candidates map to the native word (not with Hinglish)', (tester) async {
    final (_, s) = await _boot(tester);
    await _settle(tester, s);
    final swipe = s.input.swipeTransform.value;
    expect(swipe, isNotNull);
    final mapped = swipe!([const Suggestion('namaste', kind: SuggestionKind.gesture, score: 1)]);
    expect(mapped.first.text, 'नमस्ते');
    expect(mapped.first.kind, SuggestionKind.gesture);
    final untouched = swipe([const Suggestion('zzzzq', kind: SuggestionKind.gesture, score: 1)]);
    expect(untouched.first.text, 'zzzzq');
  });

  testWidgets('swipe is off with Hinglish output', (tester) async {
    final (_, s) = await _boot(tester, settings: _hinglish);
    expect(s.input.swipeTransform.value, isNull);
  });
}
