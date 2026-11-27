// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-T, redesigned 2026-11-26. The language list behind the translate bar's pills
// (PanelPlacement.full): "Translate from" or "Translate to", one row for every keyboard language with its
// own name and a check mark on the current one: the current language first, then pairs that are installed,
// published (Get), coming soon, and last, dimmed, languages with no pack yet. Every pack is English with one
// other language; a pair between two other languages goes through English and needs both packs (2026-11-26).
// A published pack that is missing offers Get, which opens Model packs (BooBoard never downloads anything
// itself). Tapping a row saves the pair in settings.translate and goes straight back to the translate bar;
// a language with no pack yet only shows a note.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../app/routes.dart';
import '../../engine/lang/registry.dart';
import '../../keyboard/keyboard_session.dart';
import '../../keyboard/panels/keyboard_panel.dart';
import '../../settings/booboard_settings.dart';
import '../../theme/keyboard_theme_data.dart';
import '../shared/panel_style.dart';
import 'translate_languages.dart';
import 'translate_panel.dart';

/// Which side of the pair the list changes.
enum TranslateSide { from, to }

/// The pair after choosing [language] on [side] of [from] → [to]: the other side stays, and choosing the
/// other side's language swaps the two (Brazilian and European Portuguese count as one language here).
(String, String) pairAfterChoosing(TranslateSide side, String language, {required String from, required String to}) {
  if (side == TranslateSide.to) {
    if (packLanguage(language) == packLanguage(from)) return (to, language);
    return (from, language);
  }
  if (packLanguage(language) == packLanguage(to)) return (language, from);
  return (language, to);
}

/// The list's rows: [current] first, then the other [languages] by status (installed, published, coming
/// soon, no pack yet), each group in the keyboard's order.
List<String> orderPairLanguages(String current, List<String> languages, PairStatus Function(String) status) {
  final others = [
    for (final id in languages)
      if (id != current) id,
  ];
  return [current, for (final s in PairStatus.values) ...others.where((id) => status(id) == s)];
}

/// The status words of a row: for the subtitle and, longer, for screen readers.
({String subtitle, String spoken}) pairStatusWords(PairStatus status, {required bool throughEnglish}) {
  final via = throughEnglish ? ' · through English' : '';
  final spokenVia = throughEnglish ? ', through English' : '';
  return switch (status) {
    PairStatus.installed => (subtitle: 'installed$via', spoken: 'pack installed$spokenVia'),
    PairStatus.published => (
      subtitle: throughEnglish ? 'get the packs$via' : 'get the pack',
      spoken: 'pack not installed$spokenVia',
    ),
    PairStatus.comingSoon => (subtitle: 'coming soon$via', spoken: 'pack coming soon$spokenVia'),
    PairStatus.noPack => (subtitle: 'no pack yet', spoken: 'no translation pack yet'),
  };
}

class TranslatePairPanel extends KeyboardPanel {
  TranslatePairPanel({
    required this.session,
    required this.from,
    required this.to,
    required this.installedPairs,
    this.side = TranslateSide.to,
    this.source = '',
  });

  final KeyboardSession session;
  final String from;
  final String to;
  final TranslateSide side;
  final Future<Set<String>> Function() installedPairs;

  /// The source text to carry back to the translate bar.
  final String source;

  @override
  String get id => 'translate_pair';

  /// The whole keyboard area: the list has its own header (back, "Translate to", Offline).
  @override
  PanelPlacement get placement => PanelPlacement.full;

  @override
  Widget build(BuildContext context, PanelContext panel) => TranslatePairView(panel: panel, pickerState: this);
}

class TranslatePairView extends StatefulWidget {
  const TranslatePairView({super.key, required this.panel, required this.pickerState});

  final PanelContext panel;
  final TranslatePairPanel pickerState;

  @override
  State<TranslatePairView> createState() => _TranslatePairViewState();
}

class _TranslatePairViewState extends State<TranslatePairView> {
  Set<String> _installed = const {};

  TranslatePairPanel get _state => widget.pickerState;

  /// The language this list is about (the current one gets the check mark).
  String get _current => _state.side == TranslateSide.to ? _state.to : _state.from;

  @override
  void initState() {
    super.initState();
    unawaited(_loadInstalled());
  }

  Future<void> _loadInstalled() async {
    try {
      final keys = await _state.installedPairs();
      if (mounted) setState(() => _installed = keys);
    } on Object {
      // Without the list every row offers Get.
    }
  }

