// SPDX-License-Identifier: GPL-3.0-or-later
//
// The Wave 2 seams: panels, key redirect, strip chips, suggestion decorators,
// insertText, frames, feature hooks, seen apps and data reloads.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/data_sections.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/keyboard/view/keyboard_view.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import 'support/app_harness.dart';

/// Captures the session and optionally provides hooks and a frame.
class _ProbeFeature extends KeyboardFeature {
  _ProbeFeature({this.hooks = const KeyboardHooks(), this.probeFrame});

  final KeyboardHooks hooks;
  final KeyboardFrame? probeFrame;
  KeyboardSession? session;
  bool detached = false;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return hooks;
  }

  @override
  KeyboardFrame? get frame => probeFrame;

  @override
  void detach() => detached = true;
}

class _Panel extends KeyboardPanel {
  _Panel(this.id, this.placement, {this.keyRedirect});

  @override
  final String id;
  @override
  final PanelPlacement placement;
  @override
  final KeyRedirect? keyRedirect;
  int closed = 0;
  Size? lastSize;

  @override
  Widget build(BuildContext context, PanelContext panel) {
    lastSize = panel.size;
    return Text('panel:$id', textDirection: TextDirection.ltr);
  }

  @override
  void onClosed() => closed++;
}

class _Redirect implements KeyRedirect {
  final List<String> log = [];

  @override
  void onText(String text) => log.add(text);
  @override
  void onSpace() => log.add('<space>');
  @override
  void onBackspace() => log.add('<bksp>');
  @override
  void onEnter() => log.add('<enter>');
}

class _HalfWidthFrame implements KeyboardFrame {
  @override
  FrameResult build(BuildContext context, FrameInfo info, {required Widget keyboard, required Widget background}) =>
      FrameResult(
        layout: WindowLayoutMessage(mode: WindowMode.docked, heightDp: info.contentHeight + info.bottomInset + 10),
        child: Stack(
          children: [
            Positioned.fill(child: background),
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: info.screenSize.width / 2, height: info.contentHeight, child: keyboard),
            ),
          ],
        ),
      );
}

