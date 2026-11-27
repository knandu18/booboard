// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-D. The mic panel (PanelPlacement.keys: the suggestion strip stays). It shows a shape that
// grows with the voice level, the interim text, the language label (English) and the Stop / Cancel buttons, and it paints
// with KeyboardThemeData so it matches the keys in every theme.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../engine/lang/registry.dart';
import '../../keyboard/panels/keyboard_panel.dart';
import '../../keyboard/view/keyboard_metrics.dart';
import '../shared/panel_style.dart';
import 'voice_controller.dart';

/// The voice panel. [controller] is created when the panel opens and disposed when it closes.
class VoicePanel extends KeyboardPanel {
  VoicePanel({required this.controller, required this.openSettings, required this.openPacks});

  final VoiceController controller;

  /// Opens the voice settings screen and the model-packs screen (settings app routes).
  final VoidCallback openSettings;
  final VoidCallback openPacks;

  @override
  String get id => 'voice';

  @override
  PanelPlacement get placement => PanelPlacement.keys;

  @override
  Widget build(BuildContext context, PanelContext panel) =>
      VoicePanelView(controller: controller, panel: panel, openSettings: openSettings, openPacks: openPacks);

  @override
  void onClosed() => controller.dispose();
}

class VoicePanelView extends StatefulWidget {
  const VoicePanelView({
    super.key,
    required this.controller,
    required this.panel,
    required this.openSettings,
    required this.openPacks,
  });

  final VoiceController controller;
  final PanelContext panel;
  final VoidCallback openSettings;
  final VoidCallback openPacks;

  @override
  State<VoicePanelView> createState() => _VoicePanelViewState();
}

