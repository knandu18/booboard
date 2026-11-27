// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. The text-editing panel (PanelPlacement.full). Arrow keys are key events (repeating
// on hold), Select turns the arrows into Shift+arrow selection, Select all / Cut / Copy / Paste use the
// editor's context-menu actions, and Undo / Redo send Ctrl+Z and Ctrl+Shift+Z. Every action finishes the
// composing word first and resyncs the controller's mirror of the text afterwards.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../bridge/messages.g.dart';
import '../../core/input_field_info.dart';
import '../../keyboard/keyboard_session.dart';
import '../../theme/keyboard_theme_data.dart';
import '../../keyboard/panels/keyboard_panel.dart';
import '../../keyboard/view/keyboard_metrics.dart';
import '../shared/panel_style.dart';
import '../shared/directional_icon.dart';

class EditingPanel extends KeyboardPanel {
  EditingPanel(this.session);

  final KeyboardSession session;

  @override
  String get id => 'editing';

  @override
  PanelPlacement get placement => PanelPlacement.full;

  @override
  Widget build(BuildContext context, PanelContext panel) => EditingPanelView(session: session, panel: panel);
}

class EditingPanelView extends StatefulWidget {
  const EditingPanelView({super.key, required this.session, required this.panel});

  final KeyboardSession session;
  final PanelContext panel;

  @override
  State<EditingPanelView> createState() => _EditingPanelViewState();
}

class _EditingPanelViewState extends State<EditingPanelView> {
  /// While on, the arrows and Home / End extend the selection (Shift + key).
  bool _selecting = false;

  /// Sends one key press (down and up). The composing word is kept as typed first.
  void _key(int keyCode, {int metaState = 0}) {
    final input = widget.session.input;
    input.finishComposing();
    unawaited(input.editor.sendDownUpKeyEvent(keyCode, metaState: metaState).catchError((Object _) => false));
    input.resyncAfterExternalEdit();
  }

  void _menu(ContextMenuAction action) {
    final input = widget.session.input;
    input.finishComposing();
    unawaited(input.editor.performContextMenuAction(action).catchError((Object _) => false));
    input.resyncAfterExternalEdit();
  }

  int get _shift => _selecting ? AndroidMetaState.shiftOn : 0;

  void _arrow(int keyCode) => _key(keyCode, metaState: _shift);

