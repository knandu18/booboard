// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Cut, Copy and Select all chips in the suggestion strip while text is selected in an
// ordinary field (never in a password field). They disappear when the selection collapses or the focused
// field changes.
import 'dart:async';

import 'package:flutter/widgets.dart' show IconData;
import 'package:material_ui/material_ui.dart' show Icons;

import '../../bridge/messages.g.dart';
import '../../keyboard/keyboard_session.dart';
import '../../keyboard/panels/keyboard_panel.dart';

/// Chip priority: above suggestions-free chips such as the recent-copy chip.
const int selectionChipPriority = 10;

const String cutChipId = 'editing.cut';
const String copyChipId = 'editing.copy';
const String selectAllChipId = 'editing.select_all';

class SelectionChips {
  SelectionChips(this.session);

  final KeyboardSession session;
  final List<StreamSubscription<Object?>> _subs = [];

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
    if (session.input.currentField.isSensitive || m.newSelStart == m.newSelEnd) {
      clear();
      return;
    }
    _chip(cutChipId, 'Cut', Icons.content_cut, ContextMenuAction.cut);
    _chip(copyChipId, 'Copy', Icons.content_copy, ContextMenuAction.copy);
    _chip(selectAllChipId, 'Select all', Icons.select_all, ContextMenuAction.selectAll);
  }

  void _chip(String id, String label, IconData icon, ContextMenuAction action) {
    session.showChip(
      StripChip(
        id: id,
        label: label,
        icon: icon,
        semanticLabel: label,
        priority: selectionChipPriority,
        onTap: () => _run(action),
      ),
    );
  }

  void _run(ContextMenuAction action) {
    final input = session.input;
    input.finishComposing();
    unawaited(input.editor.performContextMenuAction(action).catchError((Object _) => false));
    input.resyncAfterExternalEdit();
  }

  void clear() {
    session
      ..removeChip(cutChipId)
      ..removeChip(copyChipId)
      ..removeChip(selectAllChipId);
  }
}