class _VoicePanelViewState extends State<VoicePanelView> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  bool get _motion => widget.panel.theme.motion.enabled;

  @override
  void initState() {
    super.initState();
    _syncSpin();
  }

  @override
  void didUpdateWidget(covariant VoicePanelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin();
  }

  void _syncSpin() {
    if (_motion) {
      if (!_spin.isAnimating) unawaited(_spin.repeat());
    } else {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final panel = widget.panel;
        final theme = panel.theme;
        final style = PanelStyle(theme);
        return SizedBox(
          width: panel.size.width,
          height: panel.size.height,
          child: Column(
            children: [
              _header(context, style),
              Expanded(child: _body(context, style)),
              _actions(context, style),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, PanelStyle style) {
    final c = widget.controller;
    final theme = widget.panel.theme;
    final label = languageInfo(c.language).englishName;
    return SizedBox(
      height: KeyboardMetrics.stripHeight + 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            PanelButton(
              semanticsLabel: 'Back to letters',
              width: 64,
              height: double.infinity,
              fill: theme.background,
              pressedFill: theme.suggestionHighlightFill,
              radius: BorderRadius.zero,
              onTap: widget.panel.close,
              child: Text('ABC', style: style.text(size: 14, color: theme.suggestionText)),
            ),
            const SizedBox(width: 6),
            // Voice typing works in English only, so the language is shown, not chosen.
            Expanded(
              child: Semantics(
                label: 'Voice typing in $label',
                excludeSemantics: true,
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style.text(size: 13, color: theme.suggestionText),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 14, color: theme.toolbarIcon),
                const SizedBox(width: 4),
                Text('On-device', style: style.hint(size: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, PanelStyle style) {
    final c = widget.controller;
    final theme = widget.panel.theme;
    final message = _message(c.phase, c.partial);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: LayoutBuilder(
              builder: (context, box) {
                final side = math.min(box.maxHeight, box.maxWidth).clamp(0.0, 132.0);
                return SizedBox.square(
                  dimension: side,
                  child: AnimatedBuilder(
                    animation: _spin,
                    builder: (context, _) => CustomPaint(
                      painter: _VoiceBlobPainter(
                        level: c.phase == VoicePhase.listening || c.phase == VoicePhase.stopping ? c.level : 0,
                        phase: _motion ? _spin.value * 2 * math.pi : 0,
                        color: theme.suggestionHighlightFill,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.mic,
                          size: side * 0.28,
                          color: theme.suggestionHighlightText,
                          semanticLabel: 'Microphone',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: style.text(size: 15, color: theme.suggestionText),
            ),
          ),
          // Keeps the message off the buttons below.
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  String _message(VoicePhase phase, String partial) {
    switch (phase) {
      case VoicePhase.disabled:
        return 'Voice typing is off. Turn it on in Voice settings.';
      case VoicePhase.checking:
        return 'Starting';
      case VoicePhase.listening:
        return partial.isEmpty ? 'Listening. Speak now.' : partial;
      case VoicePhase.stopping:
        return partial.isEmpty ? 'Finishing' : partial;
      case VoicePhase.cancelling:
        return 'Cancelling';
      case VoicePhase.finished:
        return 'Done';
      case VoicePhase.noPermission:
        return 'BooBoard needs the microphone to hear you. Allow it when asked, then try again.';
      case VoicePhase.noModel:
        return 'Voice typing runs on this phone and needs the voice pack (154 MB). BooBoard never goes online: '
            'your browser downloads the pack, BooBoard checks it here.';
      case VoicePhase.busy:
        return 'The microphone is busy in another app. Close it, then try again.';
      case VoicePhase.failed:
        return 'Voice typing could not start on this phone.';
    }
  }

  Widget _actions(BuildContext context, PanelStyle style) {
    final c = widget.controller;
    final theme = widget.panel.theme;
    final fill = theme.functionKey.fill;
    final pressed = theme.functionKey.pressedFill;
    final label = theme.functionKey.label;
    const gap = 6.0;

    PanelButton action(String semantics, String text, VoidCallback onTap, {bool primary = false}) => PanelButton(
      semanticsLabel: semantics,
      height: double.infinity,
      fill: primary ? theme.suggestionHighlightFill : fill,
      pressedFill: pressed,
      radius: style.radius(48),
      onTap: onTap,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style.text(size: 14, color: primary ? theme.suggestionHighlightText : label),
      ),
    );

    final List<Widget> buttons;
    switch (c.phase) {
      case VoicePhase.listening:
      case VoicePhase.checking:
        buttons = [
          Expanded(child: action('Cancel voice typing', 'Cancel', c.cancel)),
          const SizedBox(width: gap),
          Expanded(child: action('Stop and keep the text', 'Stop', c.stop, primary: true)),
        ];
      case VoicePhase.noModel:
        buttons = [
          Expanded(child: action('Get the voice pack', 'Get voice pack', widget.openPacks, primary: true)),
          const SizedBox(width: gap),
          Expanded(child: action('Close voice panel', 'Close', widget.panel.close)),
        ];
      case VoicePhase.disabled:
        buttons = [
          Expanded(child: action('Open voice settings', 'Voice settings', widget.openSettings, primary: true)),
          const SizedBox(width: gap),
          Expanded(child: action('Close voice panel', 'Close', widget.panel.close)),
        ];
      case VoicePhase.noPermission:
      case VoicePhase.busy:
      case VoicePhase.failed:
        buttons = [
          Expanded(child: action('Try voice typing again', 'Try again', c.begin, primary: true)),
          const SizedBox(width: gap),
          Expanded(child: action('Close voice panel', 'Close', widget.panel.close)),
        ];
      case VoicePhase.stopping:
      case VoicePhase.cancelling:
      case VoicePhase.finished:
        buttons = const [];
    }
    if (buttons.isEmpty) return const SizedBox(height: 56);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(height: 56, child: Row(children: buttons)),
    );
  }
}

/// A soft, wobbling blob that swells with the voice level (Material 3 Expressive shape language).
class _VoiceBlobPainter extends CustomPainter {
  const _VoiceBlobPainter({required this.level, required this.phase, required this.color});

  final double level;
  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.shortestSide / 2 * 0.6;
    final radius = base * (1 + 0.3 * level.clamp(0.0, 1.0));
    final path = Path();
    const steps = 120;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * 2 * math.pi;
      final wobble = 1 + 0.06 * math.sin(5 * t + phase) + 0.04 * math.sin(3 * t - phase * 1.3);
      final r = radius * wobble;
      final p = center + Offset(math.cos(t) * r, math.sin(t) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _VoiceBlobPainter old) => old.level != level || old.phase != phase || old.color != color;
}
