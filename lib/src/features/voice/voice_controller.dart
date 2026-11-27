// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-D. State of one voice-typing session shown in the mic panel. It asks for permission,
// starts the Kotlin recognizer, writes partial text as composing text and final text as committed text,
// and never sends anything to learning. Voice typing works in English only (see [isVoiceLanguage]). The panel and the feature are in voice_panel.dart and voice_feature.dart.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../bridge/input_sink.dart';
import '../../bridge/messages.g.dart';
import '../../core/log.dart';

/// The text side of a voice session: [InputSink] edits plus the input controller's two calls around them.
/// [InputControllerVoiceSink] adapts the real controller; tests pass a fake.
abstract interface class VoiceTextSink {
  InputSink get editor;

  /// Ends the word being typed (kept as typed) before voice text is written.
  void finishComposing();

  /// Re-reads the text around the cursor after voice changed it.
  void resyncAfterExternalEdit();
}

/// Where a session is. The panel shows a message for every state except listening and stopping.
enum VoicePhase { disabled, checking, listening, stopping, cancelling, finished, noPermission, noModel, busy, failed }

/// Voice typing works in English only: 'en' and every 'en-*' variant ('en-GB', 'en-IN', ...).
bool isVoiceLanguage(String language) {
  final id = language.trim().toLowerCase();
  return id == 'en' || id.startsWith('en-');
}

/// True when [packs] holds a voice pack that lists an English language (the Parakeet pack).
bool hasEnglishVoicePack(Iterable<PackInfoMessage> packs) =>
    packs.any((p) => p.kind == PackKind.voice && p.languages.any(isVoiceLanguage));

/// The mic shows only when an English voice pack is installed and the keyboard language is English.
bool voiceMicVisible({required Iterable<PackInfoMessage> packs, required String language}) =>
    isVoiceLanguage(language) && hasEnglishVoicePack(packs);

/// Text the controller needs to place one utterance: the separator before it and whether it starts a sentence.
@immutable
class VoiceUtterance {
  const VoiceUtterance({required this.prefix, required this.capitalise});

  final String prefix;
  final bool capitalise;
}

/// Pure text rules for voice output (tested without a keyboard).
abstract final class VoiceText {
  /// Space before an utterance when the text before the cursor ends with a visible character.
  /// [before] is the text before the cursor (null when unknown).
  static VoiceUtterance utteranceAt(String? before) {
    final text = before ?? '';
    final trimmed = text.trimRight();
    final prefix = text.isNotEmpty && trimmed.length == text.length ? ' ' : '';
    final sentenceStart = trimmed.isEmpty || RegExp(r'[.!?]$').hasMatch(trimmed);
    return VoiceUtterance(prefix: prefix, capitalise: sentenceStart);
  }

  /// Trims [text] and capitalises its first letter when [capitalise] is set.
  static String format(String text, {required bool capitalise}) {
    final t = text.trim();
    if (t.isEmpty || !capitalise) return t;
    return t[0].toUpperCase() + t.substring(1);
  }
}

/// Drives one voice session. Create one per panel opening; [dispose] ends it.
class VoiceController extends ChangeNotifier {
  VoiceController({
    required this.host,
    required this.events,
    required this.text,
    required this.packId,
    required this.enabled,
    required this.language,
  }) {
    _subscription = events.listen(_onEvent);
    if (!enabled) _phase = VoicePhase.disabled;
  }

  final ImeHostApi host;
  final Stream<VoiceEventMessage> events;
  final VoiceTextSink text;

  /// The voice pack to use ('' = the first that covers the language).
  final String packId;

  /// False when voice typing is switched off in settings: the panel then explains that.
  final bool enabled;

  /// The keyboard language the session uses (English; other languages get "no model" from Kotlin).
  final String language;

  StreamSubscription<VoiceEventMessage>? _subscription;

  /// Runs when the session has ended and the text is in place: the owner closes the panel.
  VoidCallback? onFinished;

  VoicePhase _phase = VoicePhase.checking;
  VoicePhase get phase => _phase;

  /// Input level 0..1, about 20 updates a second while listening.
  double _level = 0;
  double get level => _level;

  /// Interim text of the current utterance (also shown as composing text in the field).
  String _partial = '';
  String get partial => _partial;

  bool _disposed = false;

  /// True once a start request reached the keyboard: only then does dispose have a session to cancel.
  bool _sessionRequested = false;
  VoiceUtterance? _utterance;
  Future<void> _queue = Future<void>.value();

  /// Starts (or restarts) recognition: permission first, then the Kotlin session.
  Future<void> begin() async {
    if (_disposed) return;
    if (!enabled) {
      _set(VoicePhase.disabled);
      return;
    }
    _partial = '';
    _level = 0;
    _set(VoicePhase.checking);
    try {
      text.finishComposing();
      var granted = await host.hasMicPermission();
      if (!granted && !_disposed) granted = await host.requestMicPermission();
      if (_disposed) return;
      if (!granted) {
        _set(VoicePhase.noPermission);
        return;
      }
      _sessionRequested = true;
      final status = await host.startVoice(VoiceRequestMessage(language: language, packId: packId));
      if (_disposed) {
        unawaited(_cancelQuietly());
        return;
      }
      switch (status) {
        case VoiceStartStatus.started:
          // The events may already have moved the session on; only a fresh check becomes listening.
          if (_phase == VoicePhase.checking) _set(VoicePhase.listening);
        case VoiceStartStatus.noPermission:
          _set(VoicePhase.noPermission);
        case VoiceStartStatus.noModel:
          _set(VoicePhase.noModel);
        case VoiceStartStatus.busy:
          _set(VoicePhase.busy);
        case VoiceStartStatus.failed:
          _set(VoicePhase.failed);
      }
      BooBoardLog.d('Voice', 'start status ${status.name}');
    } on Object catch (e) {
      BooBoardLog.w('Voice', 'start failed', e.runtimeType);
      if (!_disposed) _set(VoicePhase.failed);
    }
  }

