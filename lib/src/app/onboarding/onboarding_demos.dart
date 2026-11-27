// SPDX-License-Identifier: GPL-3.0-or-later
//
// Small looping demos for the first two setup steps, copied from Android 16's own screens (checked on
// the API 37 emulator, 2026-11-26): after "Open keyboard settings", switch BooBoard on in "Keyboard
// apps", tap OK on the warning, tap OK on the "after a reboot" note, then come back; after "Choose
// keyboard", pick BooBoard in the bottom sheet and the keyboard appears. A lime pointer shows where to
// tap. Drawn with widgets, not GIFs, so they stay sharp, follow the language and hold still when
// animations are turned off. Every element sits at a fixed spot so the pointer lands on it exactly.
import 'package:material_ui/material_ui.dart';

import 'booboard_mascot.dart';

import 'package:booboard/src/app/l10n.dart';

const double _cardW = 268, _cardH = 236;
const Color _sysInk = Color(0xFF1B1B1F);
const Color _sysMuted = Color(0xFF6B6671);
const Color _sysAccent = Color(0xFF3F5B9A);
const Color _sysPage = Color(0xFFF4F1F8);
const Color _sysCard = Color(0xFFFCFAFE);
const Color _sysDialog = Color(0xFFECE8F1);
const Color _sysOutline = Color(0xFF7A7581);
const Color _graphite = Color(0xFF2E2A24);

/// A looping timeline in seconds. Still (at [stillAt] seconds) when animations are off.
class _Loop extends StatefulWidget {
  const _Loop({required this.seconds, required this.stillAt, required this.builder});

  final double seconds;
  final double stillAt;
  final Widget Function(BuildContext context, double s) builder;

  @override
  State<_Loop> createState() => _LoopState();
}

class _LoopState extends State<_Loop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.seconds * 1000).round()),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.builder(context, widget.stillAt);
    return AnimatedBuilder(animation: _c, builder: (context, _) => widget.builder(context, _c.value * widget.seconds));
  }
}

/// 0 before [a], 1 after [b] (seconds), eased in between.
double _ramp(double s, double a, double b) => Curves.easeInOut.transform(((s - a) / (b - a)).clamp(0.0, 1.0));

/// Visible between [a] and [b], fading over [fade] seconds at each end.
double _window(double s, double a, double b, {double fade = 0.2}) =>
    _ramp(s, a - fade, a) * (1 - _ramp(s, b, b + fade));

/// The pointer's path: it rests at each point and glides to the next over the given seconds.
Offset _path(double s, Offset start, List<(double, double, Offset)> moves) {
  var at = start;
  for (final (from, to, target) in moves) {
    if (s <= from) return at;
    at = Offset.lerp(at, target, _ramp(s, from, to))!;
    if (s < to) return at;
    at = target;
  }
  return at;
}

/// How far into a tap at [tap] seconds we are: 0..1 over 0.45 s, else null.
double? _tapPhase(double s, List<double> taps) {
  for (final t in taps) {
    if (s >= t && s < t + 0.45) return (s - t) / 0.45;
  }
  return null;
}

class _Card extends StatelessWidget {
  const _Card({required this.children, this.color = _sysPage});

  final List<Widget> children;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: _cardW,
    height: _cardH,
    clipBehavior: Clip.antiAlias,
    // A faint ink outline keeps the card visible as a screen, also when it shows the lime app.
    foregroundDecoration: BoxDecoration(
      border: Border.all(color: BooColors.ink.withValues(alpha: 0.14), width: 1.5),
      borderRadius: BorderRadius.circular(24),
    ),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
    child: DefaultTextStyle(
      style: const TextStyle(fontSize: 12, color: _sysInk, fontFamily: 'GoogleSansFlex', height: 1.3),
      child: Stack(clipBehavior: Clip.none, children: children),
    ),
  );
}

/// Android 16's switch: an outlined track with a small grey knob when off, a filled track with a
/// larger white knob when on.
class _Switch extends StatelessWidget {
  const _Switch({required this.on});

  final double on;

