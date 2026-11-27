// SPDX-License-Identifier: GPL-3.0-or-later
//
// Raw pointer handling for the key area: hit-testing, pressed state,
// long-press popups, backspace repeat, rollover and gesture typing.
// Plain Dart (no widgets), driven by a Listener in KeyboardKeysArea.
//
// PRIVACY: nothing typed is ever logged here.
import 'dart:async';
import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import '../../bridge/messages.g.dart';
import '../../core/log.dart';
import '../../engine/contracts.dart';
import '../../settings/booboard_settings.dart';
import '../input/input_controller.dart';
import '../input/keyboard_page.dart';
import '../gesture_layer/gesture_trail.dart';
import '../layout/layout_engine.dart';
import '../layout/layout_model.dart';
import 'key_visuals.dart';
import 'keyboard_hooks.dart';
import 'keyboard_metrics.dart';
import 'key_press_animator.dart';
import 'popup_layer.dart';

class _Touch {
  _Touch(this.pointer, this.down, this.key);

  final int pointer;
  final Offset down;
  PlacedKey key;
  final List<TouchPoint> points = [];

  /// The key's action already ran (backspace, rollover, long-press consumed).
  bool committed = false;
  bool gesture = false;
  AlternativesState? alternatives;
  bool hookDrag = false;

  /// A 12-key flick key is held (Wave 4); [flickDir] is where the finger points now.
  FlickGuideState? flick;
  FlickDirection flickDir = FlickDirection.center;
  Timer? longPress;
  Timer? repeat;
  int heldMs = 0;
  int repeats = 0;
  int lastPreviewMs = -1000;
}

class KeyboardViewController {
  KeyboardViewController({
    required this._input,
    required this._decoder,
    required this._trail,
    required this._animator,
    required this._host,
    required this._settings,
    this.hooks = const KeyboardHooks(),
  });

  final InputController _input;
  final GestureDecoder _decoder;
  final GestureTrailController _trail;
  final KeyPressAnimator _animator;
  final ImeHostApi _host;
  final BooBoardSettings Function() _settings;
  KeyboardHooks hooks;

  /// Set by the view whenever it lays the keys out.
  LaidOutKeyboard? layout;

  /// Size of the whole keyboard view (strip + keys); popups are clamped to it.
  Size viewSize = Size.zero;

  /// Vertical offset of the key area inside the view (the suggestion strip).
  double keyAreaTop = KeyboardMetrics.stripHeight;

  /// The popup currently shown (preview bubble or alternatives).
  final ValueNotifier<PopupState?> popup = ValueNotifier(null);

  final Map<int, _Touch> _touches = {};
  bool _previewBusy = false;

  static final RegExp _letterRe = RegExp(r'^\p{L}$', unicode: true);

  bool get hasActiveTouches => _touches.isNotEmpty;

  BooBoardSettings get _s => _settings();
  bool get _shifted => _input.shift.value != ShiftState.off && _input.page.value == KeyboardPage.letters;

  // ---- Feedback ---------------------------------------------------------

  void _fire(Future<void> Function() call) {
    try {
      unawaited(call().catchError((Object e) => BooBoardLog.w('Keys', 'host call failed', e.runtimeType)));
    } on Object catch (e) {
      BooBoardLog.w('Keys', 'host call failed', e.runtimeType);
    }
  }

  void _haptic(HapticKind kind) {
    if (_s.feedback.haptics) _fire(() => _host.performHaptic(kind));
  }

  void _sound(KeySoundKind kind) {
    if (_s.feedback.sounds) _fire(() => _host.playKeySound(kind));
  }

  void _feedbackDown(KeyDef def) {
    switch (def.type) {
      case KeyType.shift:
      case KeyType.symbols:
      case KeyType.moreSymbols:
      case KeyType.alphabet:
      case KeyType.numbers:
        _haptic(HapticKind.toggle);
        _sound(KeySoundKind.standard);
      case KeyType.space:
        _haptic(HapticKind.keyTap);
        _sound(KeySoundKind.space);
      case KeyType.backspace:
        _haptic(HapticKind.keyTap);
        _sound(KeySoundKind.delete);
      case KeyType.enter:
        _haptic(HapticKind.keyTap);
        _sound(KeySoundKind.enter);
      default:
        _haptic(HapticKind.keyTap);
        _sound(KeySoundKind.standard);
    }
  }

