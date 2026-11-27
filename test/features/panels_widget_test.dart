// SPDX-License-Identifier: GPL-3.0-or-later
//
// The emoji, clipboard and editing panels inside the real keyboard view, with the fake editor and host.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/features/emoji/emoji_repository.dart';
import 'package:booboard/src/features/features.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../keyboard/support/app_harness.dart';

/// Captures the session so tests can reach the input controller and the strip chips.
class _Probe extends KeyboardFeature {
  KeyboardSession? session;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return const KeyboardHooks();
  }
}

/// Settings that keep the strip showing the toolbar (no next-word predictions).
const BooBoardSettings _quiet = BooBoardSettings(typing: TypingSettings(nextWordPrediction: false));

Future<(AppHarness, _Probe, KeyFinder)> boot(
  WidgetTester tester, {
  BooBoardSettings settings = _quiet,
  EditorInfoMessage? field,
  KeyboardLayoutDef? layout,
}) async {
  final h = AppHarness(settings: settings);
  final probe = _Probe();
  final panels = createPanelsFeature(emojiRepository: EmojiRepository.fromDirectory('assets/emoji'));
  await h.pump(tester, features: [probe, panels]);
  await h.focus(tester, field);
  when(() => h.platform.hasGlyphs(any()))
      .thenAnswer((inv) async => List.filled((inv.positionalArguments.first as List<String>).length, true));
  return (h, probe, KeyFinder(tester, layout ?? _qwerty));
}

late KeyboardLayoutDef _qwerty;

/// Lets the emoji index and the panels' async loads finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Scrolls the emoji tab bar until the tab [label] is built and on screen (the tabs are a lazy horizontal list).
Future<void> revealTab(WidgetTester tester, String label) async {
  final bar = find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal).first;
  bool onScreen() {
    final tab = find.bySemanticsLabel(label);
    return tab.evaluate().isNotEmpty && tester.getRect(tab).center.dx < 330;
  }

  for (var i = 0; i < 40 && !onScreen(); i++) {
    await tester.drag(bar, const Offset(-40, 0));
    await tester.pump();
  }
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 20));
}

/// Opens the text editing panel: long-press the Settings gear, then "Text editing" in the tools menu.
Future<void> openTextEditing(WidgetTester tester) async {
  await tester.longPress(find.bySemanticsLabel('Settings'));
  await tester.pump(const Duration(milliseconds: 20));
  await tap(tester, find.bySemanticsLabel('Text editing'));
}