  @override
  Widget build(BuildContext context) {
    final panel = widget.panel;
    final theme = panel.theme;
    final style = PanelStyle(theme);
    final fill = theme.functionKey.fill;
    final pressed = theme.functionKey.pressedFill;
    final label = theme.functionKey.label;
    const gap = 6.0;
    return SizedBox(
      width: panel.size.width,
      height: panel.size.height,
      child: Column(
        children: [
          // Top bar: back to the letters, and the title.
          SizedBox(
            height: KeyboardMetrics.stripHeight,
            child: Row(
              children: [
                PanelButton(
                  semanticsLabel: 'Back to letters',
                  width: 64,
                  height: KeyboardMetrics.stripHeight,
                  fill: theme.background,
                  pressedFill: theme.suggestionHighlightFill,
                  radius: BorderRadius.zero,
                  onTap: widget.session.closePanel,
                  child: Text('ABC', style: style.text(size: 14, color: theme.suggestionText)),
                ),
                Expanded(
                  child: Text('Edit text', textAlign: TextAlign.center, style: style.hint(size: 13)),
                ),
                const SizedBox(width: 64),
              ],
            ),
          ),
          // Row of actions.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: PanelButton(
                      semanticsLabel: _selecting ? 'Stop selecting' : 'Select with arrows',
                      height: double.infinity,
                      fill: fill,
                      pressedFill: pressed,
                      selected: _selecting,
                      radius: style.radius(48),
                      onTap: () => setState(() => _selecting = !_selecting),
                      child: _caption('Select', style, _selecting ? theme.suggestionHighlightText : label),
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _actionButton(
                      theme,
                      style,
                      'Select all',
                      Icons.select_all,
                      () => _menu(ContextMenuAction.selectAll),
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _actionButton(theme, style, 'Cut', Icons.content_cut, () => _menu(ContextMenuAction.cut)),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _actionButton(theme, style, 'Copy', Icons.content_copy, () => _menu(ContextMenuAction.copy)),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _actionButton(
                      theme,
                      style,
                      'Paste',
                      Icons.content_paste,
                      () => _menu(ContextMenuAction.paste),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The cluster: Home and End on the left, the arrows in the middle, Undo and Redo on the right.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _actionButton(
                            theme,
                            style,
                            'Start of line',
                            Icons.keyboard_double_arrow_left,
                            () => _key(AndroidKeyCode.moveHome, metaState: _shift),
                          ),
                        ),
                        const SizedBox(height: gap),
                        Expanded(
                          child: _actionButton(
                            theme,
                            style,
                            'End of line',
                            Icons.keyboard_double_arrow_right,
                            () => _key(AndroidKeyCode.moveEnd, metaState: _shift),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: gap),
                  // A directional pad: the arrows stay in their physical places in right-to-left text.
                  Expanded(
                    flex: 2,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Column(
                        children: [
                          Expanded(
                            child: _arrowButton(theme, 'Move up', Icons.keyboard_arrow_up, AndroidKeyCode.dpadUp),
                          ),
                          const SizedBox(height: gap),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _arrowButton(
                                    theme,
                                    'Move left',
                                    Icons.keyboard_arrow_left,
                                    AndroidKeyCode.dpadLeft,
                                  ),
                                ),
                                const SizedBox(width: gap),
                                Expanded(
                                  child: _arrowButton(
                                    theme,
                                    'Move down',
                                    Icons.keyboard_arrow_down,
                                    AndroidKeyCode.dpadDown,
                                  ),
                                ),
                                const SizedBox(width: gap),
                                Expanded(
                                  child: _arrowButton(
                                    theme,
                                    'Move right',
                                    Icons.keyboard_arrow_right,
                                    AndroidKeyCode.dpadRight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _actionButton(
                            theme,
                            style,
                            'Undo',
                            Icons.undo,
                            () => _key(AndroidKeyCode.z, metaState: AndroidMetaState.ctrlOn),
                          ),
                        ),
                        const SizedBox(height: gap),
                        Expanded(
                          child: _actionButton(
                            theme,
                            style,
                            'Redo',
                            Icons.redo,
                            () => _key(AndroidKeyCode.z, metaState: AndroidMetaState.ctrlOn | AndroidMetaState.shiftOn),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// An arrow key: repeats while held.
  Widget _arrowButton(KeyboardThemeData theme, String label, IconData icon, int keyCode) {
    return PanelButton(
      semanticsLabel: label,
      height: double.infinity,
      fill: theme.functionKey.fill,
      pressedFill: theme.functionKey.pressedFill,
      radius: PanelStyle(theme).radius(56),
      repeat: true,
      onTap: () => _arrow(keyCode),
      child: Icon(icon, size: 28, color: theme.functionKey.label),
    );
  }

  /// An icon with a caption, in a tonal button.
  Widget _actionButton(KeyboardThemeData theme, PanelStyle style, String label, IconData icon, VoidCallback onTap) {
    return PanelButton(
      semanticsLabel: label,
      height: double.infinity,
      fill: theme.functionKey.fill,
      pressedFill: theme.functionKey.pressedFill,
      radius: style.radius(48),
      onTap: onTap,
      // FittedBox keeps the icon and caption inside the key at large font scales (1.3 and up).
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            DirectionalIcon(icon, size: 20, color: theme.functionKey.label),
            Text(label, maxLines: 1, style: style.text(size: 11, color: theme.functionKey.label)),
          ],
        ),
      ),
    );
  }

  Widget _caption(String text, PanelStyle style, Color color) => Text(text, style: style.text(size: 13, color: color));
}