void main() {
  late KeyboardLayoutDef qwerty;

  setUpAll(() => qwerty = loadLayoutSync('qwerty'));

  Future<(AppHarness, _ProbeFeature, KeyFinder)> boot(
    WidgetTester tester, {
    BooBoardSettings settings = const BooBoardSettings(),
    KeyboardHooks hooks = const KeyboardHooks(),
    KeyboardFrame? frame,
    EditorInfoMessage? field,
  }) async {
    final h = AppHarness(settings: settings);
    final probe = _ProbeFeature(hooks: hooks, probeFrame: frame);
    await h.pump(tester, features: [probe]);
    await h.focus(tester, field);
    return (h, probe, KeyFinder(tester, qwerty));
  }

  Future<void> tap(WidgetTester tester, Offset p) async {
    await tester.tapAt(p);
    await tester.pump(const Duration(milliseconds: 20));
  }

  group('panels', () {
    testWidgets('a full panel replaces strip and keys at the same height, and closes', (tester) async {
      final (h, probe, _) = await boot(tester);
      final s = probe.session!;
      final p = _Panel('emoji', PanelPlacement.full);
      s.openPanel(p);
      await tester.pump();
      expect(find.text('panel:emoji'), findsOneWidget);
      expect(find.byType(KeyboardKeysArea), findsNothing);
      expect(p.lastSize!.height, KeyboardMetrics.stripHeight + 4 * 56);
      s.closePanel();
      await tester.pump();
      expect(find.text('panel:emoji'), findsNothing);
      expect(find.byType(KeyboardKeysArea), findsOneWidget);
      expect(p.closed, 1);
      // Opening a panel never changes the window height.
      final heights = verify(() => h.host.setWindowLayout(captureAny())).captured.cast<WindowLayoutMessage>();
      expect(heights.map((l) => l.heightDp).toSet(), hasLength(1));
    });

    testWidgets('a keys panel keeps the strip; a new field closes it', (tester) async {
      final (h, probe, _) = await boot(tester);
      final s = probe.session!;
      final p = _Panel('clipboard', PanelPlacement.keys);
      s.openPanel(p);
      await tester.pump();
      expect(find.text('panel:clipboard'), findsOneWidget);
      expect(p.lastSize!.height, 4 * 56);
      await h.focus(tester, editorInfo(packageName: 'com.example.other'));
      expect(s.panel.value, isNull);
      expect(p.closed, 1);
    });

    testWidgets('panels open in password fields too (2026-11-26)', (tester) async {
      final (_, probe, _) = await boot(
        tester,
        field: editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationPassword),
      );
      probe.session!.openPanel(_Panel('emoji', PanelPlacement.full));
      await tester.pump();
      expect(find.text('panel:emoji'), findsOneWidget);
    });

    testWidgets('a strip panel gets the typed keys; swipe and the editor are untouched', (tester) async {
      final (h, probe, keys) = await boot(tester);
      final s = probe.session!;
      final redirect = _Redirect();
      s.openPanel(_Panel('emoji_search', PanelPlacement.strip, keyRedirect: redirect));
      await tester.pump();
      expect(find.text('panel:emoji_search'), findsOneWidget);
      await tap(tester, keys.output('c'));
      await tap(tester, keys.output('a'));
      await tap(tester, keys.type(KeyType.space));
      await tap(tester, keys.type(KeyType.backspace));
      await tap(tester, keys.type(KeyType.enter));
      expect(redirect.log, ['c', 'a', '<space>', '<bksp>', '<enter>']);
      expect(h.editor.text, isEmpty);
      s.closePanel();
      await tester.pump();
      expect(s.input.redirect.value, isNull);
      await tap(tester, keys.output('c'));
      expect(h.editor.text, 'c');
    });
  });

  group('strip chips', () {
    testWidgets('show instead of the toolbar, replace by id, expire, and hide in password fields', (tester) async {
      var taps = 0;
      final (h, probe, _) = await boot(tester);
      final s = probe.session!;
      s.showChip(StripChip(id: 'clip', label: 'Paste â€œhelloâ€', onTap: () => taps++));
      await tester.pump();
      expect(find.text('Paste â€œhelloâ€'), findsOneWidget);
      s.showChip(
        StripChip(id: 'clip', label: 'Paste â€œbyeâ€', onTap: () => taps++, expiresAfter: const Duration(seconds: 60)),
      );
      await tester.pump();
      expect(find.text('Paste â€œhelloâ€'), findsNothing);
      await tester.tap(find.text('Paste â€œbyeâ€'));
      expect(taps, 1);
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('Paste â€œbyeâ€'), findsNothing);

      s.showChip(StripChip(id: 'x', label: 'Chip', onTap: () {}));
      await h.focus(tester, editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationPassword));
      expect(find.text('Chip'), findsNothing);
    });
  });

  group('typing seams', () {
    testWidgets('insertText keeps the composing word and adds the text', (tester) async {
      final (h, probe, keys) = await boot(tester);
      await tap(tester, keys.output('h'));
      await tap(tester, keys.output('i'));
      probe.session!.input.insertText('ðŸ˜€');
      await tester.pump();
      expect(h.editor.text, 'hiðŸ˜€');
      expect(probe.session!.input.composing, isEmpty);
    });

    testWidgets('decorators add emoji; picking one keeps the word and is not learned', (tester) async {
      final (h, probe, keys) = await boot(tester);
      final input = probe.session!.input;
      input.decorators.add(
        (base, q) => q.composing == 'hi' ? [...base, const Suggestion('ðŸ‘‹', kind: SuggestionKind.emoji)] : base,
      );
      await tap(tester, keys.output('h'));
      await tap(tester, keys.output('i'));
      final emoji = input.bar.value.suggestions.where((s) => s.kind == SuggestionKind.emoji).toList();
      expect(emoji.map((s) => s.text), ['ðŸ‘‹']);
      input.onSuggestionPicked(emoji.single);
      await tester.pump();
      expect(h.editor.text, 'hi ðŸ‘‹ ');
      expect(h.predictor.committed.where((w) => w.contains('ðŸ‘‹')), isEmpty);
    });

    testWidgets('a throwing decorator does not break suggestions', (tester) async {
      final (_, probe, keys) = await boot(tester);
      final input = probe.session!.input;
      input.decorators.add((base, q) => throw StateError('boom'));
      await tap(tester, keys.output('h'));
      expect(input.bar.value.isComposing, isTrue);
    });
  });

  group('features and frames', () {
    testWidgets('hooks from features reach the toolbar; theme defaults to the settings route', (tester) async {
      var emoji = 0;
      final (h, _, _) = await boot(
        tester,
        hooks: KeyboardHooks(onEmoji: () => emoji++),
        settings: const BooBoardSettings(typing: TypingSettings(nextWordPrediction: false)),
      );
      await tester.tap(find.bySemanticsLabel('Emoji'));
      expect(emoji, 1);
      await tester.tap(find.bySemanticsLabel('Themes'));
      verify(() => h.host.openSettings('themes')).called(1);
    });

    const noPredictions = BooBoardSettings(typing: TypingSettings(nextWordPrediction: false));

    testWidgets('the toolbar has no Text editing, modes or Images buttons without a feature', (tester) async {
      await boot(tester, settings: noPredictions);
      expect(find.bySemanticsLabel('Emoji'), findsOneWidget);
      expect(find.bySemanticsLabel('Text editing'), findsNothing);
      expect(find.bySemanticsLabel('One-handed and floating'), findsNothing);
      expect(find.bySemanticsLabel('Create images'), findsNothing);
    });

    testWidgets('long-pressing the Settings gear shows the tools menu; its entries call the hooks', (tester) async {
      var editing = 0;
      var modes = 0;
      final (h, _, _) = await boot(
        tester,
        settings: noPredictions,
        hooks: KeyboardHooks(onEditing: () => editing++, onModes: () => modes++),
      );
      expect(find.bySemanticsLabel('Text editing'), findsNothing, reason: 'not in the toolbar any more');
      await tester.longPress(find.bySemanticsLabel('Settings'));
      await tester.pump();
      expect(find.bySemanticsLabel('BooBoard settings'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Text editing'));
      await tester.pump();
      await tester.longPress(find.bySemanticsLabel('Settings'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('One-handed and floating'));
      await tester.pump();
      expect((editing, modes), (1, 1));
      await tester.longPress(find.bySemanticsLabel('Settings'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('BooBoard settings'));
      await tester.pump();
      verify(() => h.host.openSettings(any())).called(1);
    });

    testWidgets('the Images button appears when a feature provides it', (tester) async {
      var images = 0;
      await boot(
        tester,
        settings: noPredictions,
        hooks: KeyboardHooks(onImages: () => images++),
      );
      await tester.tap(find.bySemanticsLabel('Create images'));
      expect(images, 1);
    });

    testWidgets('a frame decides the window layout and wraps the keyboard', (tester) async {
      final (h, _, _) = await boot(tester, frame: _HalfWidthFrame());
      final calls = verify(() => h.host.setWindowLayout(captureAny())).captured.cast<WindowLayoutMessage>();
      expect(calls.last.heightDp, KeyboardMetrics.stripHeight + 4 * 56 + 10);
      expect(tester.getSize(find.byType(KeyboardKeysArea)).width, AppHarness.window.width / 2);
    });

    testWidgets('the navigation bar gets the keyboard background', (tester) async {
      final (h, _, _) = await boot(tester);
      verify(() => h.host.setNavigationBarStyle(any())).called(1);
    });

    testWidgets('features are detached with the keyboard', (tester) async {
      final (_, probe, _) = await boot(tester);
      await tester.pumpWidget(const SizedBox());
      expect(probe.detached, isTrue);
    });

    test('merge: the first non-null hook wins', () {
      void a() {}
      void b() {}
      final m = KeyboardHooks.merge([KeyboardHooks(onEmoji: a), KeyboardHooks(onEmoji: b, onClipboard: b)]);
      expect(m.onEmoji, same(a));
      expect(m.onClipboard, same(b));
    });
  });

  group('data', () {
    testWidgets('records apps with their label once, never BooBoard itself or while incognito', (tester) async {
      final (h, probe, _) = await boot(tester);
      when(() => h.host.getAppLabel('com.bank')).thenAnswer((_) async => 'Bank');
      await h.focus(tester, editorInfo(packageName: 'com.bank'));
      await h.focus(tester, editorInfo(packageName: 'app.booboard.keyboard'));
      await h.focus(tester, editorInfo(packageName: 'com.bank'));
      await h.store.update((s) => s.copyWith(privacy: s.privacy.copyWith(incognito: true)), sections: ['privacy']);
      await h.focus(tester, editorInfo(packageName: 'com.secret'));
      final apps = await probe.session!.seenApps.list();
      expect(apps.map((a) => (a.packageName, a.label)), [('com.bank', 'Bank')]);
      verify(() => h.host.getAppLabel('com.bank')).called(1);
    });

    testWidgets('a learned-data change from the settings app reloads the predictor', (tester) async {
      final (h, _, _) = await boot(tester);
      await h.events.onSettingsChanged([DataSections.learned]);
      await tester.pump();
      expect(h.predictor.reloads, 1);
      await h.events.onSettingsChanged(['typing']);
      await tester.pump();
      expect(h.predictor.reloads, 1);
      await h.events.onSettingsChanged([DataSections.all]);
      await tester.pump();
      expect(h.predictor.reloads, 2);
    });
  });

  test('DataSections.affects', () {
    expect(DataSections.affects(['data.learned'], DataSections.learned), isTrue);
    expect(DataSections.affects(['data.all'], DataSections.clipboard), isTrue);
    expect(DataSections.affects(['typing'], DataSections.learned), isFalse);
  });
}
