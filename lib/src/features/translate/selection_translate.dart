// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-T. "Translate" for selected text (strip chips). When text is selected in an ordinary
// field, the strip offers Translate. Tapping it reads the selection once, translates it, and offers
// Replace and Insert after with a short preview. Never in password fields or incognito, and nothing is
// learned or logged.
import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:material_ui/material_ui.dart' show Icons;

import '../../app/routes.dart';
import '../../bridge/messages.g.dart';
import '../../keyboard/keyboard_session.dart';
import '../../keyboard/panels/keyboard_panel.dart';

/// Chip priority: above the Cut/Copy/Select all chips (10), which would otherwise fill all 3 slots.
const int translateChipPriority = 11;

const String translateSelectionChipId = 'translate.selection';
const String translateReplaceChipId = 'translate.replace';
const String translateInsertAfterChipId = 'translate.insert_after';
const String translateGetPackChipId = 'translate.get_pack';

/// Longest chip label, in characters.
const int _maxChipLabel = 24;

typedef TranslateCall = Future<String> Function(String text, String from, String to);

class SelectionTranslator {
  SelectionTranslator({required this.session, required this.translate, required this.enabled});

  final KeyboardSession session;
  final TranslateCall translate;

  /// Settings' `translate.enabled`, read at each selection change.
  final bool Function() enabled;

  final List<StreamSubscription<Object?>> _subs = [];
  SelectionMessage? _selection;
  int _generation = 0;

  void attach() {
    final events = session.services.events;
    _subs
      ..add(events.selection.listen(_onSelection))
      ..add(events.startInput.listen((_) => clear()));
  }

  void detach() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    clear();
  }

  void _onSelection(SelectionMessage m) {
    _selection = m;
    final input = session.input;
    if (!enabled() || input.currentField.isSensitive || input.isIncognito || m.newSelStart == m.newSelEnd) {
      clear();
      return;
    }
    session.showChip(
      StripChip(
        id: translateSelectionChipId,
        label: 'Translate',
        icon: Icons.translate,
        semanticLabel: 'Translate the selected text',
        priority: translateChipPriority,
        onTap: () => unawaited(_translate()),
      ),
    );
  }

  Future<void> _translate() async {
    final generation = ++_generation;
    final session = this.session;
    final settings = session.services.settings.value.translate;
    final text = await session.input.editor.getSelectedText().catchError((Object _) => null);
    if (generation != _generation) return;
    if (text == null || text.trim().isEmpty || !enabled()) {
      clear();
      return;
    }
    // Translate into the pair's target; when the active language already is the target, go the other way.
    var from = settings.from;
    var to = settings.to;
    if (session.activeLanguage.value == to) {
      from = to;
      to = settings.from;
    }
    try {
      final result = await translate(text, from, to);
      if (generation != _generation) return;
      if (result.trim().isEmpty) {
        clear();
        return;
      }
      _showResult(result);
    } on PlatformException catch (e) {
      if (generation != _generation) return;
      if (e.code == 'no_pack') {
        _removeAll();
        session.showChip(
          StripChip(
            id: translateGetPackChipId,
            label: 'Get the pack',
            icon: Icons.download_for_offline_outlined,
            semanticLabel: 'Get the translation pack',
            priority: translateChipPriority,
            onTap: () => unawaited(session.services.host.openSettings(BooBoardRoutes.packs)),
          ),
        );
      } else {
        clear();
      }
    } on Object {
      if (generation == _generation) clear();
    }
  }

  void _showResult(String result) {
    session
      ..removeChip(translateSelectionChipId)
      ..showChip(
        StripChip(
          id: translateReplaceChipId,
          label: chipLabel('Replace', result),
          semanticLabel: 'Replace the selection with the translation',
          priority: translateChipPriority,
          onTap: () => _replace(result),
        ),
      )
      ..showChip(
        StripChip(
          id: translateInsertAfterChipId,
          label: chipLabel('Insert after', result),
          semanticLabel: 'Insert the translation after the selection',
          priority: translateChipPriority,
          onTap: () => _insertAfter(result),
        ),
      );
  }

  /// Replace: the translation takes the place of the selection.
  void _replace(String result) {
    final input = session.input;
    input.finishComposing();
    unawaited(input.editor.commitText(result).catchError((Object _) => false));
    input.resyncAfterExternalEdit();
    clear();
  }

  /// Insert after: the cursor goes to the end of the selection, then " " and the translation.
  void _insertAfter(String result) {
    final input = session.input;
    final end = _selection?.newSelEnd;
    input.finishComposing();
    if (end != null) unawaited(input.editor.setSelection(end, end).catchError((Object _) => false));
    unawaited(input.editor.commitText(' $result').catchError((Object _) => false));
    input.resyncAfterExternalEdit();
    clear();
  }

  /// "Replace: Dónde…" style label of at most [_maxChipLabel] characters.
  static String chipLabel(String action, String result) {
    final room = _maxChipLabel - action.length - 2;
    final flat = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    final preview = flat.length <= room ? flat : '${flat.substring(0, room - 1)}…';
    return '$action: $preview';
  }

  void _removeAll() {
    session
      ..removeChip(translateSelectionChipId)
      ..removeChip(translateReplaceChipId)
      ..removeChip(translateInsertAfterChipId)
      ..removeChip(translateGetPackChipId);
  }

  /// Drops every translate chip and cancels a pending translation.
  void clear() {
    _generation++;
    _removeAll();
  }
}