  // ---- Pointer events ---------------------------------------------------

  void onPointerDown(PointerDownEvent e) => _down(e.pointer, e.localPosition, e.timeStamp.inMilliseconds);
  void onPointerMove(PointerMoveEvent e) => _move(e.pointer, e.localPosition, e.timeStamp.inMilliseconds);
  void onPointerUp(PointerUpEvent e) => _up(e.pointer, e.localPosition, e.timeStamp.inMilliseconds);
  void onPointerCancel(PointerCancelEvent e) => _cancel(e.pointer);

  void _down(int pointer, Offset pos, int ms) {
    final laid = layout;
    if (laid == null) return;
    // Rollover: a new finger commits the previous key right away.
    for (final t in _touches.values.toList()) {
      _rollover(t);
    }
    final key = laid.hitTest(pos);
    if (key == null) return;
    final t = _Touch(pointer, pos, key)..points.add(TouchPoint(pos.dx, pos.dy, ms));
    _touches[pointer] = t;
    _animator.press(key.index);
    _feedbackDown(key.def);
    if (_isFlickKey(key.def)) {
      t.flick = _flickGuide(key);
      popup.value = t.flick;
      return;
    }
    _showPreview(key);
    if (key.def.type == KeyType.backspace) {
      // With swipe-delete on, the first delete waits for touch-up (or the first repeat), so a
      // swipe that starts on backspace never removes a character first.
      if (!(_s.swipe.backspaceSwipeDelete && hooks.onBackspaceDrag != null)) {
        t.committed = true;
        _input.onBackspace();
      }
      _scheduleRepeat(t, 400);
    } else if (_hasLongPress(key)) {
      t.longPress = Timer(Duration(milliseconds: _s.typing.longPressDelayMs), () => _longPress(t));
    }
  }

  bool _isFlickKey(KeyDef d) => d.isCharacter && d.flick != null && d.flick!.isNotEmpty;

  static FlickDirection? _flickDirNamed(String name) => switch (name) {
    'up' => FlickDirection.up,
    'down' => FlickDirection.down,
    'left' => FlickDirection.left,
    'right' => FlickDirection.right,
    _ => null,
  };

  FlickGuideState _flickGuide(PlacedKey key) {
    final d = key.def;
    final labels = <FlickDirection, String>{FlickDirection.center: outputFor(d, shifted: false)};
    d.flick!.forEach((name, text) {
      final dir = _flickDirNamed(name);
      if (dir != null && text.isNotEmpty) labels[dir] = text;
    });
    return FlickGuideState(
      keyRect: key.rect.shift(Offset(0, keyAreaTop)),
      labels: labels,
      selected: FlickDirection.center,
    );
  }

  /// What a flick key types for the finger's current direction (the centre when that way is empty).
  String _flickText(_Touch t) => t.flick?.labels[t.flickDir] ?? outputFor(t.key.def, shifted: false);

  bool _hasLongPress(PlacedKey key) {
    final d = key.def;
    switch (d.type) {
      case KeyType.character:
      case KeyType.comma:
      case KeyType.period:
        return d.popup.isNotEmpty && !_input.currentField.isSensitive;
      case KeyType.space:
      case KeyType.globe:
        return true;
      case KeyType.enter:
        return _input.currentField.enterInsertsNewline;
      default:
        return false;
    }
  }

  void _rollover(_Touch t) {
    t.longPress?.cancel();
    t.repeat?.cancel();
    if (t.gesture) {
      _trail.clear();
      t.gesture = false;
      t.committed = true;
    }
    if (!t.committed && t.flick != null) {
      _input.onText(_flickText(t));
      t.committed = true;
    } else if (!t.committed && t.alternatives == null && !t.hookDrag) {
      _commitKey(t.key, t.points.isEmpty ? t.down : t.points.last.offset);
      t.committed = true;
    }
    _animator.release(t.key.index);
    popup.value = null;
  }

