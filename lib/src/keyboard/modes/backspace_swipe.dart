// SPDX-License-Identifier: GPL-3.0-or-later
//
// Backspace swipe-to-delete. Dragging left on the backspace key selects whole words backwards from
// the cursor (one more word per 24 dp). Dragging back shrinks the selection. Releasing deletes the
// selection and offers an Undo chip for 5 s. Releasing with nothing selected restores the original
// selection and does nothing.
//
// The deleted text is kept in memory only for the undo. It is never logged or stored.
import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Icons;

import '../input/input_controller.dart';
import '../panels/keyboard_panel.dart' show StripChip;
import 'word_bounds.dart';

/// Dp of leftward travel per extra word.
const double kDpPerWord = 24;

/// How long the undo chip stays (and the deleted text is kept for it).
const Duration kUndoWindow = Duration(seconds: 5);

/// Chip id: a feature that shows undo for an edit uses this id.
const String kUndoDeleteChipId = 'editing.undo_delete';

/// Characters read around the cursor. About 100 words; a longer swipe stops at the window.
const int kSwipeWindow = 512;

class BackspaceSwipe {
  BackspaceSwipe({
    required this.input,
    required this.showChip,
    required this.removeChip,
    this.onWordStep,
    this.dpPerWord = kDpPerWord,
  });

  final InputController input;
  final void Function(StripChip chip) showChip;
  final void Function(String id) removeChip;

  /// Called when one more word is selected (a haptic tick).
  final void Function()? onWordStep;
  final double dpPerWord;

  bool _active = false;
  bool _valid = false;
  Future<void> _chain = Future.value();

  // Snapshot of the text around the cursor when the swipe started. Offsets are relative to [_text].
  String _text = '';
  int _textOffset = 0;
  int _anchor = 0;
  int _selEnd = 0;
  int _words = 0;

  String? _deleted;
  Timer? _forget;

  /// Called with the horizontal travel since touch-down, in dp. [done] is true when the finger lifts.
  void drag(double dx, {required bool done}) {
    if (!done) {
      if (!_active) {
        if (!_canEdit()) return;
        _active = true;
        input.finishComposing();
        _chain = _chain.then((_) => _snapshot());
      }
      _chain = _chain.then((_) => _apply(dx));
      return;
    }
    if (!_active) return;
    _active = false;
    _chain = _chain.then((_) => _finish());
  }

  /// Drops the undo text and any pending work. Called when the keyboard session ends.
  void dispose() {
    _forget?.cancel();
    _deleted = null;
    _active = false;
  }

  bool _canEdit() {
    final field = input.currentField;
    return !field.isSensitive && !field.isRawKeyMode && input.redirect.value == null;
  }

  Future<void> _snapshot() async {
    final s = await input.editor.getSurroundingText(kSwipeWindow, 0);
    if (s == null) {
      _valid = false;
      return;
    }
    _text = s.text;
    _textOffset = s.offset;
    _anchor = s.selectionStart;
    _selEnd = s.selectionEnd;
    _words = 0;
    _valid = true;
  }

  Future<void> _apply(double dx) async {
    if (!_valid) return;
    final words = math.max(0, (-dx / dpPerWord).floor());
    if (words == _words) return;
    final before = _words;
    _words = words;
    final start = wordStartBefore(_text, _anchor, words);
    await input.editor.setSelection(_textOffset + start, _textOffset + _selEnd);
    if (words > before) onWordStep?.call();
  }

  Future<void> _finish() async {
    final valid = _valid;
    _valid = false;
    final words = _words;
    _words = 0;
    if (!valid || words == 0) return;
    final start = wordStartBefore(_text, _anchor, words);
    if (start >= _selEnd) return;
    // The selection is already [start, _selEnd]; commitText('') replaces it with nothing.
    final deleted = _text.substring(start, _selEnd);
    await input.editor.commitText('');
    input.resyncAfterExternalEdit();
    _deleted = deleted;
    _forget?.cancel();
    _forget = Timer(kUndoWindow, () => _deleted = null);
    showChip(
      StripChip(
        id: kUndoDeleteChipId,
        label: 'Undo',
        icon: Icons.undo,
        semanticLabel: 'Undo word deletion',
        expiresAfter: kUndoWindow,
        onTap: undo,
      ),
    );
  }

  /// Puts back the words deleted by the last swipe, at the cursor.
  void undo() {
    final text = _deleted;
    removeChip(kUndoDeleteChipId);
    if (text == null) return;
    _deleted = null;
    _forget?.cancel();
    input.insertText(text);
  }
}
