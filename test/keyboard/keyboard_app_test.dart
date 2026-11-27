// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/keyboard/layout/layout_repository.dart';
import 'package:booboard/src/keyboard/view/keyboard_hooks.dart';
import 'package:booboard/src/keyboard/view/keyboard_metrics.dart';
import 'package:booboard/src/keyboard/view/keyboard_view.dart';
import 'package:booboard/src/keyboard/view/popup_layer.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import 'support/app_harness.dart';

void main() {
  late KeyboardLayoutDef qwerty;

  setUpAll(() => qwerty = loadLayoutSync('qwerty'));

  Future<(AppHarness, KeyFinder)> boot(
    WidgetTester tester, {
    BooBoardSettings settings = const BooBoardSettings(),
    EditorInfoMessage? field,
    String text = '',
  }) async {
    final h = AppHarness(settings: settings, text: text);
    await h.pump(tester);
    await h.focus(tester, field);
    return (h, KeyFinder(tester, qwerty));
  }

  Future<void> tap(WidgetTester tester, Offset p) async {
    await tester.tapAt(p);
    await tester.pump(const Duration(milliseconds: 20));
  }

  testWidgets('asks the host for strip + rows + bottom inset, and only when it changes', (tester) async {
    final h = AppHarness();
    await h.pump(tester);
    final calls = verify(() => h.host.setWindowLayout(captureAny())).captured.cast<WindowLayoutMessage>();
    expect(calls, hasLength(1));
    expect(calls.single.mode, WindowMode.docked);
    expect(calls.single.heightDp, 44 + 4 * 56);
    await h.focus(tester);
    await tester.pump();
    verifyNever(() => h.host.setWindowLayout(any()));
  });

  testWidgets('height follows height scale, number row and the bottom inset', (tester) async {
    final h = AppHarness();
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.reset);
    await h.pump(tester);
    var calls = verify(() => h.host.setWindowLayout(captureAny())).captured.cast<WindowLayoutMessage>();
    expect(calls.last.heightDp, 44 + 224 + 24);

    await h.store.update(
      (s) =>
          s.copyWith(typing: s.typing.copyWith(numberRow: true), appearance: s.appearance.copyWith(heightScale: 0.9)),
      sections: ['typing', 'appearance'],
    );
    await tester.pump();
    calls = verify(() => h.host.setWindowLayout(captureAny())).captured.cast<WindowLayoutMessage>();
    expect(calls.last.heightDp, closeTo(44 + 4.8 * 56 * 0.9 + 24, 1e-6));
  });

  test('metrics use the landscape scale in landscape', () {
    final s = const BooBoardSettings().copyWith(appearance: const AppearanceSettings(landscapeHeightScale: 0.7));
    expect(KeyboardMetrics.rowsHeight(s, landscape: true), closeTo(4 * 56 * 0.7, 1e-9));
    expect(KeyboardMetrics.rowsHeight(s, landscape: false), 4 * 56);
    expect(KeyboardMetrics.totalHeight(s, landscape: false, bottomInset: 10), 44 + 224 + 10);
  });

  testWidgets('tapping keys types text', (tester) async {
    final (h, k) = await boot(tester);
    await tap(tester, k.output('h'));
    await tap(tester, k.output('i'));
    expect(h.editor.text, 'hi');
    expect(h.editor.composing, 'hi');
    await tap(tester, k.type(KeyType.space));
    expect(h.editor.text, 'hi ');
    expect(h.editor.composing, isNull);
    await tap(tester, k.type(KeyType.backspace));
    expect(h.editor.text, 'hi');
  });

  testWidgets('shift capitalises one letter', (tester) async {
    final (h, k) = await boot(tester);
    await tap(tester, k.type(KeyType.shift));
    await tap(tester, k.output('a'));
    await tap(tester, k.output('b'));
    expect(h.editor.text, 'Ab');
  });

  testWidgets('auto-capitalises at the start of a sentence field', (tester) async {
    final (h, k) = await boot(
      tester,
      field: editorInfo(
        inputType: AndroidInputType.classText | AndroidInputType.textFlagCapSentences,
        initialCapsMode: AndroidCapsMode.sentences,
      ),
    );
    await tap(tester, k.output('h'));
    await tap(tester, k.output('i'));
    expect(h.editor.text, 'Hi');
  });

  testWidgets('symbols page: ?123, a digit, space returns to letters', (tester) async {
    final (h, k) = await boot(tester);
    await tap(tester, k.type(KeyType.symbols));
    final symbols = KeyFinder(tester, loadLayoutSync('symbols'));
    await tap(tester, symbols.output('7'));
    expect(h.editor.text, '7');
    await tap(tester, symbols.type(KeyType.space));
    expect(h.editor.text, '7 ');
    // Back on letters.
    await tap(tester, k.output('a'));
    expect(h.editor.text, '7 a');
  });

  testWidgets('enter inserts a newline in multi-line fields and runs the action elsewhere', (tester) async {
    final (h, k) = await boot(
      tester,
      field: editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textFlagMultiLine),
    );
    await tap(tester, k.output('a'));
    await tap(tester, k.type(KeyType.enter));
    expect(h.editor.text, 'a\n');
    await h.focus(tester, editorInfo(imeOptions: AndroidImeOptions.actionSearch));
    await tap(tester, k.type(KeyType.enter));
    expect(h.editor.editorActions, [AndroidImeOptions.actionSearch]);
  });

  testWidgets('number fields get the number pad', (tester) async {
    final (h, _) = await boot(tester, field: editorInfo(inputType: AndroidInputType.classNumber));
    final pad = KeyFinder(tester, loadLayoutSync('numpad'));
    await tap(tester, pad.output('7'));
    await tap(tester, pad.output('.'));
    await tap(tester, pad.output('5'));
    expect(h.editor.text, '7.5');
  });

  testWidgets('email fields get @ and .com', (tester) async {
    final (h, _) = await boot(
      tester,
      field: editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationEmailAddress),
    );
    final email = KeyFinder(tester, LayoutVariants.forField(qwerty, PreferredPage.email));
    await tap(tester, email.output('a'));
    await tap(tester, email.output('@'));
    await tap(tester, email.output('b'));
    await tap(tester, email.output('.com'));
    expect(h.editor.text, 'a@b.com');
  });

  testWidgets('long-press opens alternatives; releasing commits the first (the digit hint)', (tester) async {
    final (h, k) = await boot(tester);
    final g = await tester.startGesture(k.output('e'));
    await tester.pump(const Duration(milliseconds: 400));
    await g.up();
    await tester.pump();
    expect(h.editor.text, '3');
  });

  testWidgets('long-press then slide picks another alternative', (tester) async {
    final (h, k) = await boot(tester);
    final key = k.byOutput('e');
    final g = await tester.startGesture(k.at(key));
    await tester.pump(const Duration(milliseconds: 400));
    final layout = AlternativesLayout.compute(
      keyRect: k.viewRect(key),
      count: key.def.popup.length,
      view: Size(AppHarness.window.width, KeyboardMetrics.stripHeight + 224),
    );
    await g.moveTo(layout.cells[2].center);
    await tester.pump();
    await g.up();
    await tester.pump();
    expect(h.editor.text, 'è');
  });

  testWidgets('long-press on a key without alternatives still types it on release', (tester) async {
    final (h, k) = await boot(tester);
    final g = await tester.startGesture(k.output('t'));
    await tester.pump(const Duration(milliseconds: 100));
    await g.up();
    expect(h.editor.text, 't');
  });

  testWidgets('long-press on space opens the input method picker and types nothing', (tester) async {
    final (h, k) = await boot(tester);
    final g = await tester.startGesture(k.type(KeyType.space));
    await tester.pump(const Duration(milliseconds: 400));
    await g.up();
    await tester.pump();
    verify(() => h.host.showInputMethodPicker()).called(1);
    expect(h.editor.text, '');
  });

  testWidgets('holding backspace repeats and accelerates', (tester) async {
    final (h, k) = await boot(tester, text: 'abcdefghijklmnopqrstuvwxyz');
    final g = await tester.startGesture(k.type(KeyType.backspace));
    await tester.pump(const Duration(milliseconds: 100));
    expect(h.editor.text.length, 25, reason: 'one delete on touch-down');
    await tester.pump(const Duration(milliseconds: 350));
    expect(h.editor.text.length, 24, reason: 'first repeat after 400 ms');
    await tester.pump(const Duration(milliseconds: 600));
    expect(h.editor.text.length, lessThan(15));
    await g.up();
    final before = h.editor.text.length;
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.editor.text.length, before, reason: 'no repeat after release');
  });

  testWidgets('a long hold deletes whole words', (tester) async {
    final (h, k) = await boot(tester, text: 'one two three four five six seven eight nine ten eleven twelve ');
    final g = await tester.startGesture(k.type(KeyType.backspace));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await g.up();
    await tester.pump();
    expect(h.editor.text, isNot(contains('twelve')));
    expect(h.editor.text.endsWith(' ') || h.editor.text.isEmpty, isTrue, reason: 'word deletes end on a boundary');
  });

  testWidgets('a second finger commits the first key (rollover)', (tester) async {
    final (h, k) = await boot(tester);
    final g1 = await tester.startGesture(k.output('a'), pointer: 1);
    final g2 = await tester.startGesture(k.output('s'), pointer: 2);
    await tester.pump();
    expect(h.editor.text, 'a', reason: 'first key committed when the second finger landed');
    await g2.up();
    await g1.up();
    await tester.pump();
    expect(h.editor.text, 'as');
  });

  testWidgets('feedback: off by default; haptic on touch-down and sound only when enabled', (tester) async {
    final (h, k) = await boot(tester);
    await tap(tester, k.output('a'));
    verifyNever(() => h.host.performHaptic(any()));
    verifyNever(() => h.host.playKeySound(any()));
    await h.store.update(
      (s) => s.copyWith(feedback: s.feedback.copyWith(haptics: true, sounds: true)),
      sections: ['feedback'],
    );
    await tester.pump();
    await tap(tester, k.output('b'));
    verify(() => h.host.performHaptic(HapticKind.keyTap)).called(1);
    await tap(tester, k.type(KeyType.space));
    verify(() => h.host.playKeySound(KeySoundKind.space)).called(1);
    // The config was pushed at start and again after the change.
    verify(() => h.host.setFeedbackConfig(any())).called(2);
  });

  testWidgets('password fields: toolbar without a chip, secure window, no composing, then restored', (tester) async {
    final (h, k) = await boot(tester);
    verify(() => h.host.setSecureWindow(false)).called(1);
    await h.focus(tester, editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationPassword));
    verify(() => h.host.setSecureWindow(true)).called(1);
    expect(find.text('Private field'), findsNothing, reason: 'no chip: BooBoard is offline everywhere');
    expect(find.bySemanticsLabel('Settings'), findsOneWidget, reason: 'the toolbar shows as usual');
    await tap(tester, k.output('a'));
    await tap(tester, k.output('b'));
    expect(h.editor.text, 'ab');
    expect(h.editor.composing, isNull);
    expect(h.predictor.suggestCalls, 0);
    // Long-press gives no popup: releasing types the key itself.
    final g = await tester.startGesture(k.output('e'));
    await tester.pump(const Duration(milliseconds: 400));
    await g.up();
    await tester.pump();
    expect(h.editor.text, 'abe');
    await h.focus(tester, editorInfo());
    verify(() => h.host.setSecureWindow(false)).called(1);
    expect(find.text('Private field'), findsNothing);
  });

  testWidgets('hide-from-screenshots keeps the window secure in normal fields', (tester) async {
    final h = AppHarness(settings: const BooBoardSettings(privacy: PrivacySettings(hideFromScreenshots: true)));
    await h.pump(tester);
    verify(() => h.host.setSecureWindow(true)).called(1);
    await h.focus(tester, editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationPassword));
    await h.focus(tester, editorInfo());
    verifyNever(() => h.host.setSecureWindow(false));
  });

  testWidgets('suggestion strip: tap applies a suggestion', (tester) async {
    final (h, k) = await boot(tester);
    h.predictor.completions = {
      'hel': ['hello'],
    };
    await tap(tester, k.output('h'));
    await tap(tester, k.output('e'));
    await tap(tester, k.output('l'));
    expect(find.text('hello'), findsOneWidget);
    await tester.tap(find.text('hello'));
    await tester.pump();
    expect(h.editor.text, 'hello ');
  });

  testWidgets('strip shows the typed unknown word in quotes and next words when idle', (tester) async {
    final (h, k) = await boot(tester);
    expect(find.text('the'), findsOneWidget, reason: 'next-word predictions when nothing is composing');
    await tap(tester, k.output('x'));
    await tap(tester, k.output('q'));
    expect(find.text('“xq”'), findsOneWidget);
  });

  testWidgets('toolbar shows when there are no suggestions and wires settings and hooks', (tester) async {
    final h = AppHarness();
    h.predictor.next = const [];
    var emoji = 0;
    await h.pump(tester, hooks: KeyboardHooks(onEmoji: () => emoji++));
    await h.focus(tester);
    final handle = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Emoji'), findsOneWidget);
    expect(find.bySemanticsLabel('Clipboard'), findsOneWidget);
    expect(find.bySemanticsLabel('Themes'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.tap(find.bySemanticsLabel('Emoji'));
    await tester.pump();
    verify(() => h.host.openSettings(null)).called(1);
    expect(emoji, 1);
    handle.dispose();
  });

  testWidgets('incognito shows an indicator', (tester) async {
    final h = AppHarness(settings: const BooBoardSettings(privacy: PrivacySettings(incognito: true)));
    await h.pump(tester);
    await h.focus(tester);
    final handle = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('^Incognito mode on')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('keys have accessibility labels, including shift state', (tester) async {
    final (_, k) = await boot(tester);
    final handle = tester.ensureSemantics();
    await tester.pump();
    Set<String> labels() {
      final out = <String>{};
      void visit(SemanticsNode n) {
        if (n.label.isNotEmpty) out.add(n.label);
        n.visitChildren((c) {
          visit(c);
          return true;
        });
      }

      visit(tester.getSemantics(find.byType(KeyboardKeysArea)));
      return out;
    }

    expect(labels(), containsAll(['Delete', 'Space', 'Shift, off', 'Enter', 'Comma', 'Period', 'q', 'Symbols']));
    await tap(tester, k.type(KeyType.shift));
    await tester.pump();
    expect(labels(), contains('Shift, on'));
    expect(labels(), contains('Q'));
    handle.dispose();
  });

  testWidgets('geometry and languages are pushed to the predictor and the gesture decoder', (tester) async {
    final (h, _) = await boot(tester);
    expect(h.predictor.languages, ['en']);
    final g = h.predictor.geometry!;
    expect(g.keys.length, 26);
    expect(g.size.width, 360);
    expect(h.decoder.lastGeometry, isNotNull);
    expect(h.decoder.lastLanguages, ['en']);
    final prepared = h.decoder.prepareCalls;
    // A number row changes the key positions: pushed again.
    await h.store.update((s) => s.copyWith(typing: s.typing.copyWith(numberRow: true)), sections: ['typing']);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(h.decoder.prepareCalls, prepared + 1);
    expect(h.predictor.geometry!.keys['q']!.top, greaterThan(g.keys['q']!.top - 1));
  });

  group('gesture typing', () {
    Future<TestGesture> swipe(WidgetTester tester, KeyFinder k, List<String> keys) async {
      final g = await tester.startGesture(k.output(keys.first));
      for (final key in keys.skip(1)) {
        await g.moveTo(k.output(key));
        await tester.pump(const Duration(milliseconds: 16));
      }
      return g;
    }

    testWidgets('a swipe is decoded and committed with a trailing space', (tester) async {
      final (h, k) = await boot(tester);
      h.decoder.result = ['hello', 'help'];
      final g = await swipe(tester, k, ['h', 'e', 'l', 'o']);
      await g.up();
      await tester.pump();
      expect(h.decoder.decoded, hasLength(1));
      expect(h.decoder.decoded.single.points.length, greaterThan(3));
      // Key-area coordinates: the first point is the centre of 'h'.
      final first = h.decoder.decoded.single.points.first;
      expect(first.offset, k.byOutput('h').rect.center);
      expect(h.editor.text, 'hello ');
      expect(find.text('help'), findsOneWidget, reason: 'alternatives in the strip');
    });

    testWidgets('a tap (no movement) is a normal key press, not a swipe', (tester) async {
      final (h, k) = await boot(tester);
      h.decoder.result = ['nope'];
      await tap(tester, k.output('h'));
      expect(h.decoder.decoded, isEmpty);
      expect(h.editor.text, 'h');
    });

    testWidgets('live preview is throttled while swiping', (tester) async {
      final (h, k) = await boot(tester);
      h.decoder.previewResult = 'hel';
      final g = await swipe(tester, k, ['h', 'e', 'l', 'k', 'j', 'h', 'g', 'f']);
      await g.up();
      await tester.pump();
      expect(h.decoder.previewCalls, greaterThan(0));
      expect(h.decoder.previewCalls, lessThan(8));
    });

    testWidgets('swipe disabled in settings: sliding types the key under the finger', (tester) async {
      final (h, k) = await boot(tester, settings: const BooBoardSettings(swipe: SwipeSettings(enabled: false)));
      h.decoder.result = ['hello'];
      final g = await swipe(tester, k, ['h', 'e', 'l']);
      await g.up();
      await tester.pump();
      expect(h.decoder.decoded, isEmpty);
      expect(h.editor.text, 'l');
    });

    testWidgets('no swipe in password fields', (tester) async {
      final (h, k) = await boot(
        tester,
        field: editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationPassword),
      );
      h.decoder.result = ['hello'];
      final g = await swipe(tester, k, ['h', 'e', 'l']);
      await g.up();
      await tester.pump();
      expect(h.decoder.decoded, isEmpty);
    });

    testWidgets('a second finger cancels the swipe', (tester) async {
      final (h, k) = await boot(tester);
      h.decoder.result = ['hello'];
      final g = await swipe(tester, k, ['h', 'e', 'l']);
      final g2 = await tester.startGesture(k.output('z'), pointer: 7);
      await g.up();
      await g2.up();
      await tester.pump();
      expect(h.decoder.decoded, isEmpty);
    });
  });

  testWidgets('Wave 2 drag hooks receive space and backspace drags', (tester) async {
    final h = AppHarness();
    final events = <String>[];
    await h.pump(
      tester,
      hooks: KeyboardHooks(
        onSpaceDrag: (dx, {required done}) => events.add('space ${dx.round()} $done'),
        onBackspaceDrag: (dx, {required done}) => events.add('bs ${dx.round()} $done'),
      ),
    );
    await h.focus(tester);
    final k = KeyFinder(tester, qwerty);
    final g = await tester.startGesture(k.type(KeyType.space));
    await g.moveBy(const Offset(40, 0));
    await tester.pump();
    await g.moveBy(const Offset(20, 0));
    await g.up();
    await tester.pump();
    expect(events.first, 'space 40 false');
    expect(events.last, 'space 60 true');
    expect(h.editor.text, '', reason: 'the space bar does not type while the hook owns the drag');
    events.clear();
    final b = await tester.startGesture(k.type(KeyType.backspace));
    await b.moveBy(const Offset(-30, 0));
    await b.up();
    await tester.pump();
    expect(events.first, 'bs -30 false');
    expect(events.last.endsWith('true'), isTrue);
  });
}
