// SPDX-License-Identifier: GPL-3.0-or-later
//
// An in-memory text field that behaves like Android's EditText +
// BaseInputConnection, for unit-testing keyboard logic without a device.
//
// Semantics follow android.view.inputmethod.InputConnection:
// - commitText/setComposingText replace the composing region if any, else the selection.
// - newCursorPosition > 0 is relative to the end of the inserted text (1 = right after it),
//   <= 0 is relative to its start.
// - deleteSurroundingText deletes around the selection, ignoring the composing region.
import 'package:characters/characters.dart';
import 'package:booboard/src/bridge/input_sink.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';

class FakeEditor implements InputSink {
  FakeEditor({String text = '', int? cursor})
    : _text = text,
      _selStart = cursor ?? text.length,
      _selEnd = cursor ?? text.length;

  String _text;
  int _selStart;
  int _selEnd;
  int _composeStart = -1;
  int _composeEnd = -1;
  int _batchDepth = 0;

  final List<int> editorActions = [];
  final List<ContextMenuAction> contextActions = [];
  final List<String> log = [];

  /// Called after every edit, like InputMethodService.onUpdateSelection.
  void Function(SelectionMessage selection)? onSelectionChanged;

  String get text => _text;
  int get selectionStart => _selStart;
  int get selectionEnd => _selEnd;
  String? get composing => _composeStart < 0 ? null : _text.substring(_composeStart, _composeEnd);

  /// Text with "|" at the cursor (or [selection]) and composing text in <>.
  String get debugView {
    final b = StringBuffer();
    for (var i = 0; i <= _text.length; i++) {
      if (i == _composeStart) b.write('<');
      if (i == _composeEnd && _composeStart >= 0) b.write('>');
      if (i == _selStart) b.write(_selStart == _selEnd ? '|' : '[');
      if (i == _selEnd && _selStart != _selEnd) b.write(']');
      if (i < _text.length) b.write(_text[i]);
    }
    return b.toString();
  }

  void _replace(int start, int end, String with_, int newCursorPosition, {required bool compose}) {
    final oldSel = (_selStart, _selEnd);
    _text = _text.replaceRange(start, end, with_);
    if (compose) {
      _composeStart = start;
      _composeEnd = start + with_.length;
    } else {
      _composeStart = _composeEnd = -1;
    }
    final anchor = newCursorPosition > 0 ? start + with_.length + newCursorPosition - 1 : start + newCursorPosition;
    _selStart = _selEnd = anchor.clamp(0, _text.length);
    _notify(oldSel);
  }

  (int, int) get _target => _composeStart >= 0 ? (_composeStart, _composeEnd) : (_selStart, _selEnd);

  void _notify((int, int) old) {
    if (_batchDepth > 0) return;
    onSelectionChanged?.call(
      SelectionMessage(
        oldSelStart: old.$1,
        oldSelEnd: old.$2,
        newSelStart: _selStart,
        newSelEnd: _selEnd,
        candidatesStart: _composeStart,
        candidatesEnd: _composeEnd,
      ),
    );
  }

  @override
  Future<bool> commitText(String text, {int newCursorPosition = 1}) async {
    log.add('commit("$text")');
    final (s, e) = _target;
    _replace(s, e, text, newCursorPosition, compose: false);
    return true;
  }

  @override
  Future<bool> setComposingText(String text, {int newCursorPosition = 1}) async {
    log.add('compose("$text")');
    final (s, e) = _target;
    _replace(s, e, text, newCursorPosition, compose: true);
    return true;
  }

  @override
  Future<bool> setComposingRegion(int start, int end) async {
    log.add('composingRegion($start,$end)');
    final a = start.clamp(0, _text.length);
    final b = end.clamp(0, _text.length);
    if (a == b) {
      _composeStart = _composeEnd = -1;
    } else {
      _composeStart = a < b ? a : b;
      _composeEnd = a < b ? b : a;
    }
    _notify((_selStart, _selEnd));
    return true;
  }

  @override
  Future<bool> finishComposingText() async {
    log.add('finishComposing');
    _composeStart = _composeEnd = -1;
    _notify((_selStart, _selEnd));
    return true;
  }

  @override
  Future<bool> deleteSurroundingText(int before, int after) async {
    log.add('delete($before,$after)');
    final old = (_selStart, _selEnd);
    final a = (_selStart - before).clamp(0, _text.length);
    final b = (_selEnd + after).clamp(0, _text.length);
    final removedBefore = _selStart - a;
    _text = _text.replaceRange(_selEnd, b, '').replaceRange(a, _selStart, '');
    _selStart -= removedBefore;
    _selEnd -= removedBefore;
    _composeStart = _composeEnd = -1;
    _notify(old);
    return true;
  }

