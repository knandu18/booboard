// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. The emoji panel (PanelPlacement.full): a top bar with search and category tabs,
// a lazy grid of emoji (long-press for skin tones), the Kaomoji and Symbols tabs, and a bottom bar
// with ABC, space and a repeating delete key.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../bridge/messages.g.dart';
import '../../keyboard/keyboard_session.dart';
import '../../keyboard/panels/keyboard_panel.dart';
import '../../keyboard/view/keyboard_metrics.dart';
import '../../theme/keyboard_theme_data.dart';
import '../shared/panel_style.dart';
import 'emoji_data.dart';
import 'emoji_glyphs.dart';
import 'emoji_index.dart';
import 'emoji_repository.dart';
import 'emoji_search_panel.dart';
import 'emoji_store.dart';
import 'symbols_data.dart';
import '../shared/directional_icon.dart';

/// What the emoji panels share, created once per keyboard session.
class EmojiServices {
  EmojiServices({required this.session, required this.repository, required this.store, required this.glyphs});

  final KeyboardSession session;
  final EmojiRepository repository;
  final EmojiStore store;
  final EmojiGlyphs glyphs;

  /// Enabled languages the emoji search and suggestions use: the enabled ones that have data, plus English.
  List<String> get languages {
    final enabled = session.services.settings.value.languages.enabled;
    final known = [
      for (final l in enabled)
        if (EmojiRepository.supports(l)) l,
    ];
    if (!known.contains('en')) known.add('en');
    return known;
  }

  void haptic() {
    if (!session.services.settings.value.feedback.haptics) return;
    unawaited(session.services.host.performHaptic(HapticKind.keyTap).catchError((Object _) {}));
  }
}

/// The emoji panel. Open it with `session.openPanel(EmojiPanel(services))`.
class EmojiPanel extends KeyboardPanel {
  EmojiPanel(this.services);

  final EmojiServices services;

  @override
  String get id => 'emoji';

  @override
  PanelPlacement get placement => PanelPlacement.full;

  @override
  Widget build(BuildContext context, PanelContext panel) => EmojiPanelView(services: services, panel: panel);

  @override
  void onClosed() => unawaited(services.store.flush());
}

/// The tabs of the top bar, in order.
enum EmojiTab { recents, people, animals, food, activities, travel, objects, symbols, flags, kaomoji, marks }

/// Unicode groups behind each emoji tab.
const Map<EmojiTab, List<String>> emojiTabGroups = {
  EmojiTab.people: ['Smileys & Emotion', 'People & Body'],
  EmojiTab.animals: ['Animals & Nature'],
  EmojiTab.food: ['Food & Drink'],
  EmojiTab.activities: ['Activities'],
  EmojiTab.travel: ['Travel & Places'],
  EmojiTab.objects: ['Objects'],
  EmojiTab.symbols: ['Symbols'],
  EmojiTab.flags: ['Flags'],
};

class EmojiPanelView extends StatefulWidget {
  const EmojiPanelView({super.key, required this.services, required this.panel});

  final EmojiServices services;
  final PanelContext panel;

  @override
  State<EmojiPanelView> createState() => _EmojiPanelViewState();
}

/// One grid cell: the emoji to insert, its accessible name, and the catalogue item for skin tones.
class _Cell {
  const _Cell(this.text, this.name, this.item);

  final String text;
  final String name;
  final int? item;
}

class _EmojiPanelViewState extends State<EmojiPanelView> {
  static const double _cellHeight = 56;
  static const double _tabHeight = KeyboardMetrics.stripHeight;
  static const double _bottomHeight = 56;

  EmojiIndex? _index;
  Map<String, String> _names = const {};
  bool _loadFailed = false;
  EmojiTab _tab = EmojiTab.recents;
  List<_Cell> _cells = const [];
  List<String> _recents = const [];

  /// Catalogue item whose skin-tone picker is open, or null.
  int? _toneItem;
  bool _disposed = false;

  EmojiServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _services.store.load();
      final index = await _services.repository.ensure(_services.languages);
      if (_disposed) return;
      _names = _namesOf(index.data);
      setState(() => _index = index);
      _refresh();
      await _services.glyphs.ensureChecked(index.data);
      if (_disposed) return;
      _refresh();
    } on Object {
      if (!_disposed) setState(() => _loadFailed = true);
    }
  }

  /// English names for every displayable text, so a recent emoji still has a label.
  static Map<String, String> _namesOf(EmojiData data) {
    final names = <String, String>{};
    for (var i = 0; i < data.items.length; i++) {
      final item = data.items[i];
      names[item.text] = item.name;
      final tones = item.tones;
      if (tones == null) continue;
      for (var t = 0; t < tones.length; t++) {
        final text = tones[t];
        if (text != null) names[text] = data.nameOf(i * refStride + t + 1);
      }
    }
    return names;
  }

  void _selectTab(EmojiTab tab) {
    _toneItem = null;
    _tab = tab;
    _refresh();
  }

  /// Rebuilds the cells for the current tab. Cheap: a single pass over the catalogue.
  void _refresh() {
    final index = _index;
    if (index == null || !mounted) return;
    final store = _services.store;
    final data = index.data;
    final cells = <_Cell>[];
    if (_tab == EmojiTab.recents) {
      _recents = store.recents();
      for (final text in _recents) {
        if (store.isHidden(text)) continue;
        cells.add(_Cell(text, _names[text] ?? text, null));
      }
    } else if (_tab != EmojiTab.kaomoji && _tab != EmojiTab.marks) {
      final groups = {
        for (final name in emojiTabGroups[_tab] ?? const <String>[])
          if (data.groupIndex(name) >= 0) data.groupIndex(name),
      };
      for (var i = 0; i < data.items.length; i++) {
        final item = data.items[i];
        if (!groups.contains(item.group) || store.isHidden(item.text)) continue;
        final ref = displayRef(data, store, i);
        cells.add(_Cell(data.textOf(ref), data.nameOf(ref), i));
      }
    }
    setState(() => _cells = cells);
  }

  void _insert(String text) {
    final s = _services;
    s.session.input.insertText(text);
    s.store.recordUse(text);
    s.haptic();
  }

  void _openTones(int item) {
    setState(() => _toneItem = item);
  }

  void _pickTone(int item, int tone) {
    final index = _index;
    if (index == null) return;
    final data = index.data;
    final base = data.items[item].text;
    final ref = item * refStride + tone;
    final text = data.textOf(ref);
    _services.store.rememberTone(base, tone);
    _toneItem = null;
    _insert(text);
    _refresh();
  }

  void _openSearch() {
    _services.session.openPanel(EmojiSearchPanel(_services));
  }

  @override
  Widget build(BuildContext context) {
    final panel = widget.panel;
    final theme = panel.theme;
    final style = PanelStyle(theme);
    final index = _index;
    return SizedBox(
      width: panel.size.width,
      height: panel.size.height,
      child: Column(
        children: [
          _topBar(theme),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _body(theme, style, index)),
                if (_toneItem != null && index != null) _tonePicker(theme, style, index.data, _toneItem!),
              ],
            ),
          ),
          _bottomBar(theme, style),
        ],
      ),
    );
  }

  Widget _topBar(KeyboardThemeData theme) {
    final tabs = EmojiTab.values;
    return SizedBox(
      height: _tabHeight,
      child: Row(
        children: [
          PanelButton(
            semanticsLabel: 'Search emoji',
            width: 48,
            height: _tabHeight,
            fill: theme.background,
            pressedFill: theme.suggestionHighlightFill,
            radius: BorderRadius.zero,
            onTap: _openSearch,
            child: Icon(Icons.search, size: 22, color: theme.toolbarIcon),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, i) {
                final tab = tabs[i];
                return PanelButton(
                  semanticsLabel: _tabLabel(tab),
                  width: 48,
                  height: _tabHeight,
                  fill: theme.background,
                  pressedFill: theme.suggestionHighlightFill,
                  selected: tab == _tab,
                  radius: BorderRadius.zero,
                  onTap: () => _selectTab(tab),
                  child: _tabIcon(tab, theme),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabIcon(EmojiTab tab, KeyboardThemeData theme) {
    final color = tab == _tab ? theme.suggestionHighlightText : theme.toolbarIcon;
    final text = switch (tab) {
      EmojiTab.kaomoji => '^_^',
      EmojiTab.marks => 'Ω',
      _ => null,
    };
    if (text != null) {
      return Text(
        text,
        style: TextStyle(fontFamily: theme.fontFamily, fontSize: 15, color: color),
      );
    }
    return Icon(
      switch (tab) {
        EmojiTab.recents => Icons.access_time,
        EmojiTab.people => Icons.emoji_emotions_outlined,
        EmojiTab.animals => Icons.pets_outlined,
        EmojiTab.food => Icons.restaurant_outlined,
        EmojiTab.activities => Icons.sports_soccer_outlined,
        EmojiTab.travel => Icons.directions_car_outlined,
        EmojiTab.objects => Icons.lightbulb_outline,
        EmojiTab.symbols => Icons.tag,
        EmojiTab.flags => Icons.flag_outlined,
        _ => Icons.emoji_emotions_outlined,
      },
      size: 22,
      color: color,
    );
  }

  static String _tabLabel(EmojiTab tab) => switch (tab) {
    EmojiTab.recents => 'Recent emoji',
    EmojiTab.people => 'Smileys and people',
    EmojiTab.animals => 'Animals and nature',
    EmojiTab.food => 'Food and drink',
    EmojiTab.activities => 'Activities',
    EmojiTab.travel => 'Travel and places',
    EmojiTab.objects => 'Objects',
    EmojiTab.symbols => 'Emoji symbols',
    EmojiTab.flags => 'Flags',
    EmojiTab.kaomoji => 'Kaomoji',
    EmojiTab.marks => 'Maths, arrows, currency and Greek letters',
  };

  Widget _body(KeyboardThemeData theme, PanelStyle style, EmojiIndex? index) {
    if (_loadFailed) {
      return Center(child: Text('Emoji are not available', style: style.hint()));
    }
    if (_tab == EmojiTab.kaomoji) return _textSections(theme, style, kaomojiSections, cellWidth: null);
    if (_tab == EmojiTab.marks) return _textSections(theme, style, symbolSections, cellWidth: 44);
    if (index == null) {
      return Center(child: Text('Loading emoji', style: style.hint()));
    }
    if (_cells.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _tab == EmojiTab.recents ? 'Emoji you use show up here.' : 'Nothing to show.',
            textAlign: TextAlign.center,
            style: style.hint(),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final columns = (box.maxWidth / 48).floor().clamp(6, 10);
        final cellWidth = box.maxWidth / columns;
        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: _cells.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: cellWidth / _cellHeight,
          ),
          itemBuilder: (context, i) {
            final cell = _cells[i];
            final item = cell.item;
            final tonesItem = item != null && index.data.items[item].tones != null ? item : null;
            return PanelButton(
              semanticsLabel: cell.name,
              height: _cellHeight,
              fill: theme.background,
              pressedFill: theme.letterKey.pressedFill,
              radius: style.radius(_cellHeight),
              onTap: () => _insert(cell.text),
              onLongPress: tonesItem == null ? null : () => _openTones(tonesItem),
              child: Text(cell.text, style: const TextStyle(fontSize: 26)),
            );
          },
        );
      },
    );
  }

  /// Kaomoji and symbols: titled sections of tappable chips.
  Widget _textSections(
    KeyboardThemeData theme,
    PanelStyle style,
    List<SymbolSection> sections, {
    required double? cellWidth,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      itemCount: sections.length,
      itemBuilder: (context, s) {
        final section = sections[s];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
              child: Text(section.title, style: style.hint(size: 12)),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in section.entries)
                  PanelButton(
                    semanticsLabel: entry,
                    height: 44,
                    width: cellWidth,
                    fill: theme.functionKey.fill,
                    pressedFill: theme.functionKey.pressedFill,
                    radius: style.radius(44),
                    onTap: () => _insert(entry),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: cellWidth == null ? 12 : 0),
                      child: Text(
                        entry,
                        style: style.text(size: cellWidth == null ? 15 : 18, color: theme.functionKey.label),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// The skin-tone picker: the base emoji and each tone that Unicode has, shown over the grid.
  Widget _tonePicker(KeyboardThemeData theme, PanelStyle style, EmojiData data, int item) {
    final store = _services.store;
    final base = data.items[item];
    final options = [
      item * refStride,
      for (var t = 1; t <= toneCount; t++)
        if (base.tones?[t - 1] != null && !store.isHidden(base.tones![t - 1]!)) item * refStride + t,
    ];
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _toneItem = null),
            child: Container(color: theme.background.withValues(alpha: 0.6)),
          ),
        ),
        Positioned(
          left: 6,
          right: 6,
          top: 6,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: theme.popupFill, borderRadius: style.radius(64)),
            child: Row(
              children: [
                for (final ref in options)
                  Expanded(
                    child: PanelButton(
                      semanticsLabel: data.nameOf(ref),
                      height: 56,
                      fill: theme.popupFill,
                      pressedFill: theme.popupSelectedFill,
                      radius: style.radius(56),
                      onTap: () => _pickTone(item, ref % refStride),
                      child: Text(data.textOf(ref), style: const TextStyle(fontSize: 26)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(KeyboardThemeData theme, PanelStyle style) {
    return SizedBox(
      height: _bottomHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: PanelButton(
                semanticsLabel: 'Back to letters',
                height: double.infinity,
                fill: theme.functionKey.fill,
                pressedFill: theme.functionKey.pressedFill,
                radius: style.radius(48),
                onTap: _services.session.closePanel,
                child: Text('ABC', style: style.text(size: 15, color: theme.functionKey.label)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 5,
              child: PanelButton(
                semanticsLabel: 'Space',
                height: double.infinity,
                fill: theme.spaceKey.fill,
                pressedFill: theme.spaceKey.pressedFill,
                radius: style.radius(48),
                onTap: () => _services.session.input.insertText(' '),
                child: const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: PanelButton(
                semanticsLabel: 'Delete',
                height: double.infinity,
                fill: theme.functionKey.fill,
                pressedFill: theme.functionKey.pressedFill,
                radius: style.radius(48),
                repeat: true,
                onTap: _services.session.input.onBackspace,
                child: DirectionalIcon(Icons.backspace_outlined, size: 22, color: theme.functionKey.label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
