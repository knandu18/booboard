// SPDX-License-Identifier: GPL-3.0-or-later
//
// The keyboard frame for the modes: docked (full width, centred on tablets), one-handed (keyboard
// on one side, a strip of buttons on the other), floating (a rounded card that moves and resizes,
// inside a transparent window) and the height bar. The plain docked layout is returned unchanged.
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../settings/booboard_settings.dart';
import '../../theme/keyboard_theme_data.dart';
import '../panels/keyboard_panel.dart';
import 'mode_geometry.dart';
import 'modes_controller.dart';
import 'modes_plan.dart';

class ModesFrame implements KeyboardFrame {
  ModesFrame(this.controller);

  final ModesController controller;

  @override
  FrameResult build(BuildContext context, FrameInfo info, {required Widget keyboard, required Widget background}) {
    controller.observe(info);
    final plan = controller.plan!;
    return FrameResult(
      layout: plan.message,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _ModesBody(controller: controller, keyboard: keyboard, background: background),
      ),
    );
  }
}

class _ModesBody extends StatelessWidget {
  const _ModesBody({required this.controller, required this.keyboard, required this.background});

  final ModesController controller;
  final Widget keyboard;
  final Widget background;

  @override
  Widget build(BuildContext context) {
    final info = controller.info!;
    final plan = controller.plan!;
    final floating = plan.floating;
    if (floating != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fromRect(
            rect: floating,
            child: _FloatingCard(
              controller: controller,
              info: info,
              plan: plan,
              keyboard: keyboard,
              background: background,
            ),
          ),
        ],
      );
    }
    if (plan.isPlainDocked) {
      return Stack(
        fit: StackFit.expand,
        children: [
          background,
          Padding(
            padding: EdgeInsets.only(bottom: plan.bottomInset),
            child: Align(alignment: Alignment.topCenter, child: keyboard),
          ),
        ],
      );
    }
    final motion = info.theme.motion.enabled;
    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        Padding(
          padding: EdgeInsets.only(bottom: plan.bottomInset),
          child: Align(
            alignment: Alignment.topCenter,
            // The width eases to a new value (one-handed, tablet centring) instead of jumping.
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: plan.keyboardW),
              duration: motion ? const Duration(milliseconds: 260) : Duration.zero,
              curve: Curves.easeOutCubic,
              builder: (context, width, _) =>
                  _DockedBody(controller: controller, info: info, plan: plan, width: width, keyboard: keyboard),
            ),
          ),
        ),
      ],
    );
  }
}

/// Docked and one-handed: the optional height bar above a row with the keyboard and, when one-handed,
/// the strip of buttons on the free side.
class _DockedBody extends StatelessWidget {
  const _DockedBody({
    required this.controller,
    required this.info,
    required this.plan,
    required this.width,
    required this.keyboard,
  });

  final ModesController controller;
  final FrameInfo info;
  final ModesPlan plan;
  final double width;
  final Widget keyboard;

  @override
  Widget build(BuildContext context) {
    final theme = info.theme;
    final side = info.settings.modes.oneHanded;
    final stripWidth = plan.screenW - width;
    final kb = _KeyboardBox(width: width, naturalH: plan.naturalH, boxH: plan.keyboardH, child: keyboard);
    final strip = side == OneHandedMode.off || stripWidth <= 0
        ? null
        : SizedBox(
            width: stripWidth,
            height: plan.keyboardH,
            child: _OneHandedStrip(controller: controller, theme: theme),
          );
    final row = Row(
      mainAxisAlignment: plan.wide ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (side == OneHandedMode.right && strip != null) strip,
        kb,
        if (side == OneHandedMode.left && strip != null) strip,
      ],
    );
    return SizedBox(
      width: plan.screenW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (plan.topBar)
            SizedBox(
              width: plan.screenW,
              height: kTopBarHeight,
              child: _HeightBar(controller: controller, plan: plan, theme: theme),
            ),
          row,
        ],
      ),
    );
  }
}

/// Floating: a rounded card with a move bar on top and the keyboard below it, scaled to the card.
class _FloatingCard extends StatelessWidget {
  const _FloatingCard({
    required this.controller,
    required this.info,
    required this.plan,
    required this.keyboard,
    required this.background,
  });

  final ModesController controller;
  final FrameInfo info;
  final ModesPlan plan;
  final Widget keyboard;
  final Widget background;

  @override
  Widget build(BuildContext context) {
    final theme = info.theme;
    final rect = plan.floating!;
    final fraction = rect.width / plan.screenW;
    final radius = BorderRadius.circular(theme.keyCornerRadius + 10);
    final top = controller.resizing
        ? _HeightBar(controller: controller, plan: plan, theme: theme)
        : _MoveBar(controller: controller, theme: theme);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            background,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: rect.width, height: kTopBarHeight, child: top),
                SizedBox(
                  width: rect.width,
                  height: plan.keyboardH * fraction,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topLeft,
                    child: _KeyboardBox(
                      width: plan.screenW,
                      naturalH: plan.naturalH,
                      boxH: plan.keyboardH,
                      child: keyboard,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The keyboard at [width] x [boxH]. When the height is previewed the keyboard is drawn scaled
/// vertically inside its natural box, so the keys follow the finger before the settings are written.
class _KeyboardBox extends StatelessWidget {
  const _KeyboardBox({required this.width, required this.naturalH, required this.boxH, required this.child});

  final double width;
  final double naturalH;
  final double boxH;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if ((boxH - naturalH).abs() < 0.5) {
      return SizedBox(width: width, height: naturalH, child: child);
    }
    return SizedBox(
      width: width,
      height: boxH,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: width,
          maxWidth: width,
          minHeight: naturalH,
          maxHeight: naturalH,
          child: Transform(
            transform: Matrix4.diagonal3Values(1, boxH / naturalH, 1),
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, height: naturalH, child: child),
          ),
        ),
      ),
    );
  }
}