  @override
  Future<bool> deleteSurroundingTextInCodePoints(int before, int after) async {
    final beforeText = _text.substring(0, _selStart);
    final afterText = _text.substring(_selEnd);
    final b = _unitsForCodePoints(beforeText.runes.toList().reversed, before);
    final a = _unitsForCodePoints(afterText.runes, after);
    return deleteSurroundingText(b, a);
  }

  int _unitsForCodePoints(Iterable<int> runes, int count) =>
      runes.take(count).fold<int>(0, (sum, r) => sum + (r > 0xFFFF ? 2 : 1));

  @override
  Future<bool> sendDownUpKeyEvent(int keyCode, {int metaState = 0}) async {
    log.add('key($keyCode)');
    switch (keyCode) {
      case AndroidKeyCode.del:
        if (_selStart != _selEnd) return commitText('');
        if (_selStart == 0) return true;
        final lastGrapheme = _text.substring(0, _selStart).characters.last;
        return deleteSurroundingText(lastGrapheme.length, 0);
      case AndroidKeyCode.forwardDel:
        if (_selStart != _selEnd) return commitText('');
        if (_selEnd == _text.length) return true;
        return deleteSurroundingText(0, _text.substring(_selEnd).characters.first.length);
      case AndroidKeyCode.enter:
        return commitText('\n');
      case AndroidKeyCode.dpadLeft:
        return setSelection(_selStart - 1, _selStart - 1);
      case AndroidKeyCode.dpadRight:
        return setSelection(_selEnd + 1, _selEnd + 1);
      case AndroidKeyCode.moveHome:
        return setSelection(0, 0);
      case AndroidKeyCode.moveEnd:
        return setSelection(_text.length, _text.length);
      default:
        return true;
    }
  }

  @override
  Future<bool> performEditorAction(int actionId) async {
    editorActions.add(actionId);
    return true;
  }

  @override
  Future<bool> performContextMenuAction(ContextMenuAction action) async {
    contextActions.add(action);
    if (action == ContextMenuAction.selectAll) return setSelection(0, _text.length);
    return true;
  }

  @override
  Future<bool> setSelection(int start, int end) async {
    final old = (_selStart, _selEnd);
    _selStart = start.clamp(0, _text.length);
    _selEnd = end.clamp(0, _text.length);
    _notify(old);
    return true;
  }

  @override
  Future<String?> getTextBeforeCursor(int length) async {
    final start = (_selStart - length).clamp(0, _selStart);
    return _text.substring(start, _selStart);
  }

  @override
  Future<String?> getTextAfterCursor(int length) async {
    final end = (_selEnd + length).clamp(_selEnd, _text.length);
    return _text.substring(_selEnd, end);
  }

  @override
  Future<String?> getSelectedText() async => _selStart == _selEnd ? null : _text.substring(_selStart, _selEnd);

  @override
  Future<SurroundingTextMessage?> getSurroundingText(int before, int after) async {
    final start = (_selStart - before).clamp(0, _selStart);
    final end = (_selEnd + after).clamp(_selEnd, _text.length);
    return SurroundingTextMessage(
      text: _text.substring(start, end),
      selectionStart: _selStart - start,
      selectionEnd: _selEnd - start,
      offset: start,
    );
  }

  @override
  Future<int> getCursorCapsMode(int reqModes) async {
    final before = _text.substring(0, _selStart);
    var mode = 0;
    if (reqModes & AndroidCapsMode.characters != 0) mode |= AndroidCapsMode.characters;
    final trimmed = before.trimRight();
    final atWordStart = before.isEmpty || before.endsWith(' ') || before.endsWith('\n');
    if (reqModes & AndroidCapsMode.words != 0 && atWordStart) mode |= AndroidCapsMode.words;
    final sentenceStart = trimmed.isEmpty || RegExp(r'[.!?]["”’)]*$').hasMatch(trimmed);
    if (reqModes & AndroidCapsMode.sentences != 0 && atWordStart && sentenceStart) {
      mode |= AndroidCapsMode.sentences;
    }
    return mode;
  }

  @override
  Future<bool> beginBatchEdit() async {
    _batchDepth++;
    return true;
  }

  @override
  Future<bool> endBatchEdit() async {
    if (_batchDepth > 0) _batchDepth--;
    if (_batchDepth == 0) _notify((_selStart, _selEnd));
    return true;
  }
}
