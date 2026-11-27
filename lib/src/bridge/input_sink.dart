// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (Wave 0). Everything that edits the focused text field goes
// through InputSink, so keyboard logic is testable against FakeEditor
// (test/support/fake_editor.dart) without a device.
//
// Calls are queued in order on the platform thread. Await only when you need
// the result; otherwise wrap with unawaited().
import 'messages.g.dart';

abstract interface class InputSink {
  Future<bool> commitText(String text, {int newCursorPosition = 1});
  Future<bool> setComposingText(String text, {int newCursorPosition = 1});
  Future<bool> setComposingRegion(int start, int end);
  Future<bool> finishComposingText();

  /// Lengths are UTF-16 code units, as on Android.
  Future<bool> deleteSurroundingText(int before, int after);
  Future<bool> deleteSurroundingTextInCodePoints(int before, int after);
  Future<bool> sendDownUpKeyEvent(int keyCode, {int metaState = 0});
  Future<bool> performEditorAction(int actionId);
  Future<bool> performContextMenuAction(ContextMenuAction action);
  Future<bool> setSelection(int start, int end);
  Future<String?> getTextBeforeCursor(int length);
  Future<String?> getTextAfterCursor(int length);
  Future<String?> getSelectedText();
  Future<SurroundingTextMessage?> getSurroundingText(int before, int after);

  /// [reqModes] is a combination of AndroidCapsMode flags.
  Future<int> getCursorCapsMode(int reqModes);
  Future<bool> beginBatchEdit();
  Future<bool> endBatchEdit();
}

/// Production InputSink backed by the Kotlin InputConnection.
class PigeonInputSink implements InputSink {
  PigeonInputSink(this._api);

  final ImeHostApi _api;

  @override
  Future<bool> commitText(String text, {int newCursorPosition = 1}) => _api.commitText(text, newCursorPosition);

  @override
  Future<bool> setComposingText(String text, {int newCursorPosition = 1}) =>
      _api.setComposingText(text, newCursorPosition);

  @override
  Future<bool> setComposingRegion(int start, int end) => _api.setComposingRegion(start, end);

  @override
  Future<bool> finishComposingText() => _api.finishComposingText();

  @override
  Future<bool> deleteSurroundingText(int before, int after) => _api.deleteSurroundingText(before, after);

  @override
  Future<bool> deleteSurroundingTextInCodePoints(int before, int after) =>
      _api.deleteSurroundingTextInCodePoints(before, after);

  @override
  Future<bool> sendDownUpKeyEvent(int keyCode, {int metaState = 0}) => _api.sendDownUpKeyEvent(keyCode, metaState);

  @override
  Future<bool> performEditorAction(int actionId) => _api.performEditorAction(actionId);

  @override
  Future<bool> performContextMenuAction(ContextMenuAction action) => _api.performContextMenuAction(action);

  @override
  Future<bool> setSelection(int start, int end) => _api.setSelection(start, end);

  @override
  Future<String?> getTextBeforeCursor(int length) => _api.getTextBeforeCursor(length);

  @override
  Future<String?> getTextAfterCursor(int length) => _api.getTextAfterCursor(length);

  @override
  Future<String?> getSelectedText() => _api.getSelectedText();

  @override
  Future<SurroundingTextMessage?> getSurroundingText(int before, int after) => _api.getSurroundingText(before, after);

  @override
  Future<int> getCursorCapsMode(int reqModes) => _api.getCursorCapsMode(reqModes);

  @override
  Future<bool> beginBatchEdit() => _api.beginBatchEdit();

  @override
  Future<bool> endBatchEdit() => _api.endBatchEdit();
}
