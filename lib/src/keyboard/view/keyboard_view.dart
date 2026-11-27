// SPDX-License-Identifier: GPL-3.0-or-later
//
// The keyboard content: suggestion strip, keys, gesture trail and popups.
// Typing never rebuilds the whole tree: shift repaints the keys layer, press
// springs repaint through the animator, the strip listens to its own notifier.
import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../bridge/messages.g.dart';
import '../../core/input_field_info.dart';
import '../../settings/booboard_settings.dart';
import '../../theme/keyboard_theme_data.dart';
import '../candidates/candidate_grid_panel.dart';
import '../candidates/candidate_strip.dart';
import '../gesture_layer/gesture_trail.dart';
import '../input/keyboard_page.dart';
import '../keyboard_session.dart';
import '../layout/layout_engine.dart';
import '../layout/layout_model.dart';
import '../panels/keyboard_panel.dart';
import '../panels/tools_menu_panel.dart';
import 'key_press_animator.dart';
import 'keyboard_metrics.dart';
import 'keyboard_view_controller.dart';
import 'keys_painter.dart';
import 'popup_layer.dart';
import 'suggestion_strip.dart';

class KeyboardView extends StatefulWidget {
  const KeyboardView({
    super.key,
    required this.session,
    required this.theme,
    required this.settings,
    this.hooks = const KeyboardHooks(),
  });

  final KeyboardSession session;
  final KeyboardThemeData theme;
  final BooBoardSettings settings;
  final KeyboardHooks hooks;

  @override
  State<KeyboardView> createState() => _KeyboardViewState();
}