void main() {
  setUpAll(() {
    _qwerty = loadLayoutSync('qwerty');
  });

  group('emoji panel', () {
    testWidgets('opens from the toolbar, inserts a tapped emoji and keeps the panel open', (tester) async {
      final (h, _, _) = await boot(tester);
      await tap(tester, find.bySemanticsLabel('Emoji'));
      await settle(tester);
      await tap(tester, find.bySemanticsLabel('Smileys and people'));
      await settle(tester);
      await tap(tester, find.bySemanticsLabel('grinning face'));
      expect(h.editor.text, '😀');
      expect(find.bySemanticsLabel('grinning face'), findsOneWidget, reason: 'the panel stays open');
    });

    testWidgets('long press offers skin tones, and the choice is remembered for the emoji', (tester) async {
      final (h, _, _) = await boot(tester);
      await tap(tester, find.bySemanticsLabel('Emoji'));
      await settle(tester);
      await tap(tester, find.bySemanticsLabel('Smileys and people'));
      await settle(tester);
      // The grid builds cells lazily, so scroll in small steps until the cell is built.
      for (var i = 0; i < 400 && find.bySemanticsLabel('waving hand').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(GridView), const Offset(0, -120));
        await tester.pump();
      }
      await tester.ensureVisible(find.bySemanticsLabel('waving hand'));
      await tester.pump();
      await tester.longPress(find.bySemanticsLabel('waving hand'));
      await settle(tester);
      await tap(tester, find.bySemanticsLabel('waving hand: light skin tone'));
      expect(h.editor.text, '👋🏻');
      await settle(tester);
      expect(
        find.bySemanticsLabel('waving hand: light skin tone'),
        findsOneWidget,
        reason: 'the grid now shows the chosen tone',
      );
    });

    testWidgets('search reads the keyboard keys and inserts a result; enter goes back', (tester) async {
      final (h, probe, _) = await boot(tester);
      await tap(tester, find.bySemanticsLabel('Emoji'));
      await settle(tester);
      await tap(tester, find.bySemanticsLabel('Search emoji'));
      await settle(tester);
      final redirect = probe.session!.input.redirect.value!;
      redirect
        ..onText('pi')
        ..onText('zza');
      await settle(tester);
      expect(find.bySemanticsLabel('pizza'), findsWidgets);
      await tap(tester, find.bySemanticsLabel('pizza').last);
      expect(h.editor.text, '🍕');
      expect(find.bySemanticsLabel('pizza'), findsWidgets, reason: 'tapping a result keeps the search open');
      redirect.onEnter();
      await settle(tester);
      expect(find.bySemanticsLabel('Smileys and people'), findsOneWidget, reason: 'enter returns to the emoji panel');
    });

    testWidgets('an exact keyword in the typed word suggests one emoji in the strip', (tester) async {
      final (_, probe, keys) = await boot(tester, settings: const BooBoardSettings());
      for (final c in ['p', 'i', 'z', 'z', 'a']) {
        await tester.tapAt(keys.output(c));
        await tester.pump(const Duration(milliseconds: 20));
        await settle(tester);
      }
      final suggestions = probe.session!.input.bar.value.suggestions;
      expect(suggestions.any((s) => s.kind == SuggestionKind.emoji && s.text == '🍕'), isTrue);
    });
  });

  group('layout', () {
    testWidgets('the panels lay out without overflow at font scale 1.3', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (h, _, _) = await boot(
        tester,
        settings: const BooBoardSettings(
          typing: TypingSettings(nextWordPrediction: false),
          clipboard: ClipboardSettings(recentChip: false),
        ),
      );
      await h.events.onClipboardChanged(ClipMessage(text: 'long ' * 60, timestampMillis: 5, isSensitive: false));
      await settle(tester);
      await tap(tester, find.bySemanticsLabel('Emoji'));
      await settle(tester);
      await tap(tester, find.bySemanticsLabel('Smileys and people'));
      await revealTab(tester, 'Kaomoji');
      await tap(tester, find.bySemanticsLabel('Kaomoji'));
      await settle(tester);
      await revealTab(tester, 'Maths, arrows, currency and Greek letters');
      await tap(tester, find.bySemanticsLabel('Maths, arrows, currency and Greek letters'));
      await settle(tester);
      await tap(tester, find.bySemanticsLabel('Back to letters'));
      await tap(tester, find.bySemanticsLabel('Clipboard'));
      await settle(tester);
      expect(find.textContaining('long long'), findsOneWidget);
      await tap(tester, find.bySemanticsLabel('Back to keyboard'));
      await openTextEditing(tester);
      await settle(tester);
      expect(find.bySemanticsLabel('Select all'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('clipboard', () {
    testWidgets('a copy shows a recent-copy chip that pastes the text', (tester) async {
      final (h, _, _) = await boot(tester);
      await h.events.onClipboardChanged(ClipMessage(text: 'hello world', timestampMillis: 1, isSensitive: false));
      await tester.pump();
      expect(find.text('Paste "hello world"'), findsOneWidget);
      await tap(tester, find.text('Paste "hello world"'));
      expect(h.editor.text, 'hello world');
    });

    testWidgets('a sensitive copy shows only a masked chip, and tapping reads the clipboard again', (tester) async {
      final (h, _, _) = await boot(tester);
      when(() => h.host.getPrimaryClip())
          .thenAnswer((_) async => ClipMessage(text: 'hunter2', timestampMillis: 2, isSensitive: true));
      await h.events.onClipboardChanged(ClipMessage(text: 'hunter2', timestampMillis: 2, isSensitive: true));
      await tester.pump();
      expect(find.text('Paste ••••'), findsOneWidget);
      expect(find.text('Paste "hunter2"'), findsNothing);
      await tap(tester, find.text('Paste ••••'));
      await settle(tester);
      expect(h.editor.text, 'hunter2');
    });

    testWidgets('history keeps the copy; the panel pastes it and closes', (tester) async {
      // No recent-copy chip here: a chip replaces the toolbar, and the Clipboard button is what we tap.
      final (h, _, _) = await boot(
        tester,
        settings: const BooBoardSettings(
          typing: TypingSettings(nextWordPrediction: false),
          clipboard: ClipboardSettings(recentChip: false),
        ),
      );
      await h.events.onClipboardChanged(ClipMessage(text: 'remember me', timestampMillis: 3, isSensitive: false));
      await settle(tester);
      await tap(tester, find.bySemanticsLabel('Clipboard'));
      await settle(tester);
      expect(find.text('remember me'), findsOneWidget);
      await tap(tester, find.text('remember me'));
      expect(h.editor.text, 'remember me');
      expect(find.bySemanticsLabel('Back to keyboard'), findsNothing, reason: 'pasting closes the panel');
    });

    testWidgets('a sensitive copy is never kept in the history', (tester) async {
      final (h, _, _) = await boot(
        tester,
        settings: const BooBoardSettings(
          typing: TypingSettings(nextWordPrediction: false),
          clipboard: ClipboardSettings(recentChip: false),
        ),
      );
      await h.events.onClipboardChanged(ClipMessage(text: 'hunter2', timestampMillis: 2, isSensitive: true));
      await settle(tester);
      await tap(tester, find.bySemanticsLabel('Clipboard'));
      await settle(tester);
      expect(find.text('hunter2'), findsNothing);
      expect(find.textContaining('Text you copy shows up here'), findsOneWidget);
    });

    testWidgets('incognito keeps nothing, and shows no chip', (tester) async {
      final (h, _, _) = await boot(
        tester,
        settings: const BooBoardSettings(
          privacy: PrivacySettings(incognito: true),
          typing: TypingSettings(nextWordPrediction: false),
        ),
      );
      await h.events.onClipboardChanged(ClipMessage(text: 'private', timestampMillis: 4, isSensitive: false));
      await settle(tester);
      expect(find.text('Paste "private"'), findsNothing);
      await tap(tester, find.bySemanticsLabel('Clipboard'));
      await settle(tester);
      expect(find.text('private'), findsNothing);
    });
  });

  group('editing panel', () {
    testWidgets('select all, arrows and undo send the editor the right actions', (tester) async {
      final (h, _, _) = await boot(tester);
      await h.editor.commitText('hello');
      await openTextEditing(tester);
      await settle(tester);
      await tap(tester, find.bySemanticsLabel('Select all'));
      expect(h.editor.contextActions, contains(ContextMenuAction.selectAll));
      await tap(tester, find.bySemanticsLabel('Move right'));
      expect(h.editor.log, contains('key(${AndroidKeyCode.dpadRight})'));
      await tap(tester, find.bySemanticsLabel('Undo'));
      expect(h.editor.log, contains('key(${AndroidKeyCode.z})'));
    });

    testWidgets('selecting text shows Cut, Copy and Select all chips, and they go when the selection collapses', (
      tester,
    ) async {
      final (h, _, _) = await boot(tester);
      await h.editor.commitText('hello world');
      await h.editor.setSelection(0, 5);
      await settle(tester);
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Select all'), findsOneWidget);
      await tap(tester, find.text('Cut'));
      expect(h.editor.contextActions, contains(ContextMenuAction.cut));
      await h.editor.setSelection(2, 2);
      await settle(tester);
      expect(find.text('Cut'), findsNothing);
    });
  });
}
