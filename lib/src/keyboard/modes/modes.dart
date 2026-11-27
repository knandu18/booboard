// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-E. Keyboard modes: one-handed, floating, height handle, the modes bar, space-bar
// cursor control, backspace swipe-to-delete. keyboard_main.dart calls createModesFeature(); keep
// that signature.
import 'dart:async';

import '../../bridge/messages.g.dart';
import '../../settings/booboard_settings.dart';
import '../keyboard_session.dart';
import '../panels/keyboard_panel.dart';
import 'backspace_swipe.dart';
import 'modes_bar.dart';
import 'modes_controller.dart';
import 'modes_frame.dart';
import 'space_cursor_drag.dart';

/// The modes feature. [clockMs] is for tests; the keyboard uses the monotonic clock.
KeyboardFeature createModesFeature({int Function()? clockMs}) => _ModesFeature(clockMs: clockMs);

class _ModesFeature extends KeyboardFeature {
  _ModesFeature({this.clockMs});

  final int Function()? clockMs;
  final ModesController _controller = ModesController();
  late final ModesFrame _frame = ModesFrame(_controller);

  KeyboardSession? _session;
  SpaceCursorDrag? _space;
  BackspaceSwipe? _backspace;

  @override
  KeyboardHooks attach(KeyboardSession session) {
    _session = session;
    _controller.attach(session);
    _space = SpaceCursorDrag(
      move: (steps) => session.input.moveCursor(steps),
      tick: () => _haptic(HapticKind.repeatTick),
      clockMs: clockMs,
    );
    _backspace = BackspaceSwipe(
      input: session.input,
      showChip: session.showChip,
      removeChip: session.removeChip,
      onWordStep: () => _haptic(HapticKind.repeatTick),
    );
    return KeyboardHooks(
      onModes: _openBar,
      onSpaceDrag: (dx, {required done}) => _space?.drag(dx, done: done),
      onBackspaceDrag: (dx, {required done}) => _backspace?.drag(dx, done: done),
    );
  }

  @override
  KeyboardFrame? get frame => _frame;

  @override
  void detach() {
    _backspace?.dispose();
    _controller.dispose();
    _session = null;
  }

  void _openBar() {
    _session?.openPanel(ModesBarPanel(_onBarAction));
  }

  void _onBarAction(ModesBarAction action) {
    final session = _session;
    if (session == null) return;
    session.closePanel();
    switch (action) {
      case ModesBarAction.oneHandedLeft:
        _controller.updateModes(
          (m) => m.copyWith(
            oneHanded: m.oneHanded == OneHandedMode.left ? OneHandedMode.off : OneHandedMode.left,
            floating: false,
          ),
        );
      case ModesBarAction.oneHandedRight:
        _controller.updateModes(
          (m) => m.copyWith(
            oneHanded: m.oneHanded == OneHandedMode.right ? OneHandedMode.off : OneHandedMode.right,
            floating: false,
          ),
        );
      case ModesBarAction.floating:
        _controller.updateModes(
          (m) => m.floating ? m.copyWith(floating: false) : m.copyWith(floating: true, oneHanded: OneHandedMode.off),
        );
      case ModesBarAction.resize:
        _controller.startResize();
      case ModesBarAction.close:
        break;
    }
  }

  void _haptic(HapticKind kind) {
    final session = _session;
    if (session == null || !session.services.settings.value.feedback.haptics) return;
    try {
      unawaited(session.services.host.performHaptic(kind).catchError((Object _) {}));
    } on Object {
      // Haptics are best effort.
    }
  }
}
