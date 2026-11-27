// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Emoji search (PanelPlacement.strip): the strip becomes a search field with matching
// emoji beside it. The keyboard's own keys type into it through a KeyRedirect. Tapping a result inserts
// it and keeps the search open. Enter or the back arrow returns to the emoji panel.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../keyboard/panels/keyboard_panel.dart';
import '../shared/panel_style.dart';
import 'emoji_index.dart';
import 'emoji_panel.dart';
import 'emoji_store.dart';
import '../shared/directional_icon.dart';

/// Results shown next to the query.
const int _maxResults = 40;

class EmojiSearchPanel extends KeyboardPanel {
  EmojiSearchPanel(this.services) : _redirect = EmojiSearchRedirect();

  final EmojiServices services;
  final EmojiSearchRedirect _redirect;

  @override
  String get id => 'emoji_search';

  @override
  PanelPlacement get placement => PanelPlacement.strip;

  @override
  KeyRedirect? get keyRedirect => _redirect;

  @override
  Widget build(BuildContext context, PanelContext panel) =>
      EmojiSearchView(services: services, panel: panel, redirect: _redirect);

  @override
  void onClosed() => unawaited(services.store.flush());
}

/// Receives the keyboard's keys while the search is open: text builds the query, backspace shortens it.
class EmojiSearchRedirect implements KeyRedirect {
  final ValueNotifier<String> query = ValueNotifier('');

  /// Set by the view: Enter returns to the emoji panel.
  VoidCallback? onEnterKey;

  @override
  void onText(String text) => query.value = query.value + text;

  @override
  void onSpace() => query.value = '${query.value} ';

  @override
  void onBackspace() {
    final chars = query.value.characters;
    if (chars.isNotEmpty) query.value = chars.skipLast(1).string;
  }

  @override
  void onEnter() => onEnterKey?.call();
}

class EmojiSearchView extends StatefulWidget {
  const EmojiSearchView({super.key, required this.services, required this.panel, required this.redirect});

  final EmojiServices services;
  final PanelContext panel;
  final EmojiSearchRedirect redirect;

  @override
  State<EmojiSearchView> createState() => _EmojiSearchViewState();
}

class _EmojiSearchViewState extends State<EmojiSearchView> {
  EmojiIndex? _index;
  List<int> _items = const [];
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    widget.redirect
      ..onEnterKey = _back
      ..query.addListener(_search);
    unawaited(_load());
  }

  @override
  void dispose() {
    _disposed = true;
    widget.redirect
      ..onEnterKey = null
      ..query.removeListener(_search);
    super.dispose();
  }

  Future<void> _load() async {
    final index = await widget.services.repository.ensure(widget.services.languages);
    if (_disposed) return;
    setState(() => _index = index);
    _search();
  }

  void _search() {
    final index = _index;
    final q = widget.redirect.query.value;
    final items = index == null || q.trim().isEmpty ? const <int>[] : index.search(q, limit: _maxResults);
    if (mounted) setState(() => _items = items);
  }

  void _back() {
    widget.services.session.openPanel(EmojiPanel(widget.services));
  }

  void _insert(String text) {
    widget.services.session.input.insertText(text);
    widget.services.store.recordUse(text);
    widget.services.haptic();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.panel.theme;
    final style = PanelStyle(theme);
    final index = _index;
    return SizedBox(
      width: widget.panel.size.width,
      height: widget.panel.size.height,
      child: Row(
        children: [
          PanelButton(
            semanticsLabel: 'Back to emoji',
            width: 48,
            height: widget.panel.size.height,
            fill: theme.background,
            pressedFill: theme.suggestionHighlightFill,
            radius: BorderRadius.zero,
            onTap: _back,
            child: DirectionalIcon(Icons.arrow_back, size: 22, color: theme.toolbarIcon),
          ),
          ValueListenableBuilder<String>(
            valueListenable: widget.redirect.query,
            builder: (context, query, _) => ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Center(
                  child: Text(
                    query.isEmpty ? 'Search emoji' : query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: query.isEmpty ? style.hint(size: 13) : style.text(size: 15, color: theme.suggestionText),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: index == null
                ? Center(child: Text('…', style: style.hint()))
                : _items.isEmpty
                ? Center(
                    child: Text(
                      widget.redirect.query.value.trim().isEmpty ? '' : 'No match',
                      style: style.hint(size: 13),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final ref = displayRef(index.data, widget.services.store, _items[i]);
                      final text = index.data.textOf(ref);
                      return PanelButton(
                        semanticsLabel: index.data.nameOf(ref),
                        width: 44,
                        height: widget.panel.size.height,
                        fill: theme.background,
                        pressedFill: theme.letterKey.pressedFill,
                        radius: BorderRadius.zero,
                        onTap: () => _insert(text),
                        child: Text(text, style: const TextStyle(fontSize: 22)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