/// Floating move bar: drag to move, drag the right grip to change the width, Dock returns to docked.
class _MoveBar extends StatelessWidget {
  const _MoveBar({required this.controller, required this.theme});

  final ModesController controller;
  final KeyboardThemeData theme;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _DragArea(
          label: 'Move keyboard',
          icon: null,
          theme: theme,
          onStart: controller.rectDragStart,
          onUpdate: (o) => controller.rectDragMove(o.dx, o.dy),
          onEnd: controller.rectDragEnd,
        ),
      ),
      SizedBox(
        width: kTopBarHeight,
        child: _DragArea(
          label: 'Resize keyboard width',
          icon: Icons.open_in_full,
          theme: theme,
          onStart: controller.rectDragStart,
          onUpdate: (o) => controller.rectWidthDrag(o.dx),
          onEnd: controller.rectDragEnd,
        ),
      ),
      _Pill(label: 'Dock', theme: theme, onTap: () => controller.updateModes((m) => m.copyWith(floating: false))),
      const SizedBox(width: 6),
    ],
  );
}

/// Height bar: drag the grip up for taller, down for shorter. Reset sets 100%; Done closes the bar.
class _HeightBar extends StatelessWidget {
  const _HeightBar({required this.controller, required this.plan, required this.theme});

  final ModesController controller;
  final ModesPlan plan;
  final KeyboardThemeData theme;

  @override
  Widget build(BuildContext context) {
    final percent = (plan.scale * 100).round();
    return LayoutBuilder(
      builder: (context, constraints) {
        // The percentage goes first on narrow cards (60% floating width), so the buttons always fit.
        final showPercent = constraints.maxWidth >= 300;
        return Row(
          children: [
            Expanded(
              child: _DragArea(
                label: 'Drag to change keyboard height',
                icon: Icons.unfold_more,
                theme: theme,
                onStart: controller.heightDragStart,
                onUpdate: (o) => controller.heightDragUpdate(o.dy),
                onEnd: controller.heightDragEnd,
              ),
            ),
            if (showPercent)
              Text(
                '$percent%',
                maxLines: 1,
                style: TextStyle(fontSize: 13, color: theme.suggestionText, decoration: TextDecoration.none),
              ),
            _Pill(label: 'Reset', theme: theme, onTap: controller.resetHeight),
            _Pill(label: 'Done', theme: theme, onTap: controller.endResize),
            const SizedBox(width: 6),
          ],
        );
      },
    );
  }
}

/// One-handed strip: move the keyboard to the other side, or expand it to full width.
class _OneHandedStrip extends StatelessWidget {
  const _OneHandedStrip({required this.controller, required this.theme});

  final ModesController controller;
  final KeyboardThemeData theme;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _IconButton(
        icon: Icons.swap_horiz,
        label: 'Move keyboard to other side',
        theme: theme,
        onTap: () => controller.updateModes(
          (m) => m.copyWith(oneHanded: m.oneHanded == OneHandedMode.left ? OneHandedMode.right : OneHandedMode.left),
        ),
      ),
      _IconButton(
        icon: Icons.fullscreen,
        label: 'Full width keyboard',
        theme: theme,
        onTap: () => controller.updateModes((m) => m.copyWith(oneHanded: OneHandedMode.off)),
      ),
    ],
  );
}

/// A region that reports the total pointer travel since the touch went down. A raw Listener, so it
/// does not wait for the gesture slop and does not fight the keyboard's own touch handling.
class _DragArea extends StatefulWidget {
  const _DragArea({
    required this.label,
    required this.icon,
    required this.theme,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  final String label;
  final IconData? icon;
  final KeyboardThemeData theme;
  final VoidCallback onStart;
  final void Function(Offset total) onUpdate;
  final VoidCallback onEnd;

  @override
  State<_DragArea> createState() => _DragAreaState();
}

class _DragAreaState extends State<_DragArea> {
  Offset? _origin;

  void _end() {
    if (_origin == null) return;
    _origin = null;
    widget.onEnd();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    button: true,
    excludeSemantics: true,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        if (_origin != null) return;
        _origin = e.position;
        widget.onStart();
      },
      onPointerMove: (e) {
        final origin = _origin;
        if (origin != null) widget.onUpdate(e.position - origin);
      },
      onPointerUp: (_) => _end(),
      onPointerCancel: (_) => _end(),
      child: SizedBox(
        height: kTopBarHeight,
        child: Center(
          child: widget.icon == null
              ? Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(color: widget.theme.toolbarIcon, borderRadius: BorderRadius.circular(3)),
                )
              : Icon(widget.icon, size: 22, color: widget.theme.toolbarIcon),
        ),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.theme, required this.onTap});

  final String label;
  final KeyboardThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: kTopBarHeight,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: theme.suggestionHighlightFill, borderRadius: BorderRadius.circular(18)),
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: theme.suggestionHighlightText, decoration: TextDecoration.none),
            ),
          ),
        ),
      ),
    ),
  );
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.label, required this.theme, required this.onTap});

  final IconData icon;
  final String label;
  final KeyboardThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: kTopBarHeight,
        width: double.infinity,
        child: Center(child: Icon(icon, size: 22, color: theme.toolbarIcon)),
      ),
    ),
  );
}
