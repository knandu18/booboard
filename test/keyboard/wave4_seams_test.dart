// SPDX-License-Identifier: GPL-3.0-or-later
//
// The Wave 4 seams: the TextComposer routing in InputController, the candidate strip and grid,
// 12-key flick input and custom keys, the zh/ja registry entries and rules, dictionary packs,
// the chinese/japanese settings sections, and the settings app's localisation delegates.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/lang/registry.dart';
import 'package:booboard/src/keyboard/candidates/candidate_grid_panel.dart';
import 'package:booboard/src/keyboard/input/input_controller.dart';
import 'package:booboard/src/keyboard/input/keyboard_page.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/keyboard/view/keyboard_view.dart';
import 'package:booboard/src/keyboard/view/popup_layer.dart';
import 'package:booboard/src/packs/installed_packs.dart';
import 'package:booboard/src/settings/booboard_settings.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fake_editor.dart';
import 'support/app_harness.dart';
import 'support/fakes.dart';

/// A tiny pinyin-like composer: letters build a buffer; "nihao" offers 你好 / 你 (which converts only
/// "ni") / 尼; space commits the first candidate; enter commits the letters; punctuation commits the
/// best candidate and a full-width mark.
class FakePinyin extends TextComposer {
  String _buffer = '';
  final List<String> customKeys = [];
  final ValueNotifier<int> _changes = ValueNotifier(0);
  bool loading = false;
  int resets = 0;

  static const Map<String, List<(String, int)>> _table = {
    'nihao': [('你好', 5), ('你', 2), ('尼', 2)],
    'hao': [('好', 3), ('号', 3)],
    'ni': [('你', 2), ('尼', 2)],
  };

  List<(String, int)> get _cands => _table[_buffer] ?? (_buffer.isEmpty ? const [] : [(_buffer, _buffer.length)]);

  @override
  ComposerState get state => _buffer.isEmpty
      ? ComposerState.empty
      : ComposerState(
          preedit: _buffer,
          reading: _buffer == 'nihao' ? "ni'hao" : _buffer,
          candidates: [for (final (t, n) in _cands) ComposerCandidate(t, consumes: n)],
          highlighted: 0,
          loading: loading,
        );

  @override
  Listenable get changes => _changes;

  void finishLoading() {
    loading = false;
    _changes.value++;
  }

  @override
  ComposerStep onText(String text) {
    if (RegExp('^[a-z]\$').hasMatch(text)) {
      _buffer += text;
      return ComposerStep.consumed;
    }
    final mark = const {',': '，', '.': '。'}[text] ?? text;
    final best = _buffer.isEmpty ? '' : _cands.first.$1;
    _buffer = '';
    return ComposerStep(commit: '$best$mark');
  }

  @override
  ComposerStep onSpace() {
    if (_buffer.isEmpty) return ComposerStep.notHandled;
    return selectCandidate(0);
  }

  @override
  ComposerStep onEnter() {
    if (_buffer.isEmpty) return ComposerStep.notHandled;
    final raw = _buffer;
    _buffer = '';
    return ComposerStep(commit: raw);
  }

  @override
  ComposerStep onBackspace() {
    if (_buffer.isEmpty) return ComposerStep.notHandled;
    _buffer = _buffer.substring(0, _buffer.length - 1);
    return ComposerStep.consumed;
  }

  @override
  ComposerStep onCustomKey(String code) {
    customKeys.add(code);
    return _buffer.isEmpty ? ComposerStep.notHandled : ComposerStep.consumed;
  }

  @override
  ComposerStep selectCandidate(int index) {
    final (text, n) = _cands[index];
    _buffer = _buffer.substring(n);
    return ComposerStep(commit: text);
  }

  @override
  void reset() {
    resets++;
    _buffer = '';
  }
}

InputFieldInfo _field({int variation = 0, int ime = 0}) =>
    InputFieldInfo(inputType: AndroidInputType.classText | variation, imeOptions: ime);

class _Ctl {
  _Ctl({String text = ''}) {
    editor = FakeEditor(text: text);
    controller = InputController(
      input: editor,
      predictor: FakePredictor(),
      gestureDecoder: FakeGestureDecoder(),
      settings: () => const BooBoardSettings(),
      clock: () => now += 200,
    );
    editor.onSelectionChanged = controller.onSelectionChanged;
  }

