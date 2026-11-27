// SPDX-License-Identifier: GPL-3.0-or-later
//
// TalkBack nodes for the keys. Each key is a button with its spoken name; a tap types its main
// output. Long-press alternatives ("Type é", "Type ZWJ") and 12-key flick directions ("Type い")
// are custom actions, so no long press is needed to reach them. Custom actions need widget-level
// Semantics: CustomPainterSemantics only carries a tap, so the keys painter defers to this layer.
//
// Every action types through the same path as a tap: a synthetic character key whose output is
// the text, handed to the key's `onActivate` (KeyboardViewController.activateKey).
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../../core/input_field_info.dart';
import '../../settings/sections/typing_settings.dart';
import '../input/input_controller.dart';
import '../input/keyboard_page.dart';
import '../layout/layout_engine.dart';
import '../layout/layout_model.dart';
import '../view/key_visuals.dart';

/// The page-switch keys mark the page they show as selected ("?123" on the symbols page).
bool keyIsCurrentPage(KeyDef def, KeyboardPage page) => switch (def.type) {
  KeyType.symbols => page == KeyboardPage.symbols,
  KeyType.moreSymbols => page == KeyboardPage.symbols2,
  KeyType.numbers => page == KeyboardPage.numpad,
  _ => false,
};

/// "Type é" for each long-press alternative (shifted when the letters are shifted), and "Type い"
/// for each flick direction. Null when the key has neither.
Map<CustomSemanticsAction, VoidCallback>? keyCustomActions(
  PlacedKey key, {
  required ShiftState shift,
  required KeyboardPage page,
  required void Function(PlacedKey key) onActivate,
}) {
  final def = key.def;
  final actions = <CustomSemanticsAction, VoidCallback>{};
  void typeAction(String text) {
    actions[CustomSemanticsAction(label: 'Type ${displayLabel(text)}')] = () => onActivate(
      PlacedKey(
        def: KeyDef(type: KeyType.character, output: text),
        index: key.index,
        row: key.row,
        column: key.column,
        cell: key.cell,
        rect: key.rect,
      ),
    );
  }

  final characterLike = def.type == KeyType.character || def.type == KeyType.comma || def.type == KeyType.period;
  if (characterLike) {
    final shifted = shift != ShiftState.off && page == KeyboardPage.letters;
    for (final alt in def.popup) {
      typeAction(shifted ? applyShift(alt) : alt);
    }
  }
  final flick = def.flick;
  if (def.isCharacter && flick != null) {
    for (final text in flick.values) {
      if (text.isNotEmpty) typeAction(text);
    }
  }
  return actions.isEmpty ? null : actions;
}

/// One Semantics node per key, laid over the keys area at each key's cell. Put it above the keys
/// painter in the same Positioned.fill and pass `overlayProvidesSemantics: true` to KeysPainter.
class KeySemanticsLayer extends StatelessWidget {
  const KeySemanticsLayer({
    super.key,
    required this.laid,
    required this.shift,
    required this.page,
    required this.field,
    required this.typing,
    required this.onActivate,
    this.spaceLabel,
  });

  final LaidOutKeyboard laid;
  final ShiftState shift;
  final KeyboardPage page;
  final InputFieldInfo field;
  final TypingSettings typing;
  final String? spaceLabel;
  final void Function(PlacedKey key) onActivate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final k in laid.keys)
          Positioned.fromRect(
            rect: k.cell,
            child: Semantics(
              container: true,
              button: true,
              label: resolveKeyVisual(
                k.def,
                shift: shift,
                page: page,
                field: field,
                typing: typing,
                showHints: false,
                spaceLabel: spaceLabel,
              ).semantics,
              selected: keyIsCurrentPage(k.def, page) ? true : null,
              onTap: () => onActivate(k),
              customSemanticsActions: keyCustomActions(k, shift: shift, page: page, onActivate: onActivate),
              sortKey: OrdinalSortKey(k.row * 1000.0 + k.column),
              textDirection: TextDirection.ltr,
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }
}