  /// A short note after tapping a language with no pack yet (the pair stays as it was).
  String? _note;

  (String, String) _pair(String language) => pairAfterChoosing(_state.side, language, from: _state.from, to: _state.to);

  PairStatus _status(String language) {
    final (f, t) = _pair(language);
    return pairStatus(f, t, _installed);
  }

  List<String> get _languages => orderPairLanguages(_current, translateLanguages, _status);

  Future<void> _choose(String language) async {
    final (from, to) = _pair(language);
    if (!isSupportedPair(from, to)) {
      final missing = hasPlannedPacks(language) ? (hasPlannedPacks(from) ? to : from) : language;
      setState(() => _note = 'No translation pack for ${languageInfo(missing).englishName} yet');
      return;
    }
    await _state.session.services.settings.update(
      (s) => s.copyWith(
        translate: s.translate.copyWith(from: from, to: to),
      ),
      sections: const [SettingsSection.translate],
    );
    if (!mounted) return;
    _openTranslate(from, to);
  }

  void _openTranslate(String from, String to) {
    widget.panel.open(
      TranslatePanel(
        session: _state.session,
        from: from,
        to: to,
        installedPairs: _state.installedPairs,
        initialSource: _state.source,
      ),
    );
  }

  void _back() => _openTranslate(_state.from, _state.to);

  void _getPack() => unawaited(_state.session.services.host.openSettings(BooBoardRoutes.packs));

  @override
  Widget build(BuildContext context) {
    final theme = widget.panel.theme;
    final style = PanelStyle(theme);
    final size = widget.panel.size;
    final title = _state.side == TranslateSide.to ? 'Translate to' : 'Translate from';
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Back to translation',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _back,
                    child: SizedBox(
                      width: 56,
                      height: 48,
                      child: Icon(Icons.arrow_back, size: 22, color: theme.toolbarIcon),
                    ),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: style.text(size: 17, color: theme.suggestionText, weight: FontWeight.w600),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: theme.toolbarIcon),
                      const SizedBox(width: 4),
                      Text('Offline', style: style.hint(size: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // The note stays in view whichever row was tapped.
          if (_note != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaler: TextScaler.noScaling,
                    style: style.text(size: 13, color: theme.suggestionText, weight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              children: [
                for (final id in _languages) _row(id, theme, style),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
                  child: Text(
                    'Each pack pairs English with one language and runs on this phone. Other pairs go through '
                    'English and need both packs. Get opens BooBoard, and your browser downloads the pack: '
                    'BooBoard itself never goes online.',
                    style: style.hint(size: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String language, KeyboardThemeData theme, PanelStyle style) {
    final info = languageInfo(language);
    final current = language == _current;
    final status = _status(language);
    final installed = status == PairStatus.installed;
    final published = status == PairStatus.published;
    final noPack = status == PairStatus.noPack;
    final (from, to) = _pair(language);
    final throughEnglish = goesThroughEnglish(from, to);
    final pairName = '${languageInfo(from).englishName} to ${languageInfo(to).englishName}';
    final words = pairStatusWords(status, throughEnglish: throughEnglish);
    final subtitle = info.nativeName == info.englishName
        ? '${words.subtitle[0].toUpperCase()}${words.subtitle.substring(1)}'
        : '${info.englishName} · ${words.subtitle}';
    final spoken = noPack
        ? '${info.englishName}, ${words.spoken}'
        : '${info.englishName}, $pairName, ${words.spoken}${current ? ', selected' : ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              selected: current,
              label: spoken,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => unawaited(_choose(language)),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: current ? theme.suggestionHighlightFill : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: current
                            ? Icon(Icons.check, size: 20, color: theme.suggestionHighlightText)
                            : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.nativeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textScaler: TextScaler.noScaling,
                              style: style.text(
                                size: 16,
                                color: (current ? theme.suggestionHighlightText : theme.suggestionText).withValues(
                                  alpha: noPack ? 0.45 : 1,
                                ),
                                weight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textScaler: TextScaler.noScaling,
                              style: style.text(
                                size: 12,
                                color: (current ? theme.suggestionHighlightText : theme.suggestionText).withValues(
                                  alpha: noPack ? 0.4 : 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (installed)
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: current ? theme.suggestionHighlightText : theme.trailStart,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (published) ...[
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'Get the $pairName ${throughEnglish ? 'packs' : 'pack'}',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _getPack,
                child: Container(
                  width: 60,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: theme.actionKey.fill, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    'Get',
                    style: style.text(size: 14, color: theme.actionKey.label, weight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
