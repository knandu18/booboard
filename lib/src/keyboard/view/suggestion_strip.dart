// SPDX-License-Identifier: GPL-3.0-or-later
//
// The 44 dp strip above the keys: three suggestion slots (best in the centre),
// or a toolbar of icon buttons when there is nothing to suggest. Private fields (passwords, fields that ask
// for no suggestions) show the toolbar with every tool working (2026-11-26, no "Private field" chip).
// A button at the leading edge swaps
// suggestions for the toolbar at any time; typing brings the suggestions back.
// Toolbar (2026-11-26): emoji, clipboard, mic, translate, images, themes, settings. Text editing and
// keyboard modes moved to the tools menu: long-press the Settings gear.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../core/input_field_info.dart';
import '../../engine/contracts.dart';
import '../../theme/keyboard_theme_data.dart';
import '../input/input_controller.dart';
import '../panels/keyboard_panel.dart' show StripChip;
import 'keyboard_hooks.dart';
import 'keyboard_metrics.dart';

/// Three slots: [left, centre, right]. Null entries are empty.
List<Suggestion?> arrangeSlots(SuggestionBarState bar) {
  final items = <Suggestion>[];
  final seen = <String>{};
  void add(Suggestion s) {
    if (seen.add(s.text)) items.add(s);
  }

  final auto = bar.autoCorrection;
  if (auto != null) add(auto);
  bar.suggestions.forEach(add);
  final top = items.take(3).toList();
  return [top.length > 1 ? top[1] : null, top.isNotEmpty ? top[0] : null, top.length > 2 ? top[2] : null];
}

class SuggestionStrip extends StatefulWidget {
  const SuggestionStrip({
    super.key,
    required this.theme,
    required this.bar,
    required this.field,
    required this.suggestionsEnabled,
    required this.incognito,
    required this.onPick,
    required this.onOpenSettings,
    this.hooks = const KeyboardHooks(),
    this.chips,
  });

  final KeyboardThemeData theme;
  final ValueListenable<SuggestionBarState> bar;
  final InputFieldInfo field;

  /// `TypingSettings.showSuggestions`.
  final bool suggestionsEnabled;
  final bool incognito;
  final ValueChanged<Suggestion> onPick;
  final VoidCallback onOpenSettings;
  final KeyboardHooks hooks;

  /// Chips shown instead of the toolbar when nothing is suggested (never in sensitive fields).
  final ValueListenable<List<StripChip>>? chips;

  /// Width of the toolbar toggle at the leading edge.
  static const double toggleWidth = 40;

  @override
  State<SuggestionStrip> createState() => _SuggestionStripState();
}

class _SuggestionStripState extends State<SuggestionStrip> {
  /// The user asked for the toolbar with the leading button; cleared when typing starts.
  bool _toolbarForced = false;

  KeyboardThemeData get theme => widget.theme;
  KeyboardHooks get hooks => widget.hooks;
  ValueListenable<SuggestionBarState> get bar => widget.bar;
  ValueListenable<List<StripChip>>? get chips => widget.chips;

  @override
  void initState() {
    super.initState();
    bar.addListener(_onBar);
  }

  @override
  void didUpdateWidget(SuggestionStrip old) {
    super.didUpdateWidget(old);
    if (old.bar != bar) {
      old.bar.removeListener(_onBar);
      bar.addListener(_onBar);
    }
    if (old.field != widget.field) _toolbarForced = false;
  }

  @override
  void dispose() {
    bar.removeListener(_onBar);
    super.dispose();
  }

  void _onBar() {
    final v = bar.value;
    if (_toolbarForced && (v.isComposing || v.fromSwipe)) setState(() => _toolbarForced = false);
  }

  TextStyle _style(Color color, {bool bold = false}) => TextStyle(
    color: color,
    fontSize: 17 * theme.labelScale,
    fontFamily: theme.fontFamily,
    fontWeight: bold ? FontWeight.w600 : theme.labelWeight,
    fontVariations: theme.labelFontVariations,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    // Private fields: the toolbar as usual (no suggestions there, so no toggle).
    if (field.isSensitive) return SizedBox(height: KeyboardMetrics.stripHeight, child: _toolbar());
    final Widget content;
    if (widget.suggestionsEnabled && field.allowsSuggestions) {
      final c = chips;
      content = ListenableBuilder(
        listenable: c == null ? bar : Listenable.merge([bar, c]),
        builder: (context, _) {
          if (_toolbarForced) return _withToggle(_toolbar(), showingToolbar: true);
          final state = bar.value;
          // Chips (recent copy, undo) beat next-word predictions, never a word being typed or swiped.
          final typing = state.isComposing || state.fromSwipe || state.autoCorrection != null;
          if (!typing && c != null && c.value.isNotEmpty) {
            return _withToggle(_chipRow(c.value.take(3).toList()), showingToolbar: false);
          }
          final slots = arrangeSlots(state);
          if (slots.every((s) => s == null)) return _withToggle(_toolbar(), showingToolbar: true, canReturn: false);
          return _withToggle(_slots(state, slots), showingToolbar: false);
        },
      );
    } else {
      content = _withToggle(_toolbarOrChips(), showingToolbar: true, canReturn: false);
    }
    return SizedBox(height: KeyboardMetrics.stripHeight, child: content);
  }

