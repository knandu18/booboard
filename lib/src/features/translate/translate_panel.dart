// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-T, redesigned 2026-11-26 (like a live translate bar). The translate panel
// (PanelPlacement.strip, two rows): a back arrow, the two languages as pills with a swap button between
// them, then a "Type here to translate" box. The keyboard's own keys type into the box; the translation
// appears live in the app's text field (as composing text) and updates while typing. Enter keeps it and
// starts a new phrase; closing the bar keeps it too. The typed source never goes into the app.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../app/routes.dart';
import '../../core/log.dart';
import '../../engine/lang/registry.dart';
import '../../keyboard/keyboard_session.dart';
import '../../keyboard/panels/keyboard_panel.dart';
import '../../packs/pack_catalog.dart';
import '../../settings/booboard_settings.dart';
import '../../theme/keyboard_theme_data.dart';
import '../shared/panel_style.dart';
import 'translate_controller.dart';
import 'translate_languages.dart';
import 'translate_pair_panel.dart';

/// Characters of source text shown in the box (the end stays visible).
const int sourceTailChars = 36;

/// The source text shown in the box: the last [sourceTailChars] characters, with an ellipsis in front.
String sourceTail(String text) {
  final chars = text.characters;
  if (chars.length <= sourceTailChars) return text;
  return '…${chars.takeLast(sourceTailChars - 1).string}';
}

/// Height of the bar's second row (the text box), taken from the key rows while the bar is open.
const double translateBoxRowHeight = 48;

class TranslatePanel extends KeyboardPanel {
  TranslatePanel({
    required this.session,
    required this.from,
    required this.to,
    required this.installedPairs,
    this.initialSource = '',
  }) : controller = TranslateController(
         translate: (text, f, t) => translateMaybeThroughEnglish(session.services.host.translate, text, f, t),
         insert: session.input.insertPhrase,
         from: from,
         to: to,
       ) {
    _keys = _TranslateKeys(this);
    // Whatever was being typed stays as typed; the translation goes after it.
    session.input.finishComposing();
    controller
      ..addListener(_onChange)
      ..setSource(initialSource);
  }

  final KeyboardSession session;

  /// BooBoard language ids of the pair.
  final String from;
  final String to;

  /// Pair keys of the installed packs (see `installedPairKeys`), read when the picker opens.
  final Future<Set<String>> Function() installedPairs;

  /// Text to continue from (the picker and the swap keep the source when the pair changes).
  final String initialSource;

  final TranslateController controller;
  late final _TranslateKeys _keys;

  /// The translation shown live in the app (composing text), with its leading space if any.
  String _shown = '';

  /// The translation the app should show next (without the space).
  String _target = '';

  /// The text before the cursor ends in a word, so the translation gets a space in front. Null until the
  /// first translation: read then, after a bar this one replaced has taken its own text out.
  bool? _needsSpace;

  /// Editor calls run one after another, in order.
  Future<void> _queue = Future<void>.value();

  /// False when the bar closes only to reopen (picker, swap): the live text is taken out of the app.
  bool _keepOnClose = true;
  bool _closed = false;

  @override
  String get id => 'translate';

  @override
  PanelPlacement get placement => PanelPlacement.strip;

  @override
  double get extraStripHeight => translateBoxRowHeight;

  @override
  KeyRedirect? get keyRedirect => _keys;

  Future<bool> _readSpacing() async {
    try {
      final before = await session.input.editor.getTextBeforeCursor(1);
      return before != null && before.isNotEmpty && before.trim().isNotEmpty;
    } on Object {
      return false;
    }
  }

  void _enqueue(Future<void> Function() step) => _queue = _queue.then((_) => step());

  /// Keeps the app's text in step with the translation. While a new one is on its way the old one stays.
  void _onChange() {
    if (_closed) return;
    switch (controller.status) {
      case TranslateStatus.ready:
        _show((controller.translation ?? '').trim());
      case TranslateStatus.idle || TranslateStatus.noPack || TranslateStatus.failed:
        _show('');
      case TranslateStatus.waiting:
        break;
    }
  }

  void _show(String text) {
    _target = text;
    _enqueue(() async {
      final target = _target;
      if (target.isNotEmpty) _needsSpace ??= await _readSpacing();
      final shown = target.isEmpty ? '' : ((_needsSpace ?? false) ? ' $target' : target);
      if (shown == _shown) return;
      _shown = shown;
      await _editor(() => session.input.editor.setComposingText(shown));
    });
  }

