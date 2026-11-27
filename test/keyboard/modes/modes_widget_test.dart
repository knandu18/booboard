// SPDX-License-Identifier: GPL-3.0-or-later
//
// The modes in the real keyboard: the modes bar, one-handed, floating, the height bar, the space-bar
// cursor drag and backspace swipe-to-delete with undo.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/keyboard/modes/modes.dart';
import 'package:booboard/src/keyboard/view/keyboard_view.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../support/app_harness.dart';

final KeyboardLayoutDef qwerty = loadLayoutSync('qwerty');

const BooBoardSettings noPredictions = BooBoardSettings(typing: TypingSettings(nextWordPrediction: false));

/// A booted keyboard with every window layout it sent, in order.
class BootedRun {
  BootedRun(this.h);

  final AppHarness h;
  final List<WindowLayoutMessage> layouts = [];

  WindowLayoutMessage get last => layouts.last;
}

Future<void> tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pump(const Duration(milliseconds: 20));
}

/// Opens the modes bar: long-press the Settings gear, then "One-handed and floating" in the tools menu.
Future<void> openModesBar(WidgetTester tester) async {
  await tester.longPress(find.bySemanticsLabel('Settings'));
  await tester.pump(const Duration(milliseconds: 20));
  await tap(tester, find.bySemanticsLabel('One-handed and floating'));
}

/// Lets the width animation of a one-handed or tablet keyboard finish.
Future<void> settle(WidgetTester tester) => tester.pump(const Duration(milliseconds: 400));

Future<BootedRun> boot(
  WidgetTester tester, {
  BooBoardSettings settings = noPredictions,
  String text = '',
  int Function()? clock,
}) async {
  final h = AppHarness(settings: settings, text: text);
  final run = BootedRun(h);
  when(() => h.host.setWindowLayout(any())).thenAnswer((inv) async {
    run.layouts.add(inv.positionalArguments.first as WindowLayoutMessage);
  });
  await h.pump(tester, features: [createModesFeature(clockMs: clock)]);
  await h.focus(tester);
  return run;
}

Future<void> setModes(WidgetTester tester, BootedRun run, ModeSettings modes) async {
  await run.h.store.update((s) => s.copyWith(modes: modes), sections: ['modes']);
  await tester.pump();
  await settle(tester);
}