  /// [child] after the leading toggle. While suggestions or chips show, the toggle opens the
  /// toolbar; on a toolbar the user opened it goes back. In incognito it also shows the eye icon.
  Widget _withToggle(Widget child, {required bool showingToolbar, bool canReturn = true}) {
    final incognito = widget.incognito;
    final VoidCallback? onTap;
    final IconData icon;
    final String label;
    if (!showingToolbar) {
      onTap = () => setState(() => _toolbarForced = true);
      icon = incognito ? Icons.visibility_off_outlined : Icons.apps;
      label = incognito ? 'Incognito mode on. Show toolbar' : 'Show toolbar';
    } else if (canReturn) {
      onTap = () => setState(() => _toolbarForced = false);
      icon = Icons.chevron_left;
      label = 'Show suggestions';
    } else {
      if (!incognito) return child;
      onTap = null;
      icon = Icons.visibility_off_outlined;
      label = 'Incognito mode on';
    }
    return Row(
      children: [
        SizedBox(
          width: SuggestionStrip.toggleWidth,
          child: Semantics(
            button: onTap != null,
            label: label,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Center(child: Icon(icon, size: 20, color: theme.toolbarIcon)),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _slots(SuggestionBarState state, List<Suggestion?> slots) {
    final autoText = state.autoCorrection?.text;
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) _divider(),
          Expanded(
            child: _slot(state, slots[i], isCentre: i == 1, autoText: autoText),
          ),
        ],
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 20, color: theme.suggestionDivider);

  Widget _slot(SuggestionBarState state, Suggestion? s, {required bool isCentre, required String? autoText}) {
    if (s == null) return const SizedBox.shrink();
    final highlighted = isCentre && autoText != null && s.text == autoText;
    var label = s.display ?? s.text;
    if (s.kind == SuggestionKind.typed && state.typedWordUnknown) label = '“$label”';
    return Semantics(
      button: true,
      label: 'Suggestion $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onPick(s),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: highlighted ? theme.suggestionHighlightFill : const Color(0x00000000),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _style(highlighted ? theme.suggestionHighlightText : theme.suggestionText, bold: isCentre),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbarOrChips() {
    final c = chips;
    if (c == null) return _toolbar();
    return ValueListenableBuilder<List<StripChip>>(
      valueListenable: c,
      builder: (context, list, _) => list.isEmpty ? _toolbar() : _chipRow(list.take(3).toList()),
    );
  }

  Widget _chipRow(List<StripChip> list) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (final chip in list)
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              button: true,
              label: chip.semanticLabel ?? chip.label,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: chip.onTap,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.suggestionHighlightFill,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (chip.icon != null) ...[
                          Icon(chip.icon, size: 16, color: theme.suggestionHighlightText),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            chip.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _style(theme.suggestionHighlightText).copyWith(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _toolbar() {
    final available = hooks.voiceAvailable;
    if (available == null) return _toolbarRow(showMic: true);
    return ValueListenableBuilder<bool>(
      valueListenable: available,
      builder: (context, showMic, _) => _toolbarRow(showMic: showMic),
    );
  }

  /// Text editing, keyboard modes and settings: shown when the Settings gear is long-pressed.
  List<ToolMenuItem> _menuItems() => [
    if (hooks.onEditing case final onEditing?)
      ToolMenuItem(icon: Icons.text_fields, label: 'Text editing', onTap: onEditing),
    if (hooks.onModes case final onModes?)
      ToolMenuItem(icon: Icons.open_in_full, label: 'One-handed and floating', onTap: onModes),
    ToolMenuItem(icon: Icons.settings_outlined, label: 'BooBoard settings', onTap: widget.onOpenSettings),
  ];

  Widget _toolbarRow({required bool showMic}) {
    Widget button(
      IconData icon,
      String label,
      VoidCallback? onTap, {
      VoidCallback? onLongPress,
      String? longPressHint,
      bool dot = false,
    }) => Expanded(
      child: Semantics(
        button: true,
        label: label,
        onLongPressHint: longPressHint,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: onTap == null ? theme.toolbarIcon.withValues(alpha: 0.5) : theme.toolbarIcon,
                ),
                if (dot)
                  Positioned(
                    top: -1,
                    right: -3,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: theme.trailStart),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final showMenu = hooks.onToolsMenu;
    return Row(
      children: [
        button(Icons.emoji_emotions_outlined, 'Emoji', hooks.onEmoji),
        button(Icons.content_paste, 'Clipboard', hooks.onClipboard),
        if (hooks.onVoice != null && showMic) button(Icons.mic_none, 'Voice typing', hooks.onVoice),
        if (hooks.onTranslate != null) button(Icons.translate, 'Translate', hooks.onTranslate),
        if (hooks.onImages != null) button(Icons.image_outlined, 'Create images', hooks.onImages, dot: true),
        button(Icons.palette_outlined, 'Themes', hooks.onTheme),
        button(
          Icons.settings_outlined,
          'Settings',
          widget.onOpenSettings,
          onLongPress: showMenu == null ? null : () => showMenu(_menuItems()),
          longPressHint: showMenu == null ? null : 'More tools',
        ),
      ],
    );
  }
}
