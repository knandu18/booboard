// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. The clipboard panel (PanelPlacement.full): a top bar with back, the history switch and
// "Clear all" (asks first, keeps pinned items), then the history as cards, newest first. Tap a card to
// paste it; pin or delete it from the card. Empty and locked states explain themselves.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../keyboard/keyboard_session.dart';
import '../../keyboard/panels/keyboard_panel.dart';
import '../../keyboard/view/keyboard_metrics.dart';
import '../../theme/keyboard_theme_data.dart';
import '../../settings/booboard_settings.dart';
import '../shared/panel_style.dart';
import 'clipboard_store.dart';
import '../shared/directional_icon.dart';

class ClipboardPanel extends KeyboardPanel {
  ClipboardPanel({required this.session, required this.store});

  final KeyboardSession session;
  final ClipboardStore store;

  @override
  String get id => 'clipboard';

  @override
  PanelPlacement get placement => PanelPlacement.full;

  @override
  Widget build(BuildContext context, PanelContext panel) =>
      ClipboardPanelView(session: session, store: store, panel: panel);

  @override
  void onClosed() => unawaited(store.flush());
}

/// "1 hour", "15 minutes", "1 day", "1 week"; other values in minutes.
String expiryLabel(int minutes) {
  if (minutes % (7 * 24 * 60) == 0) {
    final weeks = minutes ~/ (7 * 24 * 60);
    return weeks == 1 ? '1 week' : '$weeks weeks';
  }
  if (minutes % (24 * 60) == 0) {
    final days = minutes ~/ (24 * 60);
    return days == 1 ? '1 day' : '$days days';
  }
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return hours == 1 ? '1 hour' : '$hours hours';
  }
  return minutes == 1 ? '1 minute' : '$minutes minutes';
}

class ClipboardPanelView extends StatefulWidget {
  const ClipboardPanelView({super.key, required this.session, required this.store, required this.panel});

  final KeyboardSession session;
  final ClipboardStore store;
  final PanelContext panel;

  @override
  State<ClipboardPanelView> createState() => _ClipboardPanelViewState();
}

class _ClipboardPanelViewState extends State<ClipboardPanelView> {
  bool _confirmClear = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Opening the panel expires old items and reads the history again.
  Future<void> _open() async {
    try {
      await widget.store.flush();
      await widget.store.load(force: true);
      widget.store.prune();
    } on Object {
      // Shown as an empty history; nothing is written over a locked blob.
    }
    if (!_disposed) setState(() {});
  }

  void _setHistory(bool on) {
    unawaited(
      widget.session.services.settings
          .update(
            (s) => s.copyWith(clipboard: s.clipboard.copyWith(history: on)),
            sections: const [SettingsSection.clipboard],
          )
          .catchError((Object _) {}),
    );
    setState(() {});
  }

  void _paste(ClipItem item) {
    widget.session.input.insertText(item.text);
    widget.session.closePanel();
  }

  void _togglePin(ClipItem item) {
    widget.store.setPinned(item.id, !item.pinned);
    setState(() {});
  }

  void _delete(ClipItem item) {
    widget.store.delete(item.id);
    setState(() {});
  }

  void _clearAll() {
    widget.store.clearUnpinned();
    setState(() => _confirmClear = false);
  }

