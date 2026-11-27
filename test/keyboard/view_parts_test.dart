// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/keyboard/input/input_controller.dart';
import 'package:booboard/src/keyboard/input/keyboard_page.dart';
import 'package:booboard/src/keyboard/layout/layout_engine.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/keyboard/view/key_press_animator.dart';
import 'package:booboard/src/keyboard/view/key_visuals.dart';
import 'package:booboard/src/keyboard/view/keys_painter.dart';
import 'package:booboard/src/keyboard/view/popup_layer.dart';
import 'package:booboard/src/keyboard/view/suggestion_strip.dart';
import 'package:booboard/src/settings/booboard_settings.dart';
import 'package:booboard/src/theme/keyboard_theme_data.dart';

import 'support/app_harness.dart';

void main() {
  late KeyboardLayoutDef qwerty;
  setUpAll(() => qwerty = loadLayoutSync('qwerty'));

  group('AlternativesLayout', () {
    const view = Size(360, 268);

    Rect keyAt(double cx, double top) => Rect.fromCenter(center: Offset(cx, top + 25), width: 30, height: 50);

    test('stays inside the view for keys at the left, middle and right edges and the top row', () {
      for (final cx in [20.0, 180.0, 340.0]) {
        for (final top in [44.0, 100.0, 210.0]) {
          for (final count in [2, 8, 12]) {
            final l = AlternativesLayout.compute(keyRect: keyAt(cx, top), count: count, view: view);
            expect(l.cells.length, count);
            expect(l.bounds.left, greaterThanOrEqualTo(0));
            expect(l.bounds.right, lessThanOrEqualTo(view.width));
            expect(
              l.bounds.top,
              greaterThanOrEqualTo(0),
              reason: 'popups may overlap the strip but not leave the view',
            );
            for (final c in l.cells) {
              expect(l.bounds.inflate(0.001).contains(c.center), isTrue);
            }
          }
        }
      }
    });

    test('the first item sits over the key, and mirrors near the right edge', () {
      final mid = AlternativesLayout.compute(keyRect: keyAt(100, 150), count: 5, view: view);
      expect((mid.cells[0].center.dx - 100).abs(), lessThan(1));
      expect(mid.cells[1].center.dx, greaterThan(mid.cells[0].center.dx));
      final edge = AlternativesLayout.compute(keyRect: keyAt(340, 150), count: 5, view: view);
      expect(edge.cells[1].center.dx, lessThan(edge.cells[0].center.dx));
    });

    test('many items wrap into two rows; item 0 is in the bottom row', () {
      final l = AlternativesLayout.compute(keyRect: keyAt(180, 150), count: 12, view: view);
      expect(l.cells[0].top, greaterThan(l.cells[6].top));
      expect(l.cells[6].top, l.cells[11].top);
    });

    test('selectAt picks the item under or nearest the finger', () {
      final l = AlternativesLayout.compute(keyRect: keyAt(180, 150), count: 5, view: view);
      expect(l.selectAt(l.cells[3].center), 3);
      expect(
        l.selectAt(l.cells[4].center + const Offset(0, 80)),
        4,
        reason: 'a finger below the popup still picks by x',
      );
      expect(l.selectAt(Offset(l.cells[0].center.dx, 200)), 0);
    });

    test('preview bubble stays inside the view', () {
      for (final cx in [10.0, 180.0, 350.0]) {
        final r = previewBubbleRect(keyAt(cx, 44), view);
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(view.width));
        expect(r.top, greaterThanOrEqualTo(0));
      }
    });
  });

  group('key visuals', () {
    KeyVisual visual(KeyDef d, {ShiftState shift = ShiftState.off, KeyboardPage page = KeyboardPage.letters}) =>
        resolveKeyVisual(
          d,
          shift: shift,
          page: page,
          field: InputFieldInfo.plainText,
          typing: const TypingSettings(),
          showHints: true,
        );

    test('labels follow the case, unless lowercase labels are on', () {
      expect(visual(KeyDef.character('a')).label, 'a');
      expect(visual(KeyDef.character('a'), shift: ShiftState.once).label, 'A');
      expect(visual(KeyDef.character('a'), shift: ShiftState.caps).label, 'A');
      final keep = resolveKeyVisual(
        KeyDef.character('a'),
        shift: ShiftState.once,
        page: KeyboardPage.letters,
        field: InputFieldInfo.plainText,
        typing: const TypingSettings(lowercaseLabels: true),
        showHints: true,
      );
      expect(keep.label, 'a');
    });

    test('symbols and multi-character labels are never cased', () {
      expect(
        visual(
          const KeyDef(type: KeyType.character, output: '.com'),
          shift: ShiftState.once,
        ).label,
        '.com',
      );
      expect(visual(KeyDef.character('@'), shift: ShiftState.once).label, '@');
      expect(visual(KeyDef.character('a'), shift: ShiftState.once, page: KeyboardPage.symbols).label, 'a');
    });

    test('outputs: letters are cased, others are not; ß becomes ẞ', () {
      expect(outputFor(KeyDef.character('e'), shifted: true), 'E');
      expect(outputFor(KeyDef.character('1'), shifted: true), '1');
      expect(outputFor(const KeyDef(type: KeyType.character, output: '.com'), shifted: true), '.com');
      expect(applyShift('ß'), 'ẞ');
    });

    test('semantics name what the key types: shiftedOutput layers, and lowercase labels', () {
      const sa = KeyDef(type: KeyType.character, output: 'स', shiftedOutput: 'ष');
      expect(visual(sa).semantics, 'स');
      expect(visual(sa, shift: ShiftState.once).label, 'ष');
      expect(visual(sa, shift: ShiftState.once).semantics, 'ष');
      final lower = resolveKeyVisual(
        KeyDef.character('a'),
        shift: ShiftState.once,
        page: KeyboardPage.letters,
        field: InputFieldInfo.plainText,
        typing: const TypingSettings(lowercaseLabels: true),
        showHints: true,
      );
      expect(lower.label, 'a');
      expect(lower.semantics, 'A', reason: 'the key still types A');
    });

    test('invisible joiners get a visible popup label and a spoken name', () {
      expect(displayLabel('‍'), 'ZWJ');
      expect(displayLabel('‌'), 'ZWNJ');
      expect(displayLabel('क'), 'क');
      expect(spokenName('‍'), 'Zero width joiner');
      expect(spokenName('‌'), 'Zero width non-joiner');
    });

    test('hints show only when allowed', () {
      const def = KeyDef(type: KeyType.character, output: 'q', hint: '1');
      expect(visual(def).hint, '1');
      final off = resolveKeyVisual(
        def,
        shift: ShiftState.off,
        page: KeyboardPage.letters,
        field: InputFieldInfo.plainText,
        typing: const TypingSettings(hintLabels: false),
        showHints: true,
      );
      expect(off.hint, isNull);
      final themeOff = resolveKeyVisual(
        def,
        shift: ShiftState.off,
        page: KeyboardPage.letters,
        field: InputFieldInfo.plainText,
        typing: const TypingSettings(),
        showHints: false,
      );
      expect(themeOff.hint, isNull);
    });

    test('shift icon states and semantics', () {
      const shift = KeyDef(type: KeyType.shift);
      expect(visual(shift).shiftGlyph, ShiftGlyph.outline);
      expect(visual(shift, shift: ShiftState.once).shiftGlyph, ShiftGlyph.filled);
      expect(visual(shift, shift: ShiftState.caps).shiftGlyph, ShiftGlyph.caps);
      expect(visual(shift).semantics, 'Shift, off');
      expect(visual(shift, shift: ShiftState.once).semantics, 'Shift, on');
      expect(visual(shift, shift: ShiftState.caps).semantics, 'Shift, caps lock on');
    });

    test('the enter key follows the editor action', () {
      String name(int ime, {int type = AndroidInputType.classText}) => resolveKeyVisual(
        const KeyDef(type: KeyType.enter),
        shift: ShiftState.off,
        page: KeyboardPage.letters,
        field: InputFieldInfo(inputType: type, imeOptions: ime),
        typing: const TypingSettings(),
        showHints: true,
      ).semantics;
      expect(name(AndroidImeOptions.actionSearch), 'Search');
      expect(name(AndroidImeOptions.actionSend), 'Send');
      expect(name(AndroidImeOptions.actionGo), 'Go');
      expect(name(AndroidImeOptions.actionNext), 'Next');
      expect(name(AndroidImeOptions.actionDone), 'Done');
      expect(name(0, type: AndroidInputType.classText | AndroidInputType.textFlagMultiLine), 'Enter');
    });
  });

  group('suggestion slots', () {
    Suggestion s(String t, [SuggestionKind k = SuggestionKind.completion]) => Suggestion(t, kind: k);

    test('best in the centre, second left, third right', () {
      final slots = arrangeSlots(SuggestionBarState(suggestions: [s('a'), s('b'), s('c'), s('d')]));
      expect(slots.map((e) => e?.text), ['b', 'a', 'c']);
    });

    test('one suggestion goes in the centre', () {
      expect(arrangeSlots(SuggestionBarState(suggestions: [s('a')])).map((e) => e?.text), [null, 'a', null]);
    });

    test('the auto-correction takes the centre and duplicates are dropped', () {
      final slots = arrangeSlots(
        SuggestionBarState(
          suggestions: [s('teh', SuggestionKind.typed), s('the'), s('ten')],
          autoCorrection: s('the', SuggestionKind.correction),
          isComposing: true,
        ),
      );
      expect(slots.map((e) => e?.text), ['teh', 'the', 'ten']);
    });

    test('empty bar has no slots', () {
      expect(arrangeSlots(SuggestionBarState.empty).every((e) => e == null), isTrue);
    });
  });

  group('press animation', () {
    testWidgets('spring drives progress to 1 on press and back to 0 on release, overshooting a little', (tester) async {
      final a = KeyPressAnimator(vsync: const TestVSync());
      addTearDown(a.dispose);
      expect(a.progress(3), 0);
      a.press(3);
      var maxP = 0.0;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        maxP = maxP > a.progress(3) ? maxP : a.progress(3);
      }
      expect(a.progress(3), closeTo(1, 0.01));
      expect(maxP, greaterThan(1), reason: 'dampingRatio 0.6 overshoots');
      a.release(3);
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(a.progress(3), closeTo(0, 0.01));
      expect(a.isAnimating, isFalse);
    });

    testWidgets('no animation when motion is disabled: values jump', (tester) async {
      final a = KeyPressAnimator(vsync: const TestVSync(), motion: const MotionSpec(enabled: false));
      addTearDown(a.dispose);
      a.press(1);
      expect(a.progress(1), 1);
      expect(a.isAnimating, isFalse);
      a.release(1);
      expect(a.progress(1), 0);
    });
  });

  group('keys painter', () {
    Future<void> paintWith(WidgetTester tester, KeyboardThemeData theme, {ShiftState shift = ShiftState.once}) async {
      final laid = KeyboardLayoutEngine.layout(qwerty, const Size(360, 224), keyGap: theme.keyGap);
      final animator = KeyPressAnimator(vsync: const TestVSync(), motion: theme.motion);
      addTearDown(animator.dispose);
      animator.press(5);
      final cache = KeyTextCache();
      final painter = KeysPainter(
        laid: laid,
        theme: theme,
        shift: shift,
        page: KeyboardPage.letters,
        field: InputFieldInfo.plainText,
        typing: const TypingSettings(),
        animator: animator,
        textCache: cache,
      );
      final recorder = PictureRecorder();
      painter.paint(Canvas(recorder), const Size(360, 224));
      recorder.endRecording().dispose();
      cache.clear();
    }

    testWidgets('paints every theme variant without errors', (tester) async {
      final base = KeyboardThemeData.fallback(Brightness.light);
      KeyboardThemeData variant({
        double radius = 0.5,
        double border = 0,
        double scale = 1,
        bool hints = true,
        bool motion = true,
      }) => KeyboardThemeData(
        id: 'v',
        brightness: Brightness.light,
        background: base.background,
        letterKey: base.letterKey,
        functionKey: base.functionKey,
        actionKey: base.actionKey,
        spaceKey: base.spaceKey,
        popupFill: base.popupFill,
        popupLabel: base.popupLabel,
        popupSelectedFill: base.popupSelectedFill,
        popupSelectedLabel: base.popupSelectedLabel,
        suggestionText: base.suggestionText,
        suggestionHighlightFill: base.suggestionHighlightFill,
        suggestionHighlightText: base.suggestionHighlightText,
        suggestionDivider: base.suggestionDivider,
        toolbarIcon: base.toolbarIcon,
        trailStart: base.trailStart,
        trailEnd: base.trailEnd,
        keyCornerRadius: radius,
        borderWidth: border,
        labelScale: scale,
        showHints: hints,
        labelFontVariations: const [FontVariation('wght', 600)],
        motion: MotionSpec(enabled: motion),
      );
      await paintWith(tester, base);
      await paintWith(tester, variant(radius: 0), shift: ShiftState.off);
      await paintWith(tester, variant(border: 2, scale: 1.3, hints: false), shift: ShiftState.caps);
      await paintWith(tester, variant(motion: false));
    });

    testWidgets('text layouts are cached between paints', (tester) async {
      final cache = KeyTextCache();
      final theme = KeyboardThemeData.fallback(Brightness.dark);
      final a = cache.get(theme, 'a', 20, const Color(0xFF000000));
      final b = cache.get(theme, 'a', 20, const Color(0xFF000000));
      expect(identical(a, b), isTrue);
      expect(identical(a, cache.get(theme, 'a', 21, const Color(0xFF000000))), isFalse);
      cache.clear();
    });
  });
}