  late final FakeEditor editor;
  late final InputController controller;
  int now = 1000;
  final composer = FakePinyin();

  Future<void> start([InputFieldInfo? f]) async {
    await controller.startInput(f ?? _field());
    controller.composer.value = composer;
  }

  Future<void> type(String s) async {
    for (final ch in s.split('')) {
      if (ch == ' ') {
        controller.onSpace();
      } else {
        controller.onText(ch);
      }
      await Future<void>.delayed(Duration.zero);
    }
  }
}

class _Probe extends KeyboardFeature {
  KeyboardSession? session;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return const KeyboardHooks();
  }
}

void main() {
  group('registry', () {
    test('zh and ja are known, with composing layouts and CJK rules', () {
      expect(languageInfo('zh').layouts.single.composes, isTrue);
      expect(languageInfo('ja').layouts.map((l) => l.id), ['kana12_ja', 'romaji_ja']);
      expect(languageInfo('ja').isCjk, isTrue);
      for (final id in ['zh', 'ja']) {
        final r = rulesForLanguage(id);
        expect(r.hasCase, isFalse);
        expect(r.addsSpaceAfter('。'), isFalse);
        expect(r.endsSentence('。'), isTrue);
      }
      expect(rulesForLanguage('ja').quotes, ('「', '」'));
    });

    test('a composing layout blends nothing else', () {
      const l = LanguageSettings(enabled: ['zh', 'en'], active: 'zh');
      expect(blendedLanguages(l), ['zh']);
      expect(blendedLanguages(l.copyWith(active: 'en')), ['en'], reason: 'pinyin is never blended into English');
    });

    test('the seed layouts parse; the 12-key layout has flick keys and custom keys', () {
      for (final id in ['pinyin_zh', 'romaji_ja', 'kana12_ja']) {
        expect(loadLayoutSync(id).id, id);
      }
      final kana = loadLayoutSync('kana12_ja');
      final a = kana.keys.firstWhere((k) => k.output == 'あ');
      expect(a.flick, {'left': 'い', 'up': 'う', 'right': 'え', 'down': 'お'});
      final mod = kana.keys.firstWhere((k) => k.code == ComposerKeys.kanaModifier);
      expect(mod.type, KeyType.custom);
      expect(mod.spoken, isNotEmpty);
    });
  });

  group('composer routing', () {
    test('letters compose through the composer; space commits the first candidate', () async {
      final c = _Ctl();
      await c.start();
      await c.type('nihao');
      expect(c.editor.composing, 'nihao');
      final s = c.controller.composerState.value;
      expect(s.reading, "ni'hao");
      expect(s.candidates.map((x) => x.text), ['你好', '你', '尼']);
      expect(c.controller.bar.value.isComposing, isTrue);
      expect(c.controller.bar.value.suggestions, isEmpty, reason: 'the predictor is off');
      await c.type(' ');
      expect(c.editor.text, '你好');
      expect(c.editor.composing, isNull);
      expect(c.controller.composerState.value.isEmpty, isTrue);
    });

    test('a partial pick leaves the rest composing', () async {
      final c = _Ctl();
      await c.start();
      await c.type('nihao');
      c.controller.selectCandidate(1);
      expect(c.editor.debugView, '你<hao>|');
      expect(c.controller.composerState.value.candidates.first.text, '好');
      c.controller.selectCandidate(0);
      expect(c.editor.text, '你好');
    });

    test('punctuation commits with a full-width mark; enter commits the letters', () async {
      final c = _Ctl();
      await c.start();
      await c.type('ni,');
      expect(c.editor.text, '你，');
      await c.type('hao');
      c.controller.onEnter();
      expect(c.editor.text, '你，hao');
    });

    test('backspace edits the buffer, then deletes normally', () async {
      final c = _Ctl(text: 'x');
      await c.start();
      await c.type('ni');
      c.controller.onBackspace();
      expect(c.editor.debugView, 'x<n>|');
      c.controller.onBackspace();
      expect(c.editor.debugView, 'x|');
      c.controller.onBackspace();
      expect(c.editor.text, '');
    });

    test('space with nothing composing types a space', () async {
      final c = _Ctl();
      await c.start();
      await c.type(' ');
      expect(c.editor.text, ' ');
    });

    test('passwords and URL fields bypass the composer', () async {
      final pw = _Ctl();
      await pw.start(_field(variation: AndroidInputType.textVariationPassword));
      await pw.type('ni');
      expect(pw.controller.composerActive, isFalse);
      expect(pw.editor.text, 'ni');
      final url = _Ctl();
      await url.start(_field(variation: AndroidInputType.textVariationUri));
      await url.type('ni');
      expect(url.controller.composerState.value.isEmpty, isTrue);
      expect(url.composer.customKeys, isEmpty);
    });

    test('an outside edit resets the composer and keeps the preedit as typed', () async {
      final c = _Ctl();
      await c.start();
      await c.type('ni');
      final before = c.composer.resets;
      c.controller.resyncAfterExternalEdit();
      expect(c.composer.resets, greaterThan(before));
      expect(c.editor.text, 'ni');
      expect(c.editor.composing, isNull);
      expect(c.controller.composerState.value.isEmpty, isTrue);
    });

    test('cursor moves go to the composer while it holds text', () async {
      final c = _Ctl();
      await c.start();
      await c.type('ni');
      c.controller.moveCursor(-1);
      expect(c.composer.customKeys, [ComposerKeys.cursorLeft]);
      expect(c.editor.composing, 'ni');
      c.controller.onCustomKey(ComposerKeys.kanaModifier);
      expect(c.composer.customKeys.last, ComposerKeys.kanaModifier);
    });

    test('the composer\'s own changes are published', () async {
      final c = _Ctl();
      await c.start();
      c.composer.loading = true;
      await c.type('n');
      expect(c.controller.composerState.value.loading, isTrue);
      c.composer.finishLoading();
      expect(c.controller.composerState.value.loading, isFalse);
    });

    test('clearing the composer drops its buffer', () async {
      final c = _Ctl();
      await c.start();
      await c.type('ni');
      c.controller.composer.value = null;
      expect(c.editor.text, 'ni');
      expect(c.editor.composing, isNull);
      await c.type('h');
      expect(c.controller.composing, 'h', reason: 'back to the normal word path');
    });
  });

  group('candidate strip and grid', () {
    Future<(AppHarness, KeyboardSession, FakePinyin)> boot(WidgetTester tester) async {
      final h = AppHarness();
      final probe = _Probe();
      await h.pump(tester, features: [probe]);
      await h.focus(tester);
      final s = probe.session!;
      final composer = FakePinyin();
      s.input.composer.value = composer;
      for (final ch in 'nihao'.split('')) {
        s.input.onText(ch);
      }
      await tester.pump();
      return (h, s, composer);
    }

    testWidgets('the strip shows the candidates; a tap commits', (tester) async {
      final (h, _, _) = await boot(tester);
      expect(find.text('你好'), findsOneWidget);
      expect(find.text("ni'hao"), findsOneWidget);
      await tester.tap(find.text('尼'));
      await tester.pump();
      expect(h.editor.debugView, '尼<hao>|');
    });

    testWidgets('the grid opens over the keys and closes after a pick', (tester) async {
      final (h, s, _) = await boot(tester);
      await tester.tap(find.bySemanticsLabel('Show all candidates'));
      await tester.pump();
      expect(s.panel.value?.id, CandidateGridPanel.panelId);
      expect(find.text('你好'), findsNWidgets(2), reason: 'strip and grid');
      await tester.tap(find.text('你好').last);
      await tester.pump();
      expect(h.editor.text, '你好');
      expect(s.panel.value, isNull);
    });
  });

  group('flick input', () {
    const ja = BooBoardSettings(
      languages: LanguageSettings(enabled: ['ja'], active: 'ja'),
    );

    Future<(AppHarness, KeyFinder, KeyboardSession)> boot(WidgetTester tester) async {
      final h = AppHarness(settings: ja);
      final probe = _Probe();
      await h.pump(tester, features: [probe]);
      await h.focus(tester);
      final s = probe.session!;
      final layout = s.layoutFor(KeyboardPage.letters, InputFieldInfo.plainText, h.store.value)!;
      expect(layout.id, startsWith('kana12_ja'));
      return (h, KeyFinder(tester, layout), s);
    }

    testWidgets('a tap types the centre; a flick types its direction', (tester) async {
      final (h, keys, s) = await boot(tester);
      final composer = FakePinyin();
      s.input.composer.value = composer;
      final a = keys.byOutput('あ');
      await tester.tapAt(keys.at(a));
      await tester.pump();
      final g = await tester.startGesture(keys.at(a));
      await g.moveBy(Offset(-a.rect.width * 0.6, 0));
      await tester.pump();
      final popup = tester.widget<KeyboardKeysArea>(find.byType(KeyboardKeysArea)).viewController.popup;
      expect(popup.value, isA<FlickGuideState>());
      expect((popup.value! as FlickGuideState).selected, FlickDirection.left);
      await g.up();
      await tester.pump();
      final g2 = await tester.startGesture(keys.at(a));
      await g2.moveBy(Offset(0, a.rect.height * 0.6));
      await g2.up();
      await tester.pump();
      // FakePinyin commits non-ASCII keys at once.
      expect(h.editor.text, 'あいお');
    });

    testWidgets('a custom key reaches the composer', (tester) async {
      final (_, keys, s) = await boot(tester);
      final composer = FakePinyin();
      s.input.composer.value = composer;
      await tester.tapAt(keys.at(keys.laid.keys.firstWhere((k) => k.def.code == ComposerKeys.kanaModifier)));
      await tester.pump();
      expect(composer.customKeys, [ComposerKeys.kanaModifier]);
    });

    test('direction thresholds', () {
      expect(flickDirectionFor(const Offset(5, 5), 40), FlickDirection.center);
      expect(flickDirectionFor(const Offset(-20, 3), 40), FlickDirection.left);
      expect(flickDirectionFor(const Offset(3, -20), 40), FlickDirection.up);
      expect(flickDirectionFor(const Offset(20, 25), 40), FlickDirection.down);
    });
  });

  group('dictionary packs', () {
    test('InstalledPacks finds dictionary packs and their folders', () async {
      final platform = MockPlatformHost();
      final pack = PackInfoMessage(
        id: 'dict-zh-rime',
        kind: PackKind.dictionary,
        name: 'Chinese dictionary',
        version: 2,
        languages: ['zh'],
        sizeBytes: 10,
        engine: 'rime-ice',
        license: 'GPL-3.0',
      );
      final voice = PackInfoMessage(
        id: 'voice-test',
        kind: PackKind.voice,
        name: 'Voice',
        version: 1,
        languages: ['zh', 'en'],
        sizeBytes: 10,
        engine: 'sherpa-onnx-nemo-transducer',
        license: 'CC-BY-4.0',
      );
      when(() => platform.listPacks()).thenAnswer((_) async => [voice, pack]);
      when(() => platform.getPackDirectory('dict-zh-rime')).thenAnswer((_) async => Directory.systemTemp.path);
      final packs = InstalledPacks(platform);
      expect((await packs.dictionariesFor('zh')).map((p) => p.id), ['dict-zh-rime']);
      expect(await packs.dictionariesFor('ja'), isEmpty);
      final opened = await packs.open('zh', engine: 'rime-ice');
      expect(opened?.$1.id, 'dict-zh-rime');
      expect(opened?.$2.path, Directory.systemTemp.path);
      expect(await packs.open('zh', engine: 'mozc'), isNull);
    });
  });

  group('settings and l10n', () {
    test('the chinese and japanese sections round-trip', () {
      const s = BooBoardSettings(
        chinese: ChineseSettings(traditional: true),
        japanese: JapaneseSettings(flickOnly: true),
      );
      final back = BooBoardSettings.fromJson(s.toJson());
      expect(back.chinese.traditional, isTrue);
      expect(back.chinese.fuzzyPinyin, isTrue);
      expect(back.japanese.flickOnly, isTrue);
      expect(SettingsSection.all, containsAll([SettingsSection.chinese, SettingsSection.japanese]));
    });

    test('the delegates include the app strings', () {
      expect(booboardLocalizationsDelegates.first, AppLocalizations.delegate);
      expect(booboardSupportedLocales, contains(const Locale('en')));
    });
  });
}