class _KeyboardViewState extends State<KeyboardView> with SingleTickerProviderStateMixin {
  late final KeyPressAnimator _animator;
  late final GestureTrailController _trail;
  late final KeyboardViewController _view;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _animator = KeyPressAnimator(vsync: this, motion: widget.theme.motion);
    _trail = GestureTrailController();
    _view = KeyboardViewController(
      input: s.input,
      decoder: s.services.gestureDecoder,
      trail: _trail,
      animator: _animator,
      host: s.services.host,
      settings: () => s.services.settings.value,
      hooks: _hooks,
    );
    // A new page or field replaces the keys under the finger: drop active touches.
    s.input.page.addListener(_view.cancelAll);
    s.input.field.addListener(_view.cancelAll);
  }

  @override
  void didUpdateWidget(KeyboardView old) {
    super.didUpdateWidget(old);
    _animator.motion = widget.theme.motion;
    _view.hooks = _hooks;
  }

  @override
  void dispose() {
    widget.session.input.page.removeListener(_view.cancelAll);
    widget.session.input.field.removeListener(_view.cancelAll);
    _view.dispose();
    _animator.dispose();
    _trail.dispose();
    super.dispose();
  }

  /// Defaults under the features' hooks: the Themes button opens the settings app's theme gallery,
  /// and the globe key cycles the enabled languages when there are several.
  KeyboardHooks get _hooks {
    final s = widget.session;
    return KeyboardHooks.merge([
      widget.hooks,
      KeyboardHooks(
        onTheme: () => unawaited(_openSettings(s, route: 'themes')),
        onLanguageSwitch: s.canSwitchLanguage ? () => unawaited(s.switchLanguage()) : null,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final theme = widget.theme;
    final settings = widget.settings;
    final metrics = s.services.events.metrics.value;
    final landscape = metrics?.isLandscape ?? false;
    final rowsHeight = KeyboardMetrics.rowsHeight(
      settings,
      landscape: landscape,
      compact: KeyboardMetrics.isCompact(metrics),
    );
    final hooks = _hooks;
    return LayoutBuilder(
      builder: (context, constraints) {
        _view
          ..viewSize = Size(constraints.maxWidth, KeyboardMetrics.stripHeight + rowsHeight)
          ..keyAreaTop = KeyboardMetrics.stripHeight;
        final width = constraints.maxWidth;
        // Right-to-left languages (Wave 3-C) mirror the strip and panels; key rows keep the
        // physical order of their layout file.
        Widget directional(Widget child) => ValueListenableBuilder<String>(
          valueListenable: s.activeLanguage,
          builder: (context, _, _) =>
              Directionality(textDirection: s.activeInfo.isRtl ? TextDirection.rtl : TextDirection.ltr, child: child),
        );
        // Wave 4: a composer (Chinese, Japanese) with something to show replaces the suggestions.
        final suggestions = ValueListenableBuilder<InputFieldInfo>(
          valueListenable: s.input.field,
          builder: (context, field, _) => SuggestionStrip(
            theme: theme,
            bar: s.input.bar,
            field: field,
            suggestionsEnabled: settings.typing.showSuggestions,
            incognito: s.input.isIncognito,
            // Long-press the Settings gear: the tools menu (text editing, one-handed and floating, settings).
            hooks: KeyboardHooks.merge([
              hooks,
              KeyboardHooks(onToolsMenu: (items) => s.openPanel(ToolsMenuPanel(items))),
            ]),
            chips: s.stripChips,
            onPick: (suggestion) {
              s.input.onSuggestionPicked(suggestion);
              if (settings.feedback.haptics) unawaited(_hapticQuiet(s));
            },
            onOpenSettings: () => unawaited(_openSettings(s)),
          ),
        );
        final strip = ListenableBuilder(
          listenable: Listenable.merge([s.input.composerState, s.panel]),
          builder: (context, _) {
            final state = s.input.composerState.value;
            if (state.isEmpty) return suggestions;
            final gridOpen = s.panel.value?.id == CandidateGridPanel.panelId;
            return CandidateStrip(
              theme: theme,
              state: state,
              expanded: gridOpen,
              onSelect: (i) {
                s.input.selectCandidate(i);
                if (settings.feedback.haptics) unawaited(_hapticQuiet(s));
              },
              onToggleGrid: () => gridOpen ? s.closePanel() : s.openPanel(CandidateGridPanel()),
            );
          },
        );
        Widget panelArea(KeyboardPanel p, double height) => SizedBox(
          width: width,
          height: height,
          child: directional(
            Builder(
              builder: (context) => p.build(
                context,
                PanelContext(session: s, theme: theme, settings: settings, size: Size(width, height)),
              ),
            ),
          ),
        );
        return SizedBox(
          height: KeyboardMetrics.stripHeight + rowsHeight,
          child: ValueListenableBuilder<KeyboardPanel?>(
            valueListenable: s.panel,
            builder: (context, panel, _) {
              if (panel != null && panel.placement == PanelPlacement.full) {
                return panelArea(panel, KeyboardMetrics.stripHeight + rowsHeight);
              }
              // A strip panel may take a little height from the keys (the translator's second row).
              final extra = panel != null && panel.placement == PanelPlacement.strip
                  ? panel.extraStripHeight.clamp(0.0, rowsHeight * 0.3)
                  : 0.0;
              final stripH = KeyboardMetrics.stripHeight + extra;
              final keysH = rowsHeight - extra;
              _view
                ..viewSize = Size(width, stripH + keysH)
                ..keyAreaTop = stripH;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      if (panel != null && panel.placement == PanelPlacement.strip)
                        panelArea(panel, stripH)
                      else
                        directional(strip),
                      SizedBox(
                        height: keysH,
                        child: panel != null && panel.placement == PanelPlacement.keys
                            ? panelArea(panel, keysH)
                            : ListenableBuilder(
                                listenable: Listenable.merge([s.input.page, s.input.field, s.layoutVersion]),
                                builder: (context, _) {
                                  final field = s.input.field.value;
                                  final page = s.input.page.value;
                                  return KeyboardKeysArea(
                                    session: s,
                                    theme: theme,
                                    settings: settings,
                                    field: field,
                                    page: page,
                                    layoutDef: s.layoutFor(page, field, settings),
                                    viewController: _view,
                                    animator: _animator,
                                    trail: _trail,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: PopupPainter(state: _view.popup, theme: theme),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _hapticQuiet(KeyboardSession s) async {
    try {
      await s.services.host.performHaptic(HapticKind.keyTap);
    } on Object {
      // Haptics are best effort.
    }
  }

  Future<void> _openSettings(KeyboardSession s, {String? route}) async {
    try {
      await s.services.host.openSettings(route);
    } on Object {
      // Nothing to do: the settings activity may be unavailable.
    }
  }
}

/// The keys of one page, with touch handling and the swipe trail.
class KeyboardKeysArea extends StatefulWidget {
  const KeyboardKeysArea({
    super.key,
    required this.session,
    required this.theme,
    required this.settings,
    required this.field,
    required this.page,
    required this.layoutDef,
    required this.viewController,
    required this.animator,
    required this.trail,
  });

  final KeyboardSession session;
  final KeyboardThemeData theme;
  final BooBoardSettings settings;
  final InputFieldInfo field;
  final KeyboardPage page;
  final KeyboardLayoutDef? layoutDef;
  final KeyboardViewController viewController;
  final KeyPressAnimator animator;
  final GestureTrailController trail;

  @override
  State<KeyboardKeysArea> createState() => _KeyboardKeysAreaState();
}

class _KeyboardKeysAreaState extends State<KeyboardKeysArea> {
  final KeyTextCache _text = KeyTextCache();
  LaidOutKeyboard? _laid;
  bool _laidSplit = false;
  bool _laidCompact = false;
  LaidOutKeyboard? _notified;
  KeyboardThemeData? _themeOfCache;

  LaidOutKeyboard? _layout(Size size) {
    final def = widget.layoutDef;
    if (def == null) return null;
    final gap = widget.theme.keyGap;
    final metrics = widget.session.services.events.metrics.value;
    final split = KeyboardMetrics.isSplit(widget.settings, size.width, metrics);
    final compact = KeyboardMetrics.isCompact(metrics);
    final cur = _laid;
    if (cur != null &&
        identical(cur.layout, def) &&
        cur.size == size &&
        cur.keyGap == gap &&
        _laidSplit == split &&
        _laidCompact == compact) {
      return cur;
    }
    _laidSplit = split;
    _laidCompact = compact;
    return _laid = KeyboardLayoutEngine.layout(def, size, keyGap: gap, split: split, compact: compact);
  }

  @override
  void dispose() {
    _text.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!identical(_themeOfCache, widget.theme)) {
      _themeOfCache = widget.theme;
      _text.clear();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final laid = _layout(size);
        widget.viewController.layout = laid;
        if (laid == null) return const SizedBox.expand();
        if (!identical(_notified, laid)) {
          _notified = laid;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted && identical(_notified, laid)) widget.session.onLayout(laid, widget.page);
          });
        }
        final swipe = widget.settings.swipe;
        final v = widget.viewController;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: v.onPointerDown,
          onPointerMove: v.onPointerMove,
          onPointerUp: v.onPointerUp,
          onPointerCancel: v.onPointerCancel,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.session.input.shift,
                      widget.session.spaceLabel,
                      widget.session.spaceLabelOverride,
                    ]),
                    builder: (context, _) => CustomPaint(
                      painter: KeysPainter(
                        laid: laid,
                        theme: widget.theme,
                        shift: widget.session.input.shift.value,
                        spaceLabel: widget.page == KeyboardPage.letters
                            ? widget.session.spaceLabelOverride.value ?? widget.session.spaceLabel.value
                            : null,
                        page: widget.page,
                        field: widget.field,
                        typing: widget.settings.typing,
                        animator: widget.animator,
                        textCache: _text,
                        onActivate: v.activateKey,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureTrailLayer(
                  controller: widget.trail,
                  theme: widget.theme,
                  trailWidth: swipe.trailWidth,
                  fadeMs: swipe.trailFadeMs,
                  showTrail: swipe.showTrail,
                  showPreview: swipe.livePreview,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
