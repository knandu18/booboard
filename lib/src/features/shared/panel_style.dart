// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Shared look for the emoji, clipboard and editing panels. Everything is painted
// with KeyboardThemeData (PanelContext.theme), so the panels match the keys in every theme.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/keyboard_theme_data.dart';

/// Theme-derived styles for a panel.
class PanelStyle {
  const PanelStyle(this.theme);

  final KeyboardThemeData theme;

  /// Labels in the panel's font and weight.
  TextStyle text({double size = 14, Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: theme.fontFamily,
    fontSize: size,
    color: color ?? theme.letterKey.label,
    fontWeight: weight ?? theme.labelWeight,
    height: 1.2,
  );

  /// Secondary text (hints, empty states).
  TextStyle hint({double size = 13}) => text(size: size, color: theme.toolbarIcon, weight: FontWeight.w400);

  /// Corner radius for a control whose shorter side is [side] (keyCornerRadius 0.5 gives a pill).
  BorderRadius radius(double side) => BorderRadius.circular(math.min(theme.keyCornerRadius * side, side / 2));
}

/// A tappable panel control with press feedback. With [repeat] it fires once on touch-down and keeps
/// firing while held (arrow keys, delete), like a hardware key.
/// See-through fill for panel cells and bar buttons, so the keyboard background (glass, gradient or picture)
/// shows through instead of a solid tile in the board's base colour.
const Color kPanelClear = Color(0x00000000);

class PanelButton extends StatefulWidget {
  const PanelButton({
    super.key,
    required this.semanticsLabel,
    required this.child,
    required this.fill,
    required this.pressedFill,
    this.width,
    this.height = 56,
    this.radius,
    this.onTap,
    this.onLongPress,
    this.repeat = false,
    this.selected = false,
  });

  final String semanticsLabel;
  final Widget child;
  final Color fill;
  final Color pressedFill;
  final double? width;
  final double? height;
  final BorderRadius? radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool repeat;
  final bool selected;

  /// Pause before a held key starts repeating, and the gap between repeats.
  static const Duration repeatDelay = Duration(milliseconds: 380);
  static const Duration repeatInterval = Duration(milliseconds: 55);

  @override
  State<PanelButton> createState() => _PanelButtonState();
}

class _PanelButtonState extends State<PanelButton> {
  bool _down = false;
  Timer? _startTimer;
  Timer? _repeatTimer;

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  void _stopRepeat() {
    _startTimer?.cancel();
    _startTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _setDown(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  void _onDown() {
    _setDown(true);
    if (!widget.repeat) return;
    widget.onTap?.call();
    _startTimer = Timer(PanelButton.repeatDelay, () {
      _repeatTimer = Timer.periodic(PanelButton.repeatInterval, (_) => widget.onTap?.call());
    });
  }

  void _onUp() {
    _stopRepeat();
    _setDown(false);
    if (!widget.repeat) widget.onTap?.call();
  }

  void _onCancel() {
    _stopRepeat();
    _setDown(false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final fill = _down || widget.selected ? widget.pressedFill : widget.fill;
    // The size is a plain SizedBox: an AnimatedContainer cannot tween between unbounded and fixed sizes
    // when one button is reused for a different width (for example a tab switch).
    final decorated = SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fill, borderRadius: widget.radius ?? BorderRadius.circular(12)),
        child: widget.child,
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _onDown() : null,
        onTapUp: enabled ? (_) => _onUp() : null,
        onTapCancel: enabled ? _onCancel : null,
        onLongPress: widget.onLongPress,
        child: decorated,
      ),
    );
  }
}

/// An on/off switch that paints with the theme (no Material needed in the keyboard window).
class PanelSwitch extends StatelessWidget {
  const PanelSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.theme,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final KeyboardThemeData theme;

  @override
  Widget build(BuildContext context) {
    const width = 46.0;
    const height = 26.0;
    return Semantics(
      toggled: value,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: width,
              height: height,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? theme.actionKey.fill : theme.functionKey.fill,
                borderRadius: BorderRadius.circular(height / 2),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                child: Container(
                  width: height - 6,
                  height: height - 6,
                  decoration: BoxDecoration(
                    color: value ? theme.actionKey.label : theme.toolbarIcon,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