  void _move(int pointer, Offset pos, int ms) {
    final t = _touches[pointer];
    final laid = layout;
    if (t == null || laid == null) return;
    if (t.alternatives != null) {
      final alt = t.alternatives!;
      final idx = alt.layout.selectAt(pos + Offset(0, keyAreaTop));
      if (idx != alt.selected) {
        t.alternatives = alt.withSelected(idx);
        popup.value = t.alternatives;
        _haptic(HapticKind.repeatTick);
      }
      return;
    }
    final guide = t.flick;
    if (guide != null) {
      var dir = flickDirectionFor(pos - t.down, laid.keyWidth);
      if (!guide.labels.containsKey(dir)) dir = FlickDirection.center;
      if (dir != t.flickDir) {
        t.flickDir = dir;
        t.flick = guide.withSelected(dir);
        popup.value = t.flick;
        _haptic(HapticKind.repeatTick);
      }
      return;
    }
    if (t.gesture) {
      final tp = TouchPoint(pos.dx, pos.dy, ms);
      t.points.add(tp);
      _trail.add(tp);
      _maybePreview(t, ms);
      return;
    }
    t.points.add(TouchPoint(pos.dx, pos.dy, ms));
    final dx = pos.dx - t.down.dx;
    final distance = (pos - t.down).distance;

    // Wave 2 hooks: horizontal drags on space and backspace.
    if (_tryHookDrag(t, dx, distance)) return;
    if (t.committed) return;

    if (_canSwipe(t) && distance > 0.6 * laid.keyWidth) {
      _startGesture(t, ms);
      return;
    }
    // Sliding onto another character key switches the pressed key (no dead zones).
    if (t.key.def.isCharacter && t.alternatives == null) {
      final under = laid.hitTest(pos);
      if (under != null && under.index != t.key.index && under.def.isCharacter && under.rect.contains(pos)) {
        _animator
          ..release(t.key.index)
          ..press(under.index);
        t.key = under;
        t.longPress?.cancel();
        if (_hasLongPress(under)) {
          t.longPress = Timer(Duration(milliseconds: _s.typing.longPressDelayMs), () => _longPress(t));
        }
        _showPreview(under);
        _haptic(HapticKind.keyTap);
      }
    }
  }

  bool _tryHookDrag(_Touch t, double dx, double distance) {
    final type = t.key.def.type;
    void Function(double dx, {required bool done})? hook;
    if (type == KeyType.space && _s.swipe.spaceCursorControl) hook = hooks.onSpaceDrag;
    if (type == KeyType.backspace && _s.swipe.backspaceSwipeDelete) hook = hooks.onBackspaceDrag;
    if (hook == null) return false;
    if (!t.hookDrag) {
      if (dx.abs() < 14 || dx.abs() < (distance * 0.7)) return false;
      t.hookDrag = true;
      t.longPress?.cancel();
      t.repeat?.cancel();
      _animator.release(t.key.index);
    }
    hook(dx, done: false);
    return true;
  }

  bool _canSwipe(_Touch t) {
    if (!_s.swipe.enabled || _touches.length != 1) return false;
    if (!_input.currentField.allowsSwipe || _input.currentField.isRawKeyMode) return false;
    if (_input.page.value != KeyboardPage.letters) return false;
    // A panel's search box has the keys: no swipe typing into it.
    if (_input.redirect.value != null) return false;
    // Chinese and Japanese composers take keys one by one (Wave 4); flick keys never swipe.
    if (_input.composerActive || _isFlickKey(t.key.def)) return false;
    final out = t.key.def.output;
    return t.key.def.isCharacter && out != null && _letterRe.hasMatch(out);
  }

  void _startGesture(_Touch t, int ms) {
    t.gesture = true;
    t.longPress?.cancel();
    popup.value = null;
    _animator.release(t.key.index);
    _trail.begin(t.points.first);
    for (final p in t.points.skip(1)) {
      _trail.add(p);
    }
    _haptic(HapticKind.gestureStart);
  }