  /// Enter: keeps the translation in the app and empties the box for the next phrase.
  void commit() {
    if (controller.status != TranslateStatus.ready || (controller.translation ?? '').trim().isEmpty) return;
    _enqueue(() async {
      if (_shown.isEmpty) return;
      _shown = '';
      _needsSpace = true;
      await _editor(session.input.editor.finishComposingText);
    });
    controller.clear();
  }

  /// The clear button: empties the box and takes the live translation back out of the app.
  void clearAll() {
    _show('');
    controller.clear();
  }

  /// Opens [next] in place of this bar; the live translation is taken out (the next bar shows it again).
  void replaceWith(PanelContext panel, KeyboardPanel next) {
    _keepOnClose = false;
    panel.open(next);
  }

  /// Swaps the two languages, saves the pair, and keeps the typed text.
  Future<void> swap(PanelContext panel) async {
    if (!isSupportedPair(to, from)) return;
    await _savePair(session, to, from);
    replaceWith(
      panel,
      TranslatePanel(
        session: session,
        from: to,
        to: from,
        installedPairs: installedPairs,
        initialSource: controller.source,
      ),
    );
  }

  void openPicker(PanelContext panel, TranslateSide side) => replaceWith(
    panel,
    TranslatePairPanel(
      session: session,
      from: from,
      to: to,
      side: side,
      installedPairs: installedPairs,
      source: controller.source,
    ),
  );

  Future<void> _editor(Future<Object?> Function() call) async {
    try {
      await call();
    } on Object catch (e) {
      BooBoardLog.w('Translate', 'editor call failed', e.runtimeType);
    }
  }

  @override
  Widget build(BuildContext context, PanelContext panel) => TranslateBar(
    controller: controller,
    theme: panel.theme,
    size: panel.size,
    from: from,
    to: to,
    onClose: panel.close,
    onFrom: () => openPicker(panel, TranslateSide.from),
    onTo: () => openPicker(panel, TranslateSide.to),
    onSwap: isSupportedPair(to, from) ? () => unawaited(swap(panel)) : null,
    onClear: clearAll,
    onGetPack: () => unawaited(session.services.host.openSettings(BooBoardRoutes.packs)),
  );

  @override
  void onClosed() {
    _closed = true;
    controller
      ..removeListener(_onChange)
      ..dispose();
    _enqueue(_finish);
    unawaited(session.services.host.releaseTranslator());
  }

  /// Keeps (or, when the bar only changes pair, removes) the live translation, then lets the input
  /// controller re-read the text around the cursor.
  Future<void> _finish() async {
    final editor = session.input.editor;
    if (_shown.isNotEmpty) {
      if (!_keepOnClose) await _editor(() => editor.setComposingText(''));
      await _editor(editor.finishComposingText);
    }
    _shown = '';
    session.input.resyncAfterExternalEdit();
  }
}

/// Saves [from] → [to] as the translate pair.
Future<void> _savePair(KeyboardSession session, String from, String to) => session.services.settings.update(
  (s) => s.copyWith(
    translate: s.translate.copyWith(from: from, to: to),
  ),
  sections: const [SettingsSection.translate],
);

/// The keyboard's keys while the bar is open: text builds the source, backspace shortens it, Enter keeps
/// the translation and starts a new phrase.
class _TranslateKeys implements KeyRedirect {
  _TranslateKeys(this.panel);

  final TranslatePanel panel;

  @override
  void onText(String text) => panel.controller.append(text);

  @override
  void onSpace() => panel.controller.append(' ');

  @override
  void onBackspace() => panel.controller.backspace();

  @override
  void onEnter() => panel.commit();
}

/// The two-row translate bar: back, [from] ⇄ [to], then the text box.
class TranslateBar extends StatelessWidget {
  const TranslateBar({
    super.key,
    required this.controller,
    required this.theme,
    required this.size,
    required this.from,
    required this.to,
    required this.onClose,
    required this.onFrom,
    required this.onTo,
    required this.onSwap,
    required this.onClear,
    required this.onGetPack,
  });

  final TranslateController controller;
  final KeyboardThemeData theme;
  final Size size;
  final String from;
  final String to;

  /// Back to the normal strip and keys (the translation stays in the app).
  final VoidCallback onClose;
  final VoidCallback onFrom;
  final VoidCallback onTo;