  @override
  Widget build(BuildContext context) {
    final knob = 11 + 2 * on;
    return Container(
      width: 36,
      height: 21,
      decoration: BoxDecoration(
        color: Color.lerp(Colors.transparent, _sysAccent, on),
        border: Border.all(color: Color.lerp(_sysOutline, _sysAccent, on)!, width: 2),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Align(
        alignment: Alignment(-0.75 + 1.5 * on, 0),
        child: Container(
          width: knob,
          height: knob,
          decoration: BoxDecoration(color: Color.lerp(_sysOutline, Colors.white, on), shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// One row of the Keyboard apps list: icon, name, chevron, divider, switch. 44 high.
class _AppRow extends StatelessWidget {
  const _AppRow({required this.icon, required this.name, required this.on, this.bold = false});

  final Widget icon;
  final String name;
  final double on;
  final bool bold;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        const SizedBox(width: 10),
        SizedBox.square(dimension: 24, child: icon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
          ),
        ),
        const Text('›', style: TextStyle(fontSize: 14, color: Color(0xFF44404A))),
        Container(
          width: 1,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: const Color(0xFFCCC7D2),
        ),
        _Switch(on: on),
        const SizedBox(width: 8),
      ],
    ),
  );
}

/// An Android dialog at [top], [height] high, with its two buttons at the bottom right.
class _Dialog extends StatelessWidget {
  const _Dialog({required this.top, required this.height, required this.opacity, required this.children});

  final double top;
  final double height;
  final double opacity;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Positioned(
      left: 14,
      right: 14,
      top: top,
      height: height,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: 0.94 + 0.06 * opacity,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(color: _sysDialog, borderRadius: BorderRadius.circular(22)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...children,
                const Spacer(),
                SizedBox(
                  height: 26,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _DialogButton(label: l10n.cancel, filled: false),
                      const SizedBox(width: 6),
                      _DialogButton(label: l10n.onboardingDemoOk, filled: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 38),
    height: 26,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: filled ? _sysAccent : null,
      border: filled ? null : Border.all(color: const Color(0xFF8E8A94)),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: filled ? Colors.white : _sysAccent),
    ),
  );
}

/// The lime pointer: an arrow with an ink outline, its tip at [tip]. It dips when it taps, and an ink
/// ring spreads from the tip.
class _Pointer extends StatelessWidget {
  const _Pointer({required this.tip, required this.opacity, required this.tap});

  final Offset tip;
  final double opacity;

  /// 0..1 through a tap, or null.
  final double? tap;

  static const double _size = 26;
  static const Offset _tipInBox = Offset(4.3, 3.3);

  @override
  Widget build(BuildContext context) {
    final t = tap;
    final press = t == null ? 0.0 : (t < 0.35 ? t / 0.35 : (1 - (t - 0.35) / 0.65)).clamp(0.0, 1.0);
    return Positioned(
      left: tip.dx - 12,
      top: tip.dy - 12,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: SizedBox(
            width: _size + 12,
            height: _size + 12,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (t != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Opacity(
                      opacity: 0.7 * (1 - t),
                      child: Transform.scale(
                        scale: 0.4 + 1.2 * t,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: BooColors.ink, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 12 - _tipInBox.dx,
                  top: 12 - _tipInBox.dy,
                  child: Transform.scale(
                    scale: 1 - 0.22 * press,
                    alignment: const Alignment(-0.67, -0.75),
                    child: const CustomPaint(size: Size.square(_size), painter: _ArrowPainter()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final arrow = Path()
      ..moveTo(4, 3)
      ..lineTo(21, 10.5)
      ..lineTo(13, 13)
      ..lineTo(10.5, 21)
      ..close();
    canvas.drawPath(arrow, Paint()..color = BooColors.lime);
    canvas.drawPath(
      arrow,
      Paint()
        ..color = BooColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => false;
}

/// Caption pills under a demo. The current one is ink with lime text, the others pale.
class _Captions extends StatelessWidget {
  const _Captions({required this.labels, required this.current});

  final List<String> labels;
  final int current;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < labels.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: i == current ? BooColors.ink : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: i == current ? BooColors.lime : _graphite,
              ),
            ),
          ),
      ],
    ),
  );
}

/// A dark scrim over the system screen while a dialog or sheet shows.
Widget _scrim(double v) => Positioned.fill(
  child: IgnorePointer(
    child: ColoredBox(color: Colors.black.withValues(alpha: 0.32 * v)),
  ),
);

/// Boo's icon: black Boo on a lime circle.
class _BooIcon extends StatelessWidget {
  const _BooIcon();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(color: BooColors.lime, shape: BoxShape.circle),
    child: CustomPaint(painter: BooPainter(pose: BooBoardPose.open, decorations: false)),
  );
}

/// Step 1: switch BooBoard on, tap OK on the warning and on the note, come back. 8.6 s loop.
class EnableDemo extends StatelessWidget {
  const EnableDemo({super.key});

  // Fixed spots in the card (pointer tips).
  static const Offset _start = Offset(150, 250), _switch = Offset(225, 120), _ok1 = Offset(222, 145);
  static const Offset _ok2 = Offset(222, 129), _back = Offset(26, 28);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final captions = [l10n.onboardingDemoSwitchOn, l10n.onboardingDemoTapOk, l10n.onboardingDemoComeBack];
    return Semantics(
      label: captions.join(', '),
      child: ExcludeSemantics(
        child: _Loop(
          seconds: 8.6,
          stillAt: 2.9,
          builder: (context, s) {
            final tip = _path(s, _start, const [
              (0.3, 1.1, _switch),
              (2.1, 2.85, _ok1),
              (3.9, 4.55, _ok2),
              (5.3, 6.1, _back),
            ]);
            final pointer = _ramp(s, 0, 0.25) * (1 - _ramp(s, 7.0, 7.3));
            final dialog1 = _window(s, 1.4, 3.05, fade: 0.2);
            final dialog2 = _window(s, 3.35, 4.7, fade: 0.2);
            final scrim = _window(s, 1.4, 4.7, fade: 0.2);
            final on = _ramp(s, 4.7, 4.95);
            final app = _ramp(s, 6.3, 6.75);
            final step = s < 1.4 ? 0 : (s < 5.0 ? 1 : 2);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Card(
                  children: [
                    // Android's Keyboard apps page.
                    Positioned(
                      left: 12,
                      top: 14,
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: Color(0xFFE6E1EC), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_back, size: 15, color: _sysInk),
                          ),
                          const SizedBox(width: 10),
                          Text(l10n.onboardingDemoKeyboards, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 54,
                      child: Container(
                        decoration: BoxDecoration(color: _sysCard, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            _AppRow(
                              icon: const DecoratedBox(
                                decoration: BoxDecoration(color: Color(0xFFD7DEF5), shape: BoxShape.circle),
                              ),
                              name: l10n.onboardingDemoOtherKeyboard,
                              on: 1,
                            ),
                            const Divider(height: 0, thickness: 2, color: _sysPage),
                            _AppRow(icon: const _BooIcon(), name: l10n.appName, on: on, bold: true),
                          ],
                        ),
                      ),
                    ),
                    if (scrim > 0) _scrim(scrim),
                    if (dialog1 > 0)
                      _Dialog(
                        top: 46,
                        height: 124,
                        opacity: dialog1,
                        children: [
                          Text(l10n.onboardingDemoAttention, style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            l10n.onboardingDemoAttentionBody,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: _sysMuted),
                          ),
                        ],
                      ),
                    if (dialog2 > 0)
                      _Dialog(
                        top: 60,
                        height: 104,
                        opacity: dialog2,
                        children: [
                          Text(
                            l10n.onboardingDemoRebootNote,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5),
                          ),
                        ],
                      ),
                    // Back in BooBoard: the app slides in from the right.
                    if (app > 0)
                      Positioned(
                        left: _cardW * (1 - app),
                        top: 0,
                        width: _cardW,
                        height: _cardH,
                        child: ColoredBox(
                          color: BooColors.lime,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox.square(
                                dimension: 76,
                                child: CustomPaint(painter: BooPainter(pose: BooBoardPose.open, decorations: false)),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: BooColors.ink,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l10n.onboardingKeyboardOn,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: BooColors.lime),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    _Pointer(tip: tip, opacity: pointer, tap: _tapPhase(s, const [1.2, 2.95, 4.6, 6.15])),
                  ],
                ),
                _Captions(labels: captions, current: step),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Step 2: pick BooBoard in Android's bottom sheet; the keyboard slides up. 6.4 s loop.
class SwitchDemo extends StatelessWidget {
  const SwitchDemo({super.key});

  static const Offset _start = Offset(150, 250), _option = Offset(150, 194), _field = Offset(134, 112);
  static const double _sheetH = 132;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final captions = [l10n.onboardingDemoPick, l10n.onboardingDemoStartTyping];
    return Semantics(
      label: captions.join(', '),
      child: ExcludeSemantics(
        child: _Loop(
          seconds: 6.4,
          stillAt: 2.1,
          builder: (context, s) {
            final tip = _path(s, _start, const [(0.9, 1.7, _option), (2.7, 3.35, _field)]);
            final pointer = _ramp(s, 0, 0.25) * (1 - _ramp(s, 4.4, 4.7));
            final sheet = _ramp(s, 0.2, 0.6) * (1 - _ramp(s, 2.5, 2.9));
            final picked = s >= 1.95 && s < 6.2;
            final keyboard = _ramp(s, 3.55, 3.95) * (1 - _ramp(s, 6.0, 6.4));
            Widget option(String label, bool current) => Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: current ? const Color(0xFFDCE1F7) : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: TextStyle(fontWeight: current ? FontWeight.w700 : FontWeight.w400)),
                  ),
                  if (current) const Icon(Icons.check, size: 14, color: _sysInk),
                ],
              ),
            );
            Widget header(String label) => Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: SizedBox(
                height: 14,
                child: Text(label, style: const TextStyle(fontSize: 10, color: _sysAccent)),
              ),
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Card(
                  color: const Color(0xFFF7F5F9),
                  children: [
                    // A chat: two messages and the message field.
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _Bubble(text: l10n.onboardingDemoChatIn, color: const Color(0xFFE6E1EC)),
                    ),
                    Positioned(
                      right: 12,
                      top: 50,
                      child: _Bubble(text: l10n.onboardingDemoChatOut, color: const Color(0xFFDCE1F7)),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 96,
                      height: 33,
                      child: Container(
                        alignment: AlignmentDirectional.centerStart,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFDDD8E3)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(l10n.onboardingDemoMessage, style: const TextStyle(color: _sysMuted)),
                      ),
                    ),
                    // BooBoard appears: dark keys and a lime enter key.
                    if (keyboard > 0)
                      Positioned(left: 0, right: 0, bottom: -96 * (1 - keyboard), height: 96, child: const _MiniKeys()),
                    if (sheet > 0) _scrim(sheet),
                    if (sheet > 0)
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: -_sheetH * (1 - sheet),
                        height: _sheetH,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF6F2FB),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              header(l10n.onboardingDemoOtherKeyboard),
                              option(l10n.onboardingDemoOtherKeyboard, !picked),
                              const SizedBox(height: 4),
                              header(l10n.appName),
                              option(l10n.appName, picked),
                            ],
                          ),
                        ),
                      ),
                    _Pointer(tip: tip, opacity: pointer, tap: _tapPhase(s, const [1.8, 3.4])),
                  ],
                ),
                _Captions(labels: captions, current: s < 2.5 ? 0 : 1),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 170),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
    child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}

/// BooBoard's keyboard, in miniature: three rows of dark keys, a space bar and a lime enter key.
class _MiniKeys extends StatelessWidget {
  const _MiniKeys();

  @override
  Widget build(BuildContext context) {
    Widget key({double width = 20, Color color = const Color(0xFF2C262B)}) => Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
    );
    Widget row(List<Widget> keys) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: keys),
      ),
    );
    return Container(
      color: BooColors.ink,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        children: [
          row([for (var i = 0; i < 10; i++) key()]),
          row([for (var i = 0; i < 9; i++) key()]),
          row([key(), key(width: 116), key(), key(color: BooColors.lime)]),
        ],
      ),
    );
  }
}