  @override
  Widget build(BuildContext context) {
    final panel = widget.panel;
    final theme = panel.theme;
    final style = PanelStyle(theme);
    final history = widget.session.services.settings.value.clipboard;
    final store = widget.store;
    final items = store.items;
    return SizedBox(
      width: panel.size.width,
      height: panel.size.height,
      child: Column(
        children: [
          SizedBox(
            height: KeyboardMetrics.stripHeight,
            child: Row(
              children: [
                PanelButton(
                  semanticsLabel: 'Back to keyboard',
                  width: 48,
                  height: KeyboardMetrics.stripHeight,
                  fill: kPanelClear,
                  pressedFill: theme.suggestionHighlightFill,
                  radius: BorderRadius.zero,
                  onTap: widget.session.closePanel,
                  child: DirectionalIcon(Icons.arrow_back, size: 22, color: theme.toolbarIcon),
                ),
                PanelSwitch(
                  value: history.history,
                  onChanged: _setHistory,
                  label: history.history ? 'Clipboard history on' : 'Clipboard history off',
                  theme: theme,
                ),
                Expanded(
                  child: Text(
                    _confirmClear ? 'Clear all but pinned?' : 'History',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style.text(size: 14, color: theme.suggestionText),
                  ),
                ),
                if (_confirmClear) ...[
                  _TextAction(
                    label: 'Cancel',
                    style: style,
                    theme: theme,
                    onTap: () => setState(() => _confirmClear = false),
                  ),
                  const SizedBox(width: 6),
                  _TextAction(label: 'Clear', style: style, theme: theme, onTap: _clearAll, emphasis: true),
                  const SizedBox(width: 6),
                ] else if (items.isNotEmpty)
                  _TextAction(
                    label: 'Clear all',
                    style: style,
                    theme: theme,
                    onTap: () => setState(() => _confirmClear = true),
                  ),
              ],
            ),
          ),
          Expanded(child: _body(theme, style, store, items, history)),
        ],
      ),
    );
  }

  Widget _body(
    KeyboardThemeData theme,
    PanelStyle style,
    ClipboardStore store,
    List<ClipItem> items,
    ClipboardSettings history,
  ) {
    if (store.locked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Unlock your phone to see clipboard history',
            textAlign: TextAlign.center,
            style: style.text(size: 15),
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            history.history
                ? 'Text you copy shows up here for ${expiryLabel(history.expiryMinutes)}. '
                      'Pinned items stay. Passwords are never saved.'
                : 'History is off. Turn it on to keep text you copy.',
            textAlign: TextAlign.center,
            style: style.hint(size: 14),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
      itemCount: items.length,
      itemBuilder: (context, i) => _card(theme, style, items[i], position: i + 1, count: items.length),
    );
  }

  Widget _card(KeyboardThemeData theme, PanelStyle style, ClipItem item, {required int position, required int count}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: PanelButton(
        semanticsLabel: 'Paste clipboard item, $position of $count',
        height: null,
        fill: theme.letterKey.fill,
        pressedFill: theme.letterKey.pressedFill,
        radius: style.radius(64),
        onTap: () => _paste(item),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 10),
                child: Text(
                  item.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: style.text(size: 15, color: theme.letterKey.label, weight: FontWeight.w400),
                ),
              ),
            ),
            PanelButton(
              semanticsLabel: item.pinned ? 'Unpin item' : 'Pin item',
              width: 48,
              height: 48,
              fill: theme.letterKey.fill,
              pressedFill: theme.letterKey.pressedFill,
              radius: BorderRadius.circular(24),
              onTap: () => _togglePin(item),
              child: Icon(
                item.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 20,
                color: item.pinned ? theme.actionKey.fill : theme.toolbarIcon,
              ),
            ),
            PanelButton(
              semanticsLabel: 'Delete item',
              width: 48,
              height: 48,
              fill: theme.letterKey.fill,
              pressedFill: theme.letterKey.pressedFill,
              radius: BorderRadius.circular(24),
              onTap: () => _delete(item),
              child: Icon(Icons.delete_outline, size: 20, color: theme.toolbarIcon),
            ),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}

/// A small text button for the top bar.
class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.style,
    required this.theme,
    required this.onTap,
    this.emphasis = false,
  });

  final String label;
  final PanelStyle style;
  final KeyboardThemeData theme;
  final VoidCallback onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return PanelButton(
      semanticsLabel: label,
      height: 36,
      fill: emphasis ? theme.actionKey.fill : theme.functionKey.fill,
      pressedFill: emphasis ? theme.actionKey.pressedFill : theme.functionKey.pressedFill,
      radius: style.radius(36),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: style.text(size: 13, color: emphasis ? theme.actionKey.label : theme.functionKey.label),
        ),
      ),
    );
  }
}