  /// Null when the reverse pair has no pack at all.
  final VoidCallback? onSwap;
  final VoidCallback onClear;
  final VoidCallback onGetPack;

  @override
  Widget build(BuildContext context) {
    final style = PanelStyle(theme);
    final fromName = languageInfo(from).englishName;
    final toName = languageInfo(to).englishName;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Column(
        children: [
          SizedBox(
            height: size.height - translateBoxRowHeight,
            child: Row(
              children: [
                _iconButton(Icons.arrow_back, 'Close translation', onClose),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: _pill(fromName, 'Translate from $fromName. Change language', onFrom, style)),
                      _iconButton(Icons.swap_horiz, 'Swap languages', onSwap),
                      Flexible(child: _pill(toName, 'Translate to $toName. Change language', onTo, style)),
                    ],
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
          ),
          SizedBox(
            height: translateBoxRowHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
              child: ListenableBuilder(listenable: controller, builder: (context, _) => _box(style, fromName, toName)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String label, VoidCallback? onTap) => Semantics(
    container: true,
    button: true,
    enabled: onTap != null,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          size: 22,
          color: onTap == null ? theme.toolbarIcon.withValues(alpha: 0.4) : theme.toolbarIcon,
        ),
      ),
    ),
  );

  /// A language pill: glass like the keys.
  Widget _pill(String name, String label, VoidCallback onTap, PanelStyle style) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: _glass(16),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textScaler: TextScaler.noScaling,
          style: style.text(size: 14, color: theme.letterKey.label, weight: FontWeight.w500),
        ),
      ),
    ),
  );

  BoxDecoration _glass(double radius) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [theme.letterKey.fillTop ?? theme.letterKey.fill, theme.letterKey.fill],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: theme.letterKey.border ?? theme.suggestionDivider),
  );

  Widget _box(PanelStyle style, String fromName, String toName) {
    final source = controller.source;
    final noPack = controller.status == TranslateStatus.noPack;
    // Get only leads somewhere when the packs are published; other directions say so plainly. A pair
    // without English needs two packs.
    final throughEnglish = goesThroughEnglish(from, to);
    final published = packsForPair(from, to).every((k) => catalogTranslation(k) != null);
    final waiting = controller.status == TranslateStatus.waiting;
    // What was typed always shows; a missing pack is a small note under it, never instead of it.
    final Widget typed = source.isEmpty
        ? Text(
            'Type here to translate',
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: style.text(size: 15, color: theme.letterKey.label.withValues(alpha: 0.55)),
          )
        : Row(
            children: [
              Flexible(
                child: Text(
                  sourceTail(source),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.noScaling,
                  style: style.text(size: noPack ? 14 : 15, color: theme.letterKey.label),
                ),
              ),
              Container(
                width: 2,
                height: noPack ? 15 : 18,
                margin: const EdgeInsets.only(left: 1),
                color: theme.trailStart,
              ),
            ],
          );
    final notice = switch ((published, throughEnglish)) {
      (true, false) => 'No $fromName → $toName pack yet: your browser downloads it with Get',
      (true, true) => '$fromName → $toName goes through English: get both packs with Get',
      (false, false) => '$fromName → $toName pack not published yet: tap a language to pick another',
      (false, true) => '$fromName → $toName goes through English: a pack is not published yet',
    };
    final Widget content = noPack
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              typed,
              Text(
                notice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: style.text(size: 11, color: theme.letterKey.label.withValues(alpha: 0.75)),
              ),
            ],
          )
        : typed;
    return Semantics(
      container: true,
      label: [source.isEmpty ? 'Type here to translate' : 'Text to translate: $source', if (noPack) notice].join('. '),
      liveRegion: noPack,
      child: Container(
        decoration: _glass(20),
        padding: const EdgeInsets.only(left: 14, right: 4),
        child: Row(
          children: [
            Expanded(child: ExcludeSemantics(child: content)),
            if (waiting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 6,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: theme.trailStart),
                  ),
                ),
              ),
            if (noPack && published)
              Semantics(
                container: true,
                button: true,
                label: 'Get the translation pack',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onGetPack,
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: theme.actionKey.fill, borderRadius: BorderRadius.circular(15)),
                    child: Text(
                      'Get',
                      style: style.text(size: 13, color: theme.actionKey.label, weight: FontWeight.w600),
                    ),
                  ),
                ),
              )
            else if (source.isNotEmpty)
              _iconButton(Icons.close, 'Clear text', onClear),
          ],
        ),
      ),
    );
  }
}