  void _maybePreview(_Touch t, int ms) {
    if (!_s.swipe.livePreview || _previewBusy || ms - t.lastPreviewMs < 50) return;
    t.lastPreviewMs = ms;
    _previewBusy = true;
    unawaited(
      _decoder
          .preview(_trail.path)
          .then<void>((word) {
            if (t.gesture && _touches.containsValue(t)) _trail.preview = word;
          })
          .catchError((Object e) => BooBoardLog.w('Swipe', 'preview failed', e.runtimeType))
          .whenComplete(() => _previewBusy = false),
    );
  }

  void _up(int pointer, Offset pos, int ms) {
    final t = _touches.remove(pointer);
    if (t == null) return;
    t.longPress?.cancel();
    t.repeat?.cancel();
    _animator.release(t.key.index);
    popup.value = null;

    if (t.hookDrag) {
      final hook = t.key.def.type == KeyType.space ? hooks.onSpaceDrag : hooks.onBackspaceDrag;
      hook?.call(pos.dx - t.down.dx, done: true);
      return;
    }
    final alt = t.alternatives;
    if (alt != null) {
      _input.onText(alt.items[alt.selected]);
      return;
    }
    if (t.flick != null) {
      if (!t.committed) _input.onText(_flickText(t));
      return;
    }
    if (t.gesture) {
      _endGesture(t, pos, ms);
      return;
    }
    if (t.committed) return;
    _commitKey(t.key, pos, ms: ms);
  }

  void _endGesture(_Touch t, Offset pos, int ms) {
    t.points.add(TouchPoint(pos.dx, pos.dy, ms));
    _trail.add(t.points.last);
    _trail.end();
    final path = GesturePath(List.unmodifiable(t.points));
    if (t.points.length < 3) {
      _trail.clear();
      return;
    }
    unawaited(
      _input
          .commitSwipe(path)
          .then<void>((_) {
            _haptic(HapticKind.gestureCommit);
            _trail.preview = null;
          })
          .catchError((Object e) => BooBoardLog.w('Swipe', 'commit failed', e.runtimeType)),
    );
  }

  void _cancel(int pointer) {
    final t = _touches.remove(pointer);
    if (t == null) return;
    t.longPress?.cancel();
    t.repeat?.cancel();
    _animator.release(t.key.index);
    popup.value = null;
    if (t.gesture) _trail.clear();
    if (t.hookDrag) {
      final hook = t.key.def.type == KeyType.space ? hooks.onSpaceDrag : hooks.onBackspaceDrag;
      hook?.call(0, done: true);
    }
  }

  /// Aborts every active touch without committing (page or field changed under the finger).
  void cancelAll() {
    for (final p in _touches.keys.toList()) {
      _cancel(p);
    }
    _animator.releaseAll();
    popup.value = null;
  }

  // ---- Previews, long press and repeat ----------------------------------

  void _showPreview(PlacedKey key) {
    final d = key.def;
    final s = _s;
    if (!s.typing.keyPopups || _input.currentField.isSensitive) return;
    if (d.type != KeyType.character && d.type != KeyType.comma && d.type != KeyType.period) return;
    final label = d.type == KeyType.character ? outputFor(d, shifted: _shifted) : (d.label ?? d.output ?? '');
    if (label.isEmpty) return;
    popup.value = KeyPreviewState(keyRect: key.rect.shift(Offset(0, keyAreaTop)), label: label);
  }