void main() {
  group('docked and the modes bar', () {
    testWidgets('with the modes feature the docked keyboard is the same as before: full width, same height', (
      tester,
    ) async {
      final run = await boot(tester);
      expect(run.last.mode, WindowMode.docked);
      expect(run.last.heightDp, 44 + 4 * 56);
      expect(tester.getSize(find.byType(KeyboardKeysArea)).width, AppHarness.window.width);
    });

    testWidgets('the modes bar: one-handed left and right, floating and resize write the right settings', (
      tester,
    ) async {
      final run = await boot(tester);
      final store = run.h.store;

      await openModesBar(tester);
      await tap(tester, find.bySemanticsLabel('One-handed, left'));
      await tester.pump();
      expect(store.value.modes.oneHanded, OneHandedMode.left);

      await openModesBar(tester);
      await tap(tester, find.bySemanticsLabel('One-handed, left'));
      await tester.pump();
      expect(store.value.modes.oneHanded, OneHandedMode.off, reason: 'tapping the selected side turns it off');

      await openModesBar(tester);
      await tap(tester, find.bySemanticsLabel('One-handed, right'));
      await tester.pump();
      expect(store.value.modes.oneHanded, OneHandedMode.right);

      await openModesBar(tester);
      await tap(tester, find.bySemanticsLabel('Floating keyboard'));
      await tester.pump();
      expect(store.value.modes.floating, isTrue);
      expect(store.value.modes.oneHanded, OneHandedMode.off, reason: 'floating and one-handed do not combine');

      await openModesBar(tester);
      await tap(tester, find.bySemanticsLabel('Resize keyboard height'));
      await tester.pump();
      expect(find.text('Done'), findsOneWidget, reason: 'the height bar is open');
      expect(find.bySemanticsLabel('Close keyboard modes'), findsNothing, reason: 'the bar closes after a choice');
    });

    testWidgets('the close button closes the bar without a change', (tester) async {
      final run = await boot(tester);
      await openModesBar(tester);
      expect(find.bySemanticsLabel('Close keyboard modes'), findsOneWidget);
      await tap(tester, find.bySemanticsLabel('Close keyboard modes'));
      await tester.pump();
      expect(run.h.store.value.modes, const ModeSettings());
      expect(find.bySemanticsLabel('Close keyboard modes'), findsNothing);
    });
  });

  group('one-handed', () {
    testWidgets('80% of the width on one side, with a strip of buttons on the other', (tester) async {
      final run = await boot(tester);
      await setModes(tester, run, const ModeSettings(oneHanded: OneHandedMode.left));
      expect(tester.getSize(find.byType(KeyboardKeysArea)).width, closeTo(288, 0.5));
      expect(tester.getTopLeft(find.byType(KeyboardKeysArea)).dx, 0, reason: 'left side');
      expect(run.last.mode, WindowMode.docked);
      expect(run.last.heightDp, 44 + 4 * 56, reason: 'same height as docked');
      expect(find.bySemanticsLabel('Move keyboard to other side'), findsOneWidget);
      expect(find.bySemanticsLabel('Full width keyboard'), findsOneWidget);
    });

    testWidgets('swap moves it to the other side; full width turns one-handed off', (tester) async {
      final run = await boot(tester);
      await setModes(tester, run, const ModeSettings(oneHanded: OneHandedMode.left));

      await tap(tester, find.bySemanticsLabel('Move keyboard to other side'));
      await tester.pump();
      expect(run.h.store.value.modes.oneHanded, OneHandedMode.right);
      await settle(tester);
      expect(tester.getTopLeft(find.byType(KeyboardKeysArea)).dx, closeTo(360 - 288, 0.5), reason: 'right side');

      await tap(tester, find.bySemanticsLabel('Full width keyboard'));
      await tester.pump();
      expect(run.h.store.value.modes.oneHanded, OneHandedMode.off);
      await settle(tester);
      expect(tester.getSize(find.byType(KeyboardKeysArea)).width, AppHarness.window.width);
    });
  });

  group('floating', () {
    const floating = ModeSettings(floating: true, floatingX: 0.5, floatingY: 0.5, floatingWidth: 0.8);

    testWidgets('the window is floating, the card sits at the saved place, and a drag saves the new place', (
      tester,
    ) async {
      final run = await boot(tester);
      await setModes(tester, run, floating);
      expect(run.last.mode, WindowMode.floating);
      expect(run.last.heightDp, closeTo(595, 0.5), reason: '85% of the 700 dp screen');
      expect(run.last.floatingRect!.left, closeTo(36, 0.5));
      expect(run.last.floatingRect!.width, closeTo(288, 0.5));

      // Drag the move bar well to the left: the card snaps to the left edge and the position is saved.
      final g = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Move keyboard')));
      await g.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(run.last.floatingRect!.left, 0, reason: 'clamped and snapped to the left edge while dragging');
      await g.up();
      await tester.pump();
      expect(run.h.store.value.modes.floatingX, 0);
      expect(run.h.store.value.modes.floatingY, closeTo(0.5, 0.01), reason: 'vertical position unchanged');
    });

    testWidgets('the width grip resizes the card and saves the width', (tester) async {
      final run = await boot(tester);
      await setModes(tester, run, const ModeSettings(floating: true, floatingX: 0, floatingWidth: 0.8));
      final g = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Resize keyboard width')));
      await g.moveBy(const Offset(-60, 0));
      await tester.pump();
      expect(run.last.floatingRect!.width, closeTo(228, 0.5));
      await g.up();
      await tester.pump();
      expect(run.h.store.value.modes.floatingWidth, closeTo(228 / 360, 0.01));
    });

    testWidgets('Dock returns to the docked keyboard', (tester) async {
      final run = await boot(tester);
      await setModes(tester, run, const ModeSettings(floating: true));
      await tap(tester, find.text('Dock'));
      await tester.pump();
      expect(run.h.store.value.modes.floating, isFalse);
      expect(run.last.mode, WindowMode.docked);
    });
  });

  group('height bar', () {
    testWidgets('dragging the grip previews the height and writes the row scale on release; Reset and Done', (
      tester,
    ) async {
      final run = await boot(tester);
      await openModesBar(tester);
      await tap(tester, find.bySemanticsLabel('Resize keyboard height'));
      await tester.pump();

      final g = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Drag to change keyboard height')));
      await g.moveBy(const Offset(0, -40));
      await tester.pump();
      // Dragging up makes the keyboard 40 dp taller (268 + 40) and the bar is part of the window.
      expect(run.last.heightDp, closeTo(308 + 48, 0.5));
      await g.up();
      await tester.pump();
      expect(run.h.store.value.appearance.heightScale, closeTo(264 / 224, 0.01));

      await tap(tester, find.text('Reset'));
      await tester.pump();
      expect(run.h.store.value.appearance.heightScale, 1.0);

      await tap(tester, find.text('Done'));
      await tester.pump();
      expect(find.text('Done'), findsNothing);
      expect(run.last.heightDp, 44 + 4 * 56);
    });

    testWidgets('the height bar fits in a narrow floating card', (tester) async {
      final run = await boot(tester);
      await setModes(tester, run, const ModeSettings(floating: true, floatingWidth: 0.6));
      await openModesBar(tester);
      await tap(tester, find.bySemanticsLabel('Resize keyboard height'));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'no overflow at 60% width');
      expect(find.text('Done'), findsOneWidget);
    });
  });

  group('space-bar cursor drag', () {
    testWidgets('a slow drag moves the cursor one character per 12 dp', (tester) async {
      var now = 0;
      final run = await boot(tester, text: 'hello world', clock: () => now);
      final h = run.h;
      expect(h.editor.selectionStart, 11);
      final keys = KeyFinder(tester, qwerty);
      final g = await tester.startGesture(keys.type(KeyType.space));
      now += 100;
      await g.moveBy(const Offset(-12, 0));
      await tester.pump();
      now += 100;
      await g.moveBy(const Offset(-12, 0));
      await tester.pump();
      now += 100;
      await g.moveBy(const Offset(-12, 0));
      await tester.pump();
      await g.up();
      await tester.pump();
      expect(h.editor.text, 'hello world', reason: 'the space bar does not type while it moves the cursor');
      expect(h.editor.selectionStart, 8);
      expect(h.editor.selectionEnd, 8);
    });
  });

  group('backspace swipe-to-delete', () {
    // With swipe-delete on, backspace deletes nothing when it goes down; a tap deletes on release.
    testWidgets('a tap still deletes one character, on release', (tester) async {
      final run = await boot(tester, text: 'one two three');
      final h = run.h;
      final keys = KeyFinder(tester, qwerty);
      final g = await tester.startGesture(keys.type(KeyType.backspace));
      await tester.pump();
      expect(h.editor.text, 'one two three', reason: 'nothing is deleted on touch-down');
      await g.up();
      await tester.pump();
      expect(h.editor.text, 'one two thre');
    });

    testWidgets('dragging left selects whole words, releasing deletes them and undo puts them back', (tester) async {
      final run = await boot(tester, text: 'one two three');
      final h = run.h;
      final keys = KeyFinder(tester, qwerty);
      final g = await tester.startGesture(keys.type(KeyType.backspace));
      await tester.pump();
      expect(h.editor.text, 'one two three');
      await g.moveBy(const Offset(-30, 0));
      await tester.pump();
      expect((h.editor.selectionStart, h.editor.selectionEnd), (8, 13), reason: 'one word: "three"');
      await g.up();
      await tester.pump();
      expect(h.editor.text, 'one two ');
      expect(h.editor.selectionStart, 8);

      await tap(tester, find.text('Undo'));
      await tester.pump();
      expect(h.editor.text, 'one two three');
      expect(h.editor.selectionStart, 13, reason: 'the cursor is back at the end');
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('dragging back to where it started selects nothing and deletes nothing', (tester) async {
      final run = await boot(tester, text: 'one two three');
      final h = run.h;
      final keys = KeyFinder(tester, qwerty);
      final g = await tester.startGesture(keys.type(KeyType.backspace));
      await tester.pump();
      await g.moveBy(const Offset(-30, 0));
      await tester.pump();
      expect(h.editor.selectionStart, 8);
      await g.moveBy(const Offset(30, 0));
      await tester.pump();
      expect((h.editor.selectionStart, h.editor.selectionEnd), (13, 13), reason: 'the selection is restored');
      await g.up();
      await tester.pump();
      expect(h.editor.text, 'one two three');
      expect(find.text('Undo'), findsNothing);
    });
  });
}
