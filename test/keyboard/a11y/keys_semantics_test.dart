// SPDX-License-Identifier: GPL-3.0-or-later
//
// TalkBack on the keys: every key is a labelled button that taps, long-press alternatives and flick
// directions are custom actions that type, shift and page states are in the labels, and the nodes
// come row by row. The key nodes come from KeySemanticsLayer; the painter defers to it.
import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/keyboard/a11y/key_semantics.dart';
import 'package:booboard/src/keyboard/input/input_controller.dart';
import 'package:booboard/src/keyboard/input/keyboard_page.dart';
import 'package:booboard/src/keyboard/layout/layout_engine.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/keyboard/view/key_press_animator.dart';
import 'package:booboard/src/keyboard/view/key_visuals.dart';
import 'package:booboard/src/keyboard/view/keys_painter.dart';
import 'package:booboard/src/settings/sections/typing_settings.dart';
import 'package:booboard/src/theme/presets.dart';
import 'package:booboard/src/theme/theme_resolver.dart';

/// A ticker source for the press animator; the tests never start it.
class _Vsync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

KeyboardLayoutDef _layout(String json) => KeyboardLayoutDef.fromJson(jsonDecode(json) as Map<String, Object?>);

final KeyboardLayoutDef _sample = _layout('''
{"id": "t", "name": "t", "rows": [
  {"keys": [{"output": "e", "popup": ["é", "è"]}, {"output": "か", "flick": {"up": "き", "down": "く"}}, "x"]},
  {"keys": [{"type": "shift", "width": 1.5}, {"type": "symbols", "width": 1.5}, {"type": "space", "width": 3}]}
]}
''');

const Size _size = Size(400, 240);

Future<void> _pump(
  WidgetTester tester,
  KeyboardLayoutDef def, {
  ShiftState shift = ShiftState.off,
  KeyboardPage page = KeyboardPage.letters,
  void Function(PlacedKey key)? onActivate,
}) async {
  final theme = resolveKeyboardThemeFromSpec(ThemePresets.booboardGold, dark: false);
  final laid = KeyboardLayoutEngine.layout(def, _size, keyGap: theme.keyGap, split: false, compact: false);
  final painter = KeysPainter(
    laid: laid,
    theme: theme,
    shift: shift,
    page: page,
    field: InputFieldInfo.plainText,
    typing: const TypingSettings(),
    animator: KeyPressAnimator(vsync: _Vsync()),
    textCache: KeyTextCache(),
    onActivate: onActivate,
    overlayProvidesSemantics: true,
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: _size.width,
        height: _size.height,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: painter)),
            Positioned.fill(
              child: KeySemanticsLayer(
                laid: laid,
                shift: shift,
                page: page,
                field: InputFieldInfo.plainText,
                typing: const TypingSettings(),
                onActivate: onActivate ?? (_) {},
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The semantics owner the test binding drives. The binding exposes it through its pipeline owner
/// (the root owner has none in widget tests).
SemanticsOwner? _semanticsOwner(WidgetTester tester) =>
    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner;

/// Every key node, in traversal order.
List<SemanticsNode> _keyNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isButton) nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(_semanticsOwner(tester)!.rootSemanticsNode!);
  return nodes;
}

List<String> _customLabels(SemanticsNode node) {
  final ids = node.getSemanticsData().customSemanticsActionIds ?? const <int>[];
  return [for (final id in ids) CustomSemanticsAction.getAction(id)!.label!];
}

void _performCustom(WidgetTester tester, SemanticsNode node, String label) {
  final ids = node.getSemanticsData().customSemanticsActionIds ?? const <int>[];
  final id = ids.firstWhere((id) => CustomSemanticsAction.getAction(id)!.label == label);
  _semanticsOwner(tester)!.performAction(node.id, SemanticsAction.customAction, id);
}

