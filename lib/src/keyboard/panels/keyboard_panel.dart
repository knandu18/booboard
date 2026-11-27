// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (orchestrator-owned): how Wave 2 features plug into the keyboard
// without editing the keyboard view.
//
//   * KeyboardPanel  - a view shown in place of the keys and/or the strip
//                      (emoji, clipboard, editing, emoji search).
//   * StripChip      - a chip shown in the suggestion strip when nothing is
//                      being suggested (recent copy, undo delete, cut/copy).
//   * KeyboardFrame  - wraps the whole keyboard and decides the IME window
//                      layout (one-handed, floating, height handle, tablets).
//   * KeyboardFeature- a bundle of the above plus hooks, attached once per
//                      keyboard session (see keyboard_main.dart).
import 'package:flutter/widgets.dart';

import '../../bridge/messages.g.dart';
import '../../settings/booboard_settings.dart';
import '../../theme/keyboard_theme_data.dart';
import '../input/input_controller.dart';
import '../keyboard_session.dart';
import '../view/keyboard_hooks.dart';

export '../input/input_controller.dart' show KeyRedirect, SuggestionDecorator, SuggestionQuery;
export '../view/keyboard_hooks.dart' show KeyboardHooks;

// ---------------------------------------------------------------------------
// Panels
// ---------------------------------------------------------------------------

/// Which part of the keyboard a panel replaces. The keyboard never changes height for a panel.
enum PanelPlacement {
  /// Strip and key rows: the panel draws its own top bar (emoji, clipboard, editing).
  full,

  /// Key rows only; the suggestion strip stays.
  keys,

  /// Strip only; the keys stay and type into the panel through [KeyboardPanel.keyRedirect]
  /// (emoji search uses the keyboard's own keys).
  strip,
}

/// A panel instance. Create a new one each time it opens, or reuse one; [onClosed] is called
/// every time it leaves the screen.
abstract class KeyboardPanel {
  /// Stable id, for example 'emoji', 'emoji_search', 'clipboard', 'editing'.
  String get id;

  PanelPlacement get placement;

  /// For [PanelPlacement.strip] only: extra height (dp) the panel takes from the key rows, so it can show a
  /// second row (the translator's text box). The keyboard window keeps its size; the keys get shorter.
  double get extraStripHeight => 0;

  /// For [PanelPlacement.strip] only: receives the typed keys while the panel is open.
  KeyRedirect? get keyRedirect => null;

  /// Builds the panel. It fills exactly [PanelContext.size].
  Widget build(BuildContext context, PanelContext panel);

  /// The panel left the screen: [KeyboardSession.closePanel], another panel opened, a new field
  /// started, a sensitive field got focus, or the keyboard was hidden.
  void onClosed() {}
}

class PanelContext {
  const PanelContext({required this.session, required this.theme, required this.settings, required this.size});

  final KeyboardSession session;
  final KeyboardThemeData theme;
  final BooBoardSettings settings;

  /// The area the panel fills, in dp.
  final Size size;

  /// Typing API: [InputController.insertText], [InputController.finishComposing],
  /// [InputController.editor] and [InputController.resyncAfterExternalEdit].
  InputController get input => session.input;

  void open(KeyboardPanel panel) => session.openPanel(panel);
  void close() => session.closePanel();
}

// ---------------------------------------------------------------------------
// Strip chips
// ---------------------------------------------------------------------------

/// A chip in the suggestion strip. Chips show instead of the toolbar while nothing is being
/// suggested; higher [priority] first, at most 3. They never show in sensitive fields.
@immutable
class StripChip {
  const StripChip({
    required this.id,
    required this.label,
    required this.onTap,
    this.icon,
    this.semanticLabel,
    this.priority = 0,
    this.expiresAfter,
  });

  /// Replaces an existing chip with the same id ('clipboard.recent', 'editing.undo_delete', ...).
  final String id;

  /// Short visible text. For copied text use a masked preview, never more than ~24 characters.
  final String label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback onTap;
  final int priority;

  /// Removed automatically after this long (for example 60 s for a recent copy).
  final Duration? expiresAfter;
}

// ---------------------------------------------------------------------------
// Frame (modes)
// ---------------------------------------------------------------------------

/// What a [KeyboardFrame] knows when it lays out the keyboard.
@immutable
class FrameInfo {
  const FrameInfo({
    required this.settings,
    required this.theme,
    required this.screenSize,
    required this.landscape,
    required this.bottomInset,
    required this.contentHeight,
  });

  final BooBoardSettings settings;
  final KeyboardThemeData theme;

  /// The IME window's width and the screen height, in dp.
  final Size screenSize;
  final bool landscape;

  /// Navigation-bar inset Flutter applies at the bottom (MediaQuery.viewPadding.bottom).
  final double bottomInset;

  /// Height of strip plus key rows from `KeyboardMetrics` (already includes the height scale).
  final double contentHeight;
}

/// What the frame returns: the window layout for Kotlin plus the widget tree.
@immutable
class FrameResult {
  const FrameResult({required this.layout, required this.child});

  /// Sent to `ImeHostApi.setWindowLayout` whenever it changes. Docked: heightDp is the total
  /// window height including [FrameInfo.bottomInset]. Floating: see `WindowLayoutMessage`.
  final WindowLayoutMessage layout;

  /// The whole keyboard area. [KeyboardFrame.build]'s `keyboard` argument must appear in it once.
  final Widget child;
}

/// Wraps the keyboard (docked full width by default). Implemented by Wave 2-E.
abstract class KeyboardFrame {
  /// [keyboard] is the strip plus keys (or the open panel), sized by its parent: give it a
  /// bounded width and exactly [FrameInfo.contentHeight] of height (or a resized height when the
  /// user changes it). [background] paints the theme background; place it behind the keyboard
  /// area. Called on every keyboard rebuild: keep it cheap.
  FrameResult build(BuildContext context, FrameInfo info, {required Widget keyboard, required Widget background});
}

// ---------------------------------------------------------------------------
// Features
// ---------------------------------------------------------------------------

/// A feature module (emoji/clipboard/editing, modes, shortcuts). [attach] runs once per keyboard
/// session, after the session is created; [detach] when it is disposed.
abstract class KeyboardFeature {
  /// Register decorators, listeners and chips here. Return the hooks this feature provides; they
  /// are merged with other features' hooks (first non-null callback wins, in feature order).
  KeyboardHooks attach(KeyboardSession session);

  /// The frame, if this feature provides one (only modes do). At most one feature may.
  KeyboardFrame? get frame => null;

  void detach() {}
}