  void _longPress(_Touch t) {
    if (_touches[t.pointer] != t || t.gesture || t.committed) return;
    final d = t.key.def;
    switch (d.type) {
      case KeyType.space:
        t.committed = true;
        _haptic(HapticKind.keyLongPress);
        final picker = hooks.onLanguagePicker;
        if (picker != null) {
          picker();
        } else {
          _fire(() => _host.showInputMethodPicker());
        }
      case KeyType.globe:
        t.committed = true;
        _haptic(HapticKind.keyLongPress);
        _fire(() => _host.showInputMethodPicker());
      case KeyType.enter:
        t.committed = true;
        _haptic(HapticKind.keyLongPress);
        _input.onEnterLongPress();
      case KeyType.character:
      case KeyType.comma:
      case KeyType.period:
        if (d.popup.isEmpty) return;
        final shifted = _shifted;
        final items = [for (final p in d.popup) shifted ? applyShift(p) : p];
        final keyRect = t.key.rect.shift(Offset(0, keyAreaTop));
        final layout = AlternativesLayout.compute(keyRect: keyRect, count: items.length, view: viewSize);
        t.alternatives = AlternativesState(keyRect: keyRect, items: items, layout: layout, selected: 0);
        popup.value = t.alternatives;
        _haptic(HapticKind.keyLongPress);
      default:
        break;
    }
  }

  void _scheduleRepeat(_Touch t, int delayMs) {
    t.heldMs = delayMs;
    t.repeat = Timer(Duration(milliseconds: delayMs), () => _repeatTick(t));
  }

  void _repeatTick(_Touch t) {
    if (_touches[t.pointer] != t || t.hookDrag) return;
    t.committed = true;
    final wordMode = t.heldMs >= 2000;
    if (wordMode) {
      _input.deleteWordBackward();
    } else {
      _input.onBackspace();
    }
    t.repeats++;
    // Accelerate from 60 ms to 25 ms over the first two seconds; then one word per 140 ms.
    final progress = ((t.heldMs - 400) / 1600).clamp(0.0, 1.0);
    final interval = wordMode ? 140 : (60 - 35 * progress).round();
    if (interval >= 50 || t.repeats % 3 == 0) _haptic(HapticKind.repeatTick);
    t.heldMs += interval;
    t.repeat = Timer(Duration(milliseconds: interval), () => _repeatTick(t));
  }

  // ---- Key actions ------------------------------------------------------

  /// Runs the key's action (touch up, rollover, or an accessibility tap).
  void _commitKey(PlacedKey key, Offset pos, {int ms = 0}) {
    final d = key.def;
    switch (d.type) {
      case KeyType.character:
      case KeyType.comma:
      case KeyType.period:
        final text = d.type == KeyType.character ? outputFor(d, shifted: _shifted) : (d.output ?? d.label ?? '');
        _input.onText(text, point: TouchPoint(pos.dx, pos.dy, ms));
      case KeyType.space:
        _input.onSpace();
      case KeyType.shift:
        _input.onShiftTap();
      case KeyType.backspace:
        _input.onBackspace();
      case KeyType.enter:
        _input.onEnter();
      case KeyType.symbols:
        _input.setPage(KeyboardPage.symbols);
      case KeyType.moreSymbols:
        _input.setPage(KeyboardPage.symbols2);
      case KeyType.alphabet:
        _input.setPage(KeyboardPage.letters);
      case KeyType.numbers:
        _input.setPage(KeyboardPage.numpad);
      case KeyType.globe:
        final next = hooks.onLanguageSwitch;
        if (next != null) {
          next();
        } else {
          _fire(() => _host.switchToNextInputMethod(false).then<void>((_) {}));
        }
      case KeyType.emoji:
        hooks.onEmoji?.call();
      case KeyType.voice:
        hooks.onVoice?.call();
      case KeyType.clipboard:
        hooks.onClipboard?.call();
      case KeyType.settings:
        _fire(() => _host.openSettings(null));
      case KeyType.tab:
        _input.sendTab();
      case KeyType.cursorLeft:
        _input.moveCursor(-1);
      case KeyType.cursorRight:
        _input.moveCursor(1);
      case KeyType.custom:
        // Wave 4: composer keys (12-key dakuten toggle, small kana, ...).
        _input.onCustomKey(d.code ?? '');
    }
  }

  /// TalkBack double-tap on a key.
  void activateKey(PlacedKey key) {
    _feedbackDown(key.def);
    if (key.def.type == KeyType.backspace) {
      _input.onBackspace();
    } else {
      _commitKey(key, key.rect.center);
    }
  }

  void dispose() {
    cancelAll();
    popup.dispose();
  }
}
