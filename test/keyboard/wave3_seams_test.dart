// SPDX-License-Identifier: GPL-3.0-or-later
//
// The Wave 3 seams: language registry and blending, layout variants (currency, globe key, native
// digits, domains), language switching, the transliteration transform, the strip's toolbar toggle,
// and the voice event stream.

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/engine/lang/registry.dart';
import 'package:booboard/src/keyboard/input/keyboard_page.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/keyboard/layout/layout_repository.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import 'support/app_harness.dart';

class _Probe extends KeyboardFeature {
  _Probe([this.hooks = const KeyboardHooks()]);

  final KeyboardHooks hooks;
  KeyboardSession? session;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return hooks;
  }
}

const _multi = BooBoardSettings(
  languages: LanguageSettings(enabled: ['en', 'de', 'hi', 'ru'], layouts: {'de': 'qwerty'}),
);

void main() {
  group('registry', () {
    test('every language has a layout, and ids are unique', () {
      final ids = allLanguages.map((l) => l.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, containsAll(['en', 'es', 'fr', 'de', 'pt-BR', 'pt-PT', 'id', 'ru', 'uk']));
      expect(ids, containsAll(['hi', 'mr', 'bn', 'ta', 'te', 'ar', 'ur']));
      for (final l in allLanguages) {
        expect(l.layouts, isNotEmpty, reason: l.id);
        if (l.nativeDigits != null) expect(l.nativeDigits!.runes, hasLength(10), reason: l.id);
      }
      expect(languageInfo('ar').isRtl, isTrue);
      expect(languageInfo('xx').layouts.first.id, 'qwerty');
    });

    test('blending follows the script the active layout types', () {
      final l = _multi.languages;
      expect(blendedLanguages(l), ['en', 'de']);
      expect(blendedLanguages(l.copyWith(active: 'hi')), ['hi', 'en', 'de']);
      expect(blendedLanguages(l.copyWith(active: 'ru')), ['ru']);
      expect(blendedLanguages(l.copyWith(multilingual: false)), ['en']);
      expect(blendedLanguages(l.copyWith(active: 'hi', layouts: {'hi': 'inscript_hi'})), [
        'hi',
      ], reason: 'a Devanagari layout blends with no Latin language');
    });
  });

  group('layout variants', () {
    final qwerty = loadLayoutSync('qwerty');
    final symbols = loadLayoutSync('symbols');

    test('currency key types the language currency; \$ moves to its popup', () {
      final l = LayoutVariants.withCurrency(symbols, '€');
      final key = l.rows.expand((r) => r.keys).firstWhere((k) => k.id == 'currency');
      expect(key.output, '€');
      expect(key.popup.first, r'$');
      expect(key.popup.where((p) => p == '€'), isEmpty);
      expect(identical(LayoutVariants.withCurrency(symbols, r'$'), symbols), isTrue);
    });

    test('globe key goes after ?123 and takes one unit from the space bar', () {
      final l = LayoutVariants.withLanguageKey(qwerty);
      final row = l.rows.last.keys;
      double space(Iterable<KeyDef> keys) => keys.firstWhere((k) => k.type == KeyType.space).width;
      expect(row[1].type, KeyType.globe);
      expect(space(row), space(qwerty.rows.last.keys) - 1);
      expect(identical(LayoutVariants.withLanguageKey(l), l), isTrue);
    });

    test('native digits replace ASCII digits, which stay in the popup', () {
      final l = LayoutVariants.withDigits(LayoutVariants.withNumberRow(qwerty), '०१२३४५६७८९');
      final digits = l.rows.first.keys;
      expect(digits.first.output, '१');
      expect(digits.first.popup.first, '1');
      expect(l.rows[1].keys.first.output, 'q');
    });

    test('email .com popup starts with the language domains', () {
      final l = LayoutVariants.forField(qwerty, PreferredPage.email, domains: ['.de', '.com', '.at']);
      final dotcom = l.rows.expand((r) => r.keys).firstWhere((k) => k.id == 'dotcom');
      expect(dotcom.popup.take(2), ['.de', '.at']);
      expect(dotcom.popup, isNot(contains('.com')));
    });
  });

  group('session languages', () {
    testWidgets('switching cycles enabled languages and updates blend, rules and space label', (tester) async {
      final h = AppHarness(settings: _multi);
      final probe = _Probe();
      await h.pump(tester, features: [probe]);
      await h.focus(tester);
      final s = probe.session!;
      expect(s.activeLanguage.value, 'en');
      expect(s.spaceLabel.value, 'English');
      expect(h.predictor.languages, ['en', 'de']);

      await s.switchLanguage();
      await tester.pump();
      expect(s.activeLanguage.value, 'de');
      expect(s.spaceLabel.value, 'Deutsch');
      expect(s.input.language, 'de');
      expect(h.predictor.languages, ['de', 'en']);

      await s.switchLanguage('ru');
      await tester.pump();
      expect(s.activeLanguage.value, 'ru');
      expect(s.activeLayout.id, 'jcuken_ru');
      expect(h.store.value.languages.active, 'ru');
      await s.switchLanguage('ja');
      expect(s.activeLanguage.value, 'ru', reason: 'not enabled');
    });

    testWidgets('one language: no globe key and no space label', (tester) async {
      final h = AppHarness();
      final probe = _Probe();
      await h.pump(tester, features: [probe]);
      await h.focus(tester);
      final s = probe.session!;
      expect(s.spaceLabel.value, isNull);
      final layout = s.layoutFor(KeyboardPage.letters, InputFieldInfo.plainText, h.store.value)!;
      expect(layout.rows.expand((r) => r.keys).where((k) => k.type == KeyType.globe), isEmpty);
    });

    testWidgets('the globe key switches language when several are enabled', (tester) async {
      final h = AppHarness(settings: _multi);
      final probe = _Probe();
      await h.pump(tester, features: [probe]);
      await h.focus(tester);
      final s = probe.session!;
      final layout = s.layoutFor(KeyboardPage.letters, InputFieldInfo.plainText, h.store.value)!;
      await tester.tapAt(KeyFinder(tester, layout).type(KeyType.globe));
      await tester.pump(const Duration(milliseconds: 50));
      expect(s.activeLanguage.value, 'de');
    });
  });

  group('transliteration transform', () {
    SuggestionResult translit(SuggestionResult base, TypingContext c) => c.composing == 'namaste'
        ? const SuggestionResult(
            suggestions: [Suggestion('नमस्ते', kind: SuggestionKind.transliteration, display: 'नमस्ते')],
            autoCorrection: Suggestion('नमस्ते', kind: SuggestionKind.transliteration),
          )
        : base;

    Future<(AppHarness, KeyboardSession)> boot(
      WidgetTester tester,
      BooBoardSettings settings, [
      EditorInfoMessage? f,
    ]) async {
      final h = AppHarness(settings: settings);
      final probe = _Probe();
      await h.pump(tester, features: [probe]);
      await h.focus(tester, f);
      probe.session!.input.transform.value = translit;
      return (h, probe.session!);
    }

    void type(KeyboardSession s, String word) {
      for (final ch in word.split('')) {
        s.input.onText(ch);
      }
      s.input.onSpace();
    }

    testWidgets('space commits the native word even with autocorrect off', (tester) async {
      final (h, s) = await boot(tester, const BooBoardSettings(typing: TypingSettings(autoCorrect: false)));
      type(s, 'namaste');
      await tester.pump();
      expect(h.editor.text, 'नमस्ते ');
    });

    testWidgets('never in URL fields', (tester) async {
      final (h, s) = await boot(
        tester,
        const BooBoardSettings(),
        editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationUri),
      );
      type(s, 'namaste');
      await tester.pump();
      expect(h.editor.text, 'namaste ');
    });
  });

  group('strip toolbar toggle', () {
    testWidgets('the leading button shows the toolbar over predictions; typing brings them back', (tester) async {
      final h = AppHarness();
      final probe = _Probe(KeyboardHooks(onTranslate: () {}, onVoice: () {}));
      await h.pump(tester, features: [probe]);
      await h.focus(tester);
      // Next-word predictions fill an empty plain-text field.
      expect(find.text('the'), findsOneWidget);
      expect(find.bySemanticsLabel('Settings'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Show toolbar'));
      await tester.pump();
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      expect(find.bySemanticsLabel('Translate'), findsOneWidget);
      expect(find.bySemanticsLabel('Voice typing'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Show suggestions'));
      await tester.pump();
      expect(find.text('the'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Show toolbar'));
      await tester.pump();
      probe.session!.input.onText('h');
      await tester.pump();
      expect(find.bySemanticsLabel('Settings'), findsNothing);
    });
  });

  test('a pre-Wave-3 voice model setting ("base") loads as automatic pack choice', () {
    expect(VoiceSettings.fromJson({'modelId': 'base'}).modelId, '');
    expect(VoiceSettings.fromJson({'modelId': 'small'}).modelId, '');
    expect(VoiceSettings.fromJson({'modelId': 'voice-parakeet-en'}).modelId, 'voice-parakeet-en');
  });

  test('voice events arrive on ImeEvents.voice in order', () async {
    final h = AppHarness();
    final got = <VoiceEventKind>[];
    h.events.voice.listen((e) => got.add(e.kind));
    await h.events.onVoiceEvent(VoiceEventMessage(kind: VoiceEventKind.partial, level: 0, text: 'hel'));
    await h.events.onVoiceEvent(VoiceEventMessage(kind: VoiceEventKind.stopped, level: 0));
    expect(got, [VoiceEventKind.partial, VoiceEventKind.stopped]);
  });
}
