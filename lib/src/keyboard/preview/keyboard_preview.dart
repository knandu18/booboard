// SPDX-License-Identifier: GPL-3.0-or-later
//
// A static, non-interactive picture of the keyboard for the settings app (theme gallery cards and
// the editor). It paints with the keyboard's own layout engine and KeysPainter, so it looks like the
// real thing. It never touches KeyboardSession or the IME host: the settings engine has no IME.
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../core/input_field_info.dart';
import '../../packs/pack_repository.dart';
import '../../settings/booboard_settings.dart';
import '../../theme/keyboard_theme_data.dart';
import '../input/input_controller.dart';
import '../input/keyboard_page.dart';
import '../layout/layout_engine.dart';
import '../layout/layout_model.dart';
import '../layout/layout_repository.dart';
import '../view/key_press_animator.dart';
import '../view/keyboard_metrics.dart';
import '../view/keys_painter.dart';

/// Layouts are read from the bundle once for every preview in the app.
final LayoutRepository _previewLayouts = LayoutRepository(BundledPackRepository());

/// Samples shown in the strip mock. Fixed words, never user text.
const List<String> _sampleSuggestions = ['the', 'to', 'and'];

class KeyboardPreview extends StatefulWidget {
  const KeyboardPreview({
    super.key,
    required this.theme,
    required this.settings,
    this.layoutId = 'qwerty',
    this.height,
    this.showStrip = true,
    this.demoPress = false,
  });

  final KeyboardThemeData theme;
  final BooBoardSettings settings;

  /// Layout asset id (`assets/layouts/<id>.json`).
  final String layoutId;

  /// Height of the key rows. Null = the keyboard's own height for these settings.
  final double? height;

  /// Paints the suggestion strip mock above the keys.
  final bool showStrip;

  /// Presses one key every 1.6 s (the gallery hero card). Does nothing when the theme has no motion.
  final bool demoPress;

  @override
  State<KeyboardPreview> createState() => _KeyboardPreviewState();
}

class _KeyboardPreviewState extends State<KeyboardPreview> with SingleTickerProviderStateMixin {
  late final KeyPressAnimator _animator;
  final KeyTextCache _text = KeyTextCache();
  KeyboardThemeData? _textTheme;

  KeyboardLayoutDef? _base;
  bool _numberRow = false;
  KeyboardLayoutDef? _variant;
  LaidOutKeyboard? _laid;
  Timer? _demoTimer;
  Timer? _demoRelease;

  @override
  void initState() {
    super.initState();
    _animator = KeyPressAnimator(vsync: this, motion: widget.theme.motion);
    _loadLayout();
    _startDemo();
  }

  @override
  void didUpdateWidget(KeyboardPreview old) {
    super.didUpdateWidget(old);
    _animator.motion = widget.theme.motion;
    if (old.layoutId != widget.layoutId) {
      _base = null;
      _variant = null;
      _laid = null;
      _loadLayout();
    }
    if (old.demoPress != widget.demoPress) _startDemo();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _demoRelease?.cancel();
    _animator.dispose();
    _text.clear();
    super.dispose();
  }

  void _loadLayout() {
    final id = widget.layoutId;
    final cached = _previewLayouts.peek(id);
    if (cached != null) {
      _base = cached;
      return;
    }
    unawaited(
      _previewLayouts.load(id).then((def) {
        if (!mounted || id != widget.layoutId) return;
        setState(() => _base = def);
      }),
    );
  }

  /// The layout as the keyboard would show it: the number row is part of the letters page.
  KeyboardLayoutDef? _layoutFor(bool numberRow) {
    final base = _base;
    if (base == null) return null;
    if (_variant != null && _numberRow == numberRow) return _variant;
    _numberRow = numberRow;
    return _variant = numberRow ? LayoutVariants.withNumberRow(base) : base;
  }

  void _startDemo() {
    _demoTimer?.cancel();
    _demoTimer = null;
    if (!widget.demoPress || !widget.theme.motion.enabled) return;
    _demoTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) => _pressOne());
  }

  void _pressOne() {
    final laid = _laid;
    if (laid == null || laid.keys.isEmpty) return;
    // Presses the letter "e" when there is one, else the first key.
    final key = laid.keys.firstWhere((k) => k.def.output == 'e', orElse: () => laid.keys.first).index;
    _animator.press(key);
    _demoRelease?.cancel();
    _demoRelease = Timer(const Duration(milliseconds: 380), () => _animator.release(key));
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    if (!identical(_textTheme, theme)) {
      _textTheme = theme;
      _text.clear();
    }
    final def = _layoutFor(widget.settings.typing.numberRow);
    final rowsHeight = widget.height ?? KeyboardMetrics.rowsHeight(widget.settings, landscape: false);
    final stripHeight = widget.showStrip ? KeyboardMetrics.stripHeight : 0.0;

    return Semantics(
      label: 'Keyboard preview',
      container: true,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: _PreviewBackground(
            theme: theme,
            child: SizedBox(
              height: stripHeight + rowsHeight,
              child: Column(
                children: [
                  if (widget.showStrip) _StripMock(theme: theme, height: stripHeight),
                  Expanded(
                    child: def == null
                        ? const SizedBox.shrink()
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final size = constraints.biggest;
                              final laid = _laidFor(def, size, theme.keyGap);
                              return RepaintBoundary(
                                child: CustomPaint(
                                  painter: KeysPainter(
                                    laid: laid,
                                    theme: theme,
                                    shift: ShiftState.off,
                                    page: KeyboardPage.letters,
                                    field: InputFieldInfo.plainText,
                                    typing: widget.settings.typing,
                                    animator: _animator,
                                    textCache: _text,
                                  ),
                                  size: size,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  LaidOutKeyboard _laidFor(KeyboardLayoutDef def, Size size, double gap) {
    final cur = _laid;
    if (cur != null && identical(cur.layout, def) && cur.size == size && cur.keyGap == gap) return cur;
    return _laid = KeyboardLayoutEngine.layout(def, size, keyGap: gap);
  }
}

/// Solid colour, gradient or dimmed photo, as the keyboard paints it.
class _PreviewBackground extends StatelessWidget {
  const _PreviewBackground({required this.theme, required this.child});

  final KeyboardThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = theme.backgroundImagePath;
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.background, gradient: theme.backgroundGradient),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final layer in theme.backgroundLayers)
            Positioned.fill(
              child: DecoratedBox(decoration: BoxDecoration(gradient: layer)),
            ),
          if (path != null) ...[
            Positioned.fill(
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            if (theme.backgroundImageDim > 0)
              Positioned.fill(
                child: ColoredBox(color: Color.fromRGBO(0, 0, 0, theme.backgroundImageDim.clamp(0.0, 1.0))),
              ),
          ],
          child,
        ],
      ),
    );
  }
}

/// The suggestion strip: three chips, the middle one highlighted.
class _StripMock extends StatelessWidget {
  const _StripMock({required this.theme, required this.height});

  final KeyboardThemeData theme;
  final double height;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (var i = 0; i < _sampleSuggestions.length; i++) {
      final highlighted = i == 1;
      chips.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: highlighted ? theme.suggestionHighlightFill : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _sampleSuggestions[i],
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: theme.fontFamily,
                    fontWeight: theme.labelWeight,
                    fontVariations: theme.labelFontVariations,
                    fontSize: 15,
                    color: highlighted ? theme.suggestionHighlightText : theme.suggestionText,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: Row(children: chips),
    );
  }
}
