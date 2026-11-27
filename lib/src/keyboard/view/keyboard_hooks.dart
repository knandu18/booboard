// SPDX-License-Identifier: GPL-3.0-or-later
//
// Extension points for Wave 2 (panels, space-bar cursor control, swipe to
// delete words). Every hook is optional; the keyboard works without them.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;

/// One entry of the small tools menu (long-press the Settings gear).
@immutable
class ToolMenuItem {
  const ToolMenuItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class KeyboardHooks {
  const KeyboardHooks({
    this.onEmoji,
    this.onClipboard,
    this.onEditing,
    this.onModes,
    this.onTheme,
    this.onVoice,
    this.voiceAvailable,
    this.onTranslate,
    this.onImages,
    this.onToolsMenu,
    this.onLanguageSwitch,
    this.onLanguagePicker,
    this.onSpaceDrag,
    this.onBackspaceDrag,
  });

  /// Toolbar and key buttons. Text editing and keyboard modes are not in the toolbar (2026-11-26): they are
  /// in the tools menu (long-press the Settings gear), when set.
  final VoidCallback? onEmoji;
  final VoidCallback? onClipboard;

  /// Text-editing panel (Wave 2-D).
  final VoidCallback? onEditing;

  /// One-handed / floating / resize bar (Wave 2-E).
  final VoidCallback? onModes;
  final VoidCallback? onTheme;
  final VoidCallback? onVoice;

  /// Whether the toolbar mic shows (voice typing works in English only: an English voice pack is installed
  /// and the keyboard language is English). Null means always, when [onVoice] is set.
  final ValueListenable<bool>? voiceAvailable;

  /// Translate panel (Wave 3-T). The toolbar button only appears when set.
  final VoidCallback? onTranslate;

  /// Images (offline image creation; a coming-soon panel until the model ships). The toolbar button only
  /// appears when set.
  final VoidCallback? onImages;

  /// Shows the tools menu with [items] (long-press the Settings gear). Without it, long-press does nothing.
  final void Function(List<ToolMenuItem> items)? onToolsMenu;

  /// Globe key tap: next enabled language. Defaults to `KeyboardSession.switchLanguage` when more
  /// than one language is enabled; otherwise the globe key switches to the next keyboard app.
  final VoidCallback? onLanguageSwitch;

  /// Space-bar long press (Wave 3-A: language picker panel). Without it, the system keyboard picker.
  final VoidCallback? onLanguagePicker;

  /// A finger that landed on the space bar moved horizontally. [dx] is the total
  /// horizontal travel since touch-down in dp; [done] is true when the finger lifts.
  /// Only called when `SwipeSettings.spaceCursorControl` is on. While the hook is
  /// active the space key does not type a space.
  final void Function(double dx, {required bool done})? onSpaceDrag;

  /// Same for backspace (`SwipeSettings.backspaceSwipeDelete`). While active the
  /// key stops repeating. Wave 2 selects words while [done] is false and deletes
  /// them on release.
  final void Function(double dx, {required bool done})? onBackspaceDrag;

  /// Combines hooks from several features: for each callback the first non-null one wins.
  static KeyboardHooks merge(Iterable<KeyboardHooks> all) {
    T? first<T>(T? Function(KeyboardHooks h) pick) {
      for (final h in all) {
        final v = pick(h);
        if (v != null) return v;
      }
      return null;
    }

    return KeyboardHooks(
      onEmoji: first((h) => h.onEmoji),
      onClipboard: first((h) => h.onClipboard),
      onEditing: first((h) => h.onEditing),
      onModes: first((h) => h.onModes),
      onTheme: first((h) => h.onTheme),
      onVoice: first((h) => h.onVoice),
      voiceAvailable: first((h) => h.voiceAvailable),
      onTranslate: first((h) => h.onTranslate),
      onImages: first((h) => h.onImages),
      onToolsMenu: first((h) => h.onToolsMenu),
      onLanguageSwitch: first((h) => h.onLanguageSwitch),
      onLanguagePicker: first((h) => h.onLanguagePicker),
      onSpaceDrag: first((h) => h.onSpaceDrag),
      onBackspaceDrag: first((h) => h.onBackspaceDrag),
    );
  }
}
