// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: orchestrator since Wave 2 (Wave 1-A wrote it). The keyboard UI shown
// in the IME window. Features (panels, modes) plug in through [KeyboardFeature];
// a feature's [KeyboardFrame] decides the window layout (one-handed, floating).
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../bridge/messages.g.dart';
import '../core/keyboard_services.dart';
import '../core/log.dart';
import '../settings/booboard_settings.dart';
import '../theme/keyboard_theme_data.dart';
import '../theme/theme_resolver.dart';
import 'keyboard_session.dart';
import 'panels/keyboard_panel.dart';
import 'view/keyboard_metrics.dart';
import 'view/keyboard_view.dart';

export 'panels/keyboard_panel.dart';
export 'view/keyboard_metrics.dart' show KeyboardMetrics;

class KeyboardApp extends StatefulWidget {
  const KeyboardApp({super.key, required this.services, this.hooks = const KeyboardHooks(), this.features = const []});

  final KeyboardServices services;

  /// Hooks that win over the features' hooks (tests use this).
  final KeyboardHooks hooks;

  /// Attached in order once the session exists (see keyboard_main.dart).
  final List<KeyboardFeature> features;

  @override
  State<KeyboardApp> createState() => _KeyboardAppState();
}

class _KeyboardAppState extends State<KeyboardApp> {
  late final KeyboardSession _session;
  late final KeyboardHooks _hooks;
  KeyboardFrame? _frame;
  WindowLayoutMessage? _sentLayout;
  int? _sentNavBarArgb;

  // Theme cache: resolving can be expensive, so only redo it when an input changed.
  KeyboardThemeData? _theme;
  AppearanceSettings? _themeAppearance;
  SystemColorsMessage? _themeColors;
  bool? _themeDark;
  bool? _themeReduce;

  KeyboardServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    _session = KeyboardSession(s);
    final featureHooks = <KeyboardHooks>[widget.hooks];
    for (final f in widget.features) {
      try {
        featureHooks.add(f.attach(_session));
        _frame ??= f.frame;
      } on Object catch (e) {
        BooBoardLog.w('Keyboard', 'feature attach failed', e.runtimeType);
      }
    }
    _hooks = KeyboardHooks.merge(featureHooks);
    s.settings.addListener(_rebuild);
    s.events.metrics.addListener(_rebuild);
    _session.systemColors.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    s.settings.removeListener(_rebuild);
    s.events.metrics.removeListener(_rebuild);
    _session.systemColors.removeListener(_rebuild);
    for (final f in widget.features) {
      try {
        f.detach();
      } on Object catch (e) {
        BooBoardLog.w('Keyboard', 'feature detach failed', e.runtimeType);
      }
    }
    _session.dispose();
    super.dispose();
  }

  KeyboardThemeData _resolveTheme(BuildContext context) {
    final appearance = s.settings.value.appearance;
    final colors = _session.systemColors.value;
    final metrics = s.events.metrics.value;
    final dark = metrics?.isNightMode ?? MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final cached = _theme;
    if (cached != null &&
        identical(appearance, _themeAppearance) &&
        identical(colors, _themeColors) &&
        dark == _themeDark &&
        reduce == _themeReduce) {
      return cached;
    }
    _themeAppearance = appearance;
    _themeColors = colors;
    _themeDark = dark;
    _themeReduce = reduce;
    return _theme = resolveKeyboardTheme(
      appearance: appearance,
      systemColors: colors,
      systemDark: dark,
      disableAnimations: reduce,
      customThemesDirectory: s.dataDirectory == null ? null : '${s.dataDirectory}/themes',
    );
  }

  static bool _sameLayout(WindowLayoutMessage a, WindowLayoutMessage b) {
    final ra = a.floatingRect;
    final rb = b.floatingRect;
    final sameRect =
        (ra == null && rb == null) ||
        (ra != null &&
            rb != null &&
            ra.left == rb.left &&
            ra.top == rb.top &&
            ra.width == rb.width &&
            ra.height == rb.height);
    return a.mode == b.mode && a.heightDp == b.heightDp && sameRect;
  }

  /// Dart owns the window layout: the total docked height (content plus the bottom inset Flutter
  /// applies) or the floating rect. Sent only when it changes.
  void _syncWindowLayout(WindowLayoutMessage layout) {
    final last = _sentLayout;
    if (last != null && _sameLayout(last, layout)) return;
    _sentLayout = layout;
    try {
      unawaited(
        s.host.setWindowLayout(layout).catchError((Object e) {
          _sentLayout = null;
          BooBoardLog.w('Keyboard', 'window layout failed', e.runtimeType);
        }),
      );
    } on Object catch (e) {
      _sentLayout = null;
      BooBoardLog.w('Keyboard', 'window layout failed', e.runtimeType);
    }
  }

  /// Lets Kotlin pick light or dark navigation-bar icons for the keyboard's background.
  void _syncNavigationBar(KeyboardThemeData theme) {
    final argb = theme.background.toARGB32();
    if (argb == _sentNavBarArgb) return;
    _sentNavBarArgb = argb;
    try {
      unawaited(
        s.host.setNavigationBarStyle(argb).catchError((Object e) {
          _sentNavBarArgb = null;
          BooBoardLog.w('Keyboard', 'navigation bar style failed', e.runtimeType);
        }),
      );
    } on Object catch (e) {
      _sentNavBarArgb = null;
      BooBoardLog.w('Keyboard', 'navigation bar style failed', e.runtimeType);
    }
  }

  /// The real screen in dp. MediaQuery here is the IME window, which is only as tall as the keyboard,
  /// so modes that size their own window (floating) need the display size from the window metrics.
  Size _screenSize(BuildContext context) {
    final m = s.events.metrics.value;
    final view = MediaQuery.sizeOf(context);
    if (m == null || m.density <= 0) return view;
    return Size(view.width, math.max(view.height, m.screenHeightPx / m.density));
  }

  @override
  Widget build(BuildContext context) {
    final settings = s.settings.value;
    final theme = _resolveTheme(context);
    _syncNavigationBar(theme);
    final landscape = s.events.metrics.value?.isLandscape ?? false;
    final compact = KeyboardMetrics.isCompact(s.events.metrics.value);
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    final keyboard = KeyboardView(session: _session, theme: theme, settings: settings, hooks: _hooks);
    final background = _Background(theme: theme);

    final frame = _frame;
    final Widget content;
    if (frame != null) {
      final info = FrameInfo(
        settings: settings,
        theme: theme,
        screenSize: _screenSize(context),
        landscape: landscape,
        bottomInset: inset,
        contentHeight: KeyboardMetrics.contentHeight(settings, landscape: landscape, compact: compact),
      );
      final result = frame.build(context, info, keyboard: keyboard, background: background);
      _syncWindowLayout(result.layout);
      content = result.child;
    } else {
      _syncWindowLayout(
        WindowLayoutMessage(
          mode: WindowMode.docked,
          heightDp: KeyboardMetrics.totalHeight(settings, landscape: landscape, bottomInset: inset, compact: compact),
        ),
      );
      content = Stack(
        fit: StackFit.expand,
        children: [
          background,
          Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: Align(alignment: Alignment.topCenter, child: keyboard),
          ),
        ],
      );
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: content,
      ),
    );
  }
}

/// Solid colour, gradient (with optional glow layers) or image (with dim). Also fills the area under the
/// navigation bar.
class _Background extends StatelessWidget {
  const _Background({required this.theme});

  final KeyboardThemeData theme;

  @override
  Widget build(BuildContext context) {
    final path = theme.backgroundImagePath;
    final layers = theme.backgroundLayers;
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.background, gradient: theme.backgroundGradient),
      child: path == null && layers.isEmpty
          ? null
          : Stack(
              fit: StackFit.expand,
              children: [
                for (final layer in layers) DecoratedBox(decoration: BoxDecoration(gradient: layer)),
                if (path != null) ...[
                  Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  if (theme.backgroundImageDim > 0)
                    ColoredBox(color: Color.fromRGBO(0, 0, 0, theme.backgroundImageDim.clamp(0.0, 1.0))),
                ],
              ],
            ),
    );
  }
}