void main() {
  testWidgets('every key is a labelled button with a tap action', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _sample, onActivate: (_) {});
    final nodes = _keyNodes(tester);
    expect(nodes, hasLength(_sample.keys.length));
    for (final node in nodes) {
      final data = node.getSemanticsData();
      expect(data.label, isNotEmpty);
      expect(data.hasAction(SemanticsAction.tap), isTrue, reason: data.label);
    }
    handle.dispose();
  });

  testWidgets('a tap action types the key', (tester) async {
    final handle = tester.ensureSemantics();
    final typed = <String?>[];
    await _pump(tester, _sample, onActivate: (key) => typed.add(key.def.output));
    final first = _keyNodes(tester).first;
    _semanticsOwner(tester)!.performAction(first.id, SemanticsAction.tap);
    expect(typed, ['e']);
    handle.dispose();
  });

  testWidgets('long-press alternatives and flick directions are custom actions that type', (tester) async {
    final handle = tester.ensureSemantics();
    final typed = <String?>[];
    await _pump(tester, _sample, onActivate: (key) => typed.add(key.def.output));
    final nodes = _keyNodes(tester);

    expect(_customLabels(nodes[0]), containsAll(['Type é', 'Type è']));
    _performCustom(tester, nodes[0], 'Type é');
    expect(typed.last, 'é');

    expect(_customLabels(nodes[1]), containsAll(['Type き', 'Type く']));
    _performCustom(tester, nodes[1], 'Type く');
    expect(typed.last, 'く');

    // A plain key has no custom actions, only its tap.
    expect(_customLabels(nodes[2]), isEmpty);
    handle.dispose();
  });

  testWidgets('shift and caps states are in the shift key label', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _sample, onActivate: (_) {});
    expect(_keyNodes(tester)[3].getSemanticsData().label, 'Shift, off');

    await _pump(tester, _sample, shift: ShiftState.once, onActivate: (_) {});
    expect(_keyNodes(tester)[3].getSemanticsData().label, 'Shift, on');

    await _pump(tester, _sample, shift: ShiftState.caps, onActivate: (_) {});
    expect(_keyNodes(tester)[3].getSemanticsData().label, 'Shift, caps lock on');
    handle.dispose();
  });

  testWidgets('the page-switch key of the shown page is selected', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _sample, page: KeyboardPage.symbols, onActivate: (_) {});
    final symbols = _keyNodes(tester)[4];
    expect(symbols.getSemanticsData().label, 'Symbols');
    expect(_selected(symbols), isTrue);

    await _pump(tester, _sample, onActivate: (_) {});
    expect(_selected(_keyNodes(tester)[4]), isFalse);
    handle.dispose();
  });

  testWidgets('nodes come row by row, left to right', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _sample, onActivate: (_) {});
    // The expected order is the layout's own: row by row, each row left to right.
    final theme = resolveKeyboardThemeFromSpec(ThemePresets.booboardGold, dark: false);
    final laid = KeyboardLayoutEngine.layout(_sample, _size, keyGap: theme.keyGap, split: false, compact: false);
    final expected = [
      for (final k in laid.keys)
        resolveKeyVisual(
          k.def,
          shift: ShiftState.off,
          page: KeyboardPage.letters,
          field: InputFieldInfo.plainText,
          typing: const TypingSettings(),
          showHints: false,
        ).semantics,
    ];
    expect([for (final n in _keyNodes(tester)) n.getSemanticsData().label], expected);
    handle.dispose();
  });

  testWidgets('the painter stops its own nodes when the layer provides them', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _sample, onActivate: (_) {});
    // Only the layer's nodes are buttons; the painter adds none on top of them.
    expect(_keyNodes(tester), hasLength(_sample.keys.length));
    handle.dispose();
  });

  test('spoken names cover symbols, scripts and CJK marks', () {
    expect(spokenName('€'), 'Euro');
    expect(spokenName('©'), 'Copyright');
    expect(spokenName('、'), 'Comma');
    expect(spokenName('。'), 'Full stop');
    expect(spokenName('ー'), 'Long vowel mark');
    expect(spokenName('्'), 'halant');
    expect(spokenName('़'), 'nukta');
    expect(spokenName('ं'), 'anusvara');
    expect(spokenName('ः'), 'visarga');
    expect(spokenName('َ'), 'fatha');
    expect(spokenName('ِ'), 'kasra');
    // A combining mark with no name is never spoken as a lone glyph.
    expect(spokenName('́'), 'combining mark');
    // Ordinary letters are spoken as themselves.
    expect(spokenName('q'), 'q');
  });
}

// ignore: deprecated_member_use
bool _selected(SemanticsNode node) => node.getSemanticsData().hasFlag(SemanticsFlag.isSelected);