  /// Finishes the utterance being spoken, then stops.
  void stop() {
    if (_phase != VoicePhase.listening && _phase != VoicePhase.checking) return;
    _set(VoicePhase.stopping);
    unawaited(_stopQuietly());
  }

  /// Drops the utterance being spoken (its composing text is removed), then stops.
  void cancel() {
    if (_phase == VoicePhase.finished || _phase == VoicePhase.cancelling) return;
    _cancelSession();
  }

  void _cancelSession() {
    _set(VoicePhase.cancelling);
    _enqueue(_discardUtterance);
    unawaited(_cancelQuietly());
  }

  void _onEvent(VoiceEventMessage e) {
    if (_disposed) return;
    switch (e.kind) {
      case VoiceEventKind.level:
        _level = e.level;
        notifyListeners();
      case VoiceEventKind.partial:
        if (_phase == VoicePhase.listening || _phase == VoicePhase.stopping) {
          final t = e.text ?? '';
          _enqueue(() => _showPartial(t));
        }
      case VoiceEventKind.finalText:
        if (_phase != VoicePhase.cancelling) {
          final t = e.text ?? '';
          _enqueue(() => _commitFinal(t));
        }
      case VoiceEventKind.stopped:
        _onStopped();
      case VoiceEventKind.error:
        _onError(e.errorCode);
    }
  }

  void _onError(String? code) {
    switch (code) {
      case 'audio_busy':
        _set(VoicePhase.busy);
      case 'permission_revoked':
        _set(VoicePhase.noPermission);
      default:
        _set(VoicePhase.failed);
    }
  }

  void _onStopped() {
    switch (_phase) {
      case VoicePhase.noPermission:
      case VoicePhase.noModel:
      case VoicePhase.busy:
      case VoicePhase.failed:
      case VoicePhase.disabled:
        // Keep the message on the panel; the user closes it.
        _partial = '';
        notifyListeners();
      default:
        _enqueue(() async {
          await _discardUtterance();
          _set(VoicePhase.finished);
          onFinished?.call();
        });
    }
  }

  Future<void> _showPartial(String partialText) async {
    if (_disposed) return;
    _utterance ??= VoiceText.utteranceAt(await _textBeforeCursor());
    final u = _utterance!;
    _partial = partialText.trim();
    await text.editor.setComposingText(
      u.prefix + VoiceText.format(partialText, capitalise: u.capitalise),
      newCursorPosition: 1,
    );
    text.resyncAfterExternalEdit();
    notifyListeners();
  }

  Future<void> _commitFinal(String finalText) async {
    if (_disposed) return;
    final u = _utterance ?? VoiceText.utteranceAt(await _textBeforeCursor());
    _utterance = null;
    _partial = '';
    final committed = VoiceText.format(finalText, capitalise: u.capitalise);
    if (committed.isNotEmpty) {
      await text.editor.setComposingText(u.prefix + committed, newCursorPosition: 1);
    }
    await text.editor.finishComposingText();
    text.resyncAfterExternalEdit();
    notifyListeners();
  }

  /// Removes composing text that voice wrote but never committed.
  Future<void> _discardUtterance() async {
    if (_utterance == null) return;
    _utterance = null;
    _partial = '';
    await text.editor.setComposingText('', newCursorPosition: 1);
    await text.editor.finishComposingText();
    text.resyncAfterExternalEdit();
    notifyListeners();
  }

  Future<String?> _textBeforeCursor() async {
    try {
      return await text.editor.getTextBeforeCursor(32);
    } on Object {
      return null;
    }
  }

  /// Runs text work one step at a time, in order.
  void _enqueue(Future<void> Function() op) {
    _queue = _queue.then((_) => op()).catchError((Object e) {
      BooBoardLog.w('Voice', 'text step failed', e.runtimeType);
    });
  }

  Future<void> _stopQuietly() async {
    try {
      await host.stopVoice();
    } on Object catch (e) {
      BooBoardLog.w('Voice', 'stop failed', e.runtimeType);
    }
  }

  Future<void> _cancelQuietly() async {
    try {
      await host.cancelVoice();
    } on Object catch (e) {
      BooBoardLog.w('Voice', 'cancel failed', e.runtimeType);
    }
  }

  void _set(VoicePhase next) {
    if (_disposed) return;
    _phase = next;
    if (next != VoicePhase.listening && next != VoicePhase.stopping) _level = 0;
    notifyListeners();
  }

  /// The panel closed or the session ended: stop listening and drop the composing text.
  @override
  void dispose() {
    if (_disposed) return;
    final active =
        _sessionRequested &&
        (_phase == VoicePhase.listening || _phase == VoicePhase.stopping || _phase == VoicePhase.checking);
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (active) unawaited(_cancelQuietly());
    _partial = '';
    _utterance = null;
    super.dispose();
  }
}

/// Adapts the keyboard's [InputController]-style editing to [VoiceTextSink].
class InputVoiceTextSink implements VoiceTextSink {
  InputVoiceTextSink({required this.editor, required this.finish, required this.resync});

  @override
  final InputSink editor;
  final void Function() finish;
  final void Function() resync;

  @override
  void finishComposing() => finish();

  @override
  void resyncAfterExternalEdit() => resync();
}
