// SPDX-License-Identifier: GPL-3.0-or-later
//
// The BooBoard mascot: Boo, the black ghost with lime eyes (since 2026-11-26; the app icon is Boo on a
// lime tile). Drawn with a CustomPainter, by default on a lime circle. The shape is the approved
// prototype (.design/onboarding_v2.html, "middle" height): a dome, long sides and a small wavy hem of
// three lobes. tool/brand/render.py draws the same shape for the launcher icon; keep the two in step.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The mascot's four moods.
enum BooBoardPose {
  /// Boo with two sparkles: welcome and onboarding.
  open,

  /// Boo with a padlock badge: privacy and app lock.
  locked,

  /// A soft glow behind Boo: voice typing, translation and other work in progress.
  glowing,

  /// Muted, eyes closed: incognito and empty states.
  quiet,
}

/// Brand colours. Boo keeps them in light and dark mode.
abstract final class BooColors {
  static const Color lime = Color(0xFFE3F794);
  static const Color ink = Color(0xFF161015);
  static const Color sheen = Color(0xFF4A4247);
  static const Color body = Color(0xFF211B20);
  static const Color edge = Color(0xFF0E0A0D);
  static const Color muteBody = Color(0xFF6E686C);
  static const Color muteLid = Color(0xFFCFD8A6);
}

/// Where Boo is in its float: [wave] drives the hem (seconds), [lean] runs -1..1 side to side, [bob]
/// runs -1 (high) .. 1 (low). [look] shifts the eyes sideways (-1 left, 1 right).
@immutable
class BooMotion {
  const BooMotion({this.wave = 0, this.lean = 0, this.bob = 1, this.look = 0});

  /// Boo standing still, eyes ahead.
  static const BooMotion still = BooMotion();

  /// The float at [seconds]: a slow lean, a bob, and a hem wave that travels left to right.
  factory BooMotion.at(double seconds, {double look = 0, double phase = 0}) {
    final w = seconds + phase;
    return BooMotion(wave: w, lean: math.sin(w * 0.9), bob: math.sin(w * 1.85), look: look);
  }

  final double wave;
  final double lean;
  final double bob;
  final double look;

  /// 0 when low, 1 when high.
  double get height => (1 - bob) / 2;

  @override
  bool operator ==(Object other) =>
      other is BooMotion && other.wave == wave && other.lean == lean && other.bob == bob && other.look == look;

  @override
  int get hashCode => Object.hash(wave, lean, bob, look);
}

/// Boo's geometry, in its own frame: about x 6..94, y 4..129 (the hem dips a little lower as it waves).
abstract final class BooShape {
  /// The hem's baseline: the sides end here and the lobes hang below it.
  static const double hemY = 116;

  /// The body outline for [m]. The lower body sways with the lean; the lobes wave left to right.
  static Path body(BooMotion m) {
    const b = hemY;
    final sway = 2.2 * m.lean;
    double ph(double k) => m.wave * 2.4 - k * 1.25;
    final lx = 6 + sway, rx = 94 + sway;
    final tipX = [
      for (var k = 0; k < 3; k++) [21.0, 50.0, 79.0][k] + sway + 1.6 * math.sin(ph(k.toDouble())),
    ];
    final tipY = [for (var k = 0; k < 3; k++) b + 9 + 3.6 * math.sin(ph(k.toDouble()))];
    final valX = [
      for (var k = 0; k < 2; k++) [35.5, 64.5][k] + sway + 1.0 * math.sin(ph(k + 0.5) - 0.4),
    ];
    final valY = [for (var k = 0; k < 2; k++) b - 2 + 1.6 * math.sin(ph(k + 0.5) - 0.6)];
    final (x1, x2, x3) = (tipX[0], tipX[1], tipX[2]);
    final (t1, t2, t3) = (tipY[0], tipY[1], tipY[2]);
    final (vx1, vx2, v1, v2) = (valX[0], valX[1], valY[0], valY[1]);
    return Path()
      ..moveTo(lx, b)
      ..cubicTo(lx + 2, b - 24, 13 + sway * 0.3, 73, 14, 50)
      ..cubicTo(14, 22, 30, 4, 50, 4)
      ..cubicTo(70, 4, 86, 22, 86, 50)
      ..cubicTo(87 + sway * 0.3, 73, rx - 2, b - 24, rx, b)
      ..cubicTo(rx, b + 5, x3 + 9, t3, x3, t3)
      ..cubicTo(x3 - 7, t3, vx2 + 7, v2, vx2, v2)
      ..cubicTo(vx2 - 7, v2, x2 + 7, t2, x2, t2)
      ..cubicTo(x2 - 7, t2, vx1 + 7, v1, vx1, v1)
      ..cubicTo(vx1 - 7, v1, x1 + 7, t1, x1, t1)
      ..cubicTo(x1 - 9, t1, lx, b + 5, lx, b)
      ..close();
  }

  static const List<Offset> eyes = [Offset(36, 50), Offset(64, 50)];
  static const double eyeRx = 9, eyeRy = 12.5;

  /// The point Boo leans and squashes around.
  static const Offset pivot = Offset(50, 66);

  /// Where the floor shadow sits.
  static const double shadowY = 142;
}

class BooBoardMascot extends StatelessWidget {
  const BooBoardMascot({
    super.key,
    this.size = 96,
    this.label = 'BooBoard mascot',
    this.pose = BooBoardPose.open,
    this.backdrop = true,
  });

  /// Width and height in logical pixels. Crisp from 24 to 240.
  final double size;

  /// Spoken by TalkBack.
  final String label;

  /// Which drawing to show. Changing it springs between poses unless animations are disabled.
  final BooBoardPose pose;

  /// Whether Boo sits on a lime circle, like the app icon.
  final bool backdrop;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final drawing = SizedBox.square(
      dimension: size,
      child: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 460),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        // AnimatedSwitcher lays its children out loosely, and a CustomPaint without a child would
        // then size itself to zero, so the painted box states its size.
        child: KeyedSubtree(
          key: ValueKey<BooBoardPose>(pose),
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(painter: BooPainter(pose: pose)),
          ),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: label,
      child: backdrop
          ? DecoratedBox(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: BooColors.lime),
              child: drawing,
            )
          : drawing,
    );
  }
}

/// Draws Boo. [view] is the part of Boo's frame mapped onto the canvas: by default a square around Boo
/// and its decorations; [BooPainter.tall] adds room below for the floor shadow.
class BooPainter extends CustomPainter {
  const BooPainter({
    required this.pose,
    this.motion = BooMotion.still,
    this.decorations = true,
    this.shadow = false,
    this.view = square,
  });

  /// A tall view (Boo, its float and its shadow) for the animated onboarding Boo. Aspect 120 : 153.
  const BooPainter.tall({required this.pose, this.motion = BooMotion.still, this.decorations = false})
    : shadow = true,
      view = tallView;

  /// The square view used by [BooBoardMascot].
  static const Rect square = Rect.fromLTWH(-18, -2, 136, 136);

  /// The tall view used on the onboarding pages.
  static const Rect tallView = Rect.fromLTWH(-10, -6, 120, 153);

  final BooBoardPose pose;
  final BooMotion motion;

  /// The sparkles and glow around Boo. Off draws Boo alone (the padlock badge always shows).
  final bool decorations;

  /// A soft floor shadow that shrinks as Boo rises.
  final bool shadow;
  final Rect view;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / view.width, size.height / view.height);
    canvas.translate(-view.left, -view.top);
    final m = motion;
    if (shadow) {
      final up = m.height;
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, BooShape.shadowY), width: 2 * (30 - 6 * up), height: 9),
        Paint()..color = BooColors.ink.withValues(alpha: 0.24 - 0.09 * up),
      );
    }
    if (pose == BooBoardPose.glowing && decorations) {
      canvas.drawCircle(const Offset(50, 66), 66, Paint()..color = Colors.white.withValues(alpha: 0.35));
      canvas.drawCircle(const Offset(50, 66), 54, Paint()..color = Colors.white.withValues(alpha: 0.35));
    }
    // Float: rise with the bob, lean around the pivot, squash a little at the bottom.
    canvas.save();
    canvas.translate(0, -6 * (1 - m.bob));
    canvas.translate(BooShape.pivot.dx, BooShape.pivot.dy);
    canvas.rotate(4 * m.lean * math.pi / 180);
    canvas.scale(1 - 0.035 * m.lean.abs() + 0.02 * m.bob, 1 - 0.02 * m.bob);
    canvas.translate(-BooShape.pivot.dx, -BooShape.pivot.dy);
    if (pose == BooBoardPose.quiet) {
      _quiet(canvas, m);
    } else {
      _boo(canvas, m);
    }
    canvas.restore();
    switch (pose) {
      case BooBoardPose.open when decorations:
        _sparkles(canvas, const [(98, 14, 8.0), (108, 36, 5.0)]);
      case BooBoardPose.locked:
        _padlockBadge(canvas, const Offset(86, 112));
      case BooBoardPose.glowing when decorations:
        _sparkles(canvas, const [(-4, 22, 6.0), (104, 16, 5.5), (106, 104, 4.0)]);
      default:
        break;
    }
    canvas.restore();
  }

  /// Black body with a soft sheen up and to the left, a faint lime glow on the far edge, lime eyes.
  void _boo(Canvas canvas, BooMotion m) {
    final body = BooShape.body(m);
    const bounds = Rect.fromLTRB(6, 4, 94, 129);
    canvas.drawPath(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.32, -0.56),
          radius: 0.95,
          colors: [BooColors.sheen, BooColors.body, BooColors.edge],
          stops: [0, 0.45, 1],
        ).createShader(bounds),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.7, 0.2),
          radius: 0.5,
          colors: [BooColors.lime.withValues(alpha: 0.22), BooColors.lime.withValues(alpha: 0)],
        ).createShader(bounds),
    );
    final shift = Offset(5 * m.lean + 4 * m.look, -1.2 * m.bob);
    final eye = Paint()..color = BooColors.lime;
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (final c in BooShape.eyes) {
      final at = c + shift;
      canvas.drawOval(Rect.fromCenter(center: at, width: BooShape.eyeRx * 2, height: BooShape.eyeRy * 2), eye);
      canvas.drawOval(Rect.fromCenter(center: at + const Offset(-3, -5), width: 5.2, height: 6.8), shine);
    }
  }

  void _quiet(Canvas canvas, BooMotion m) {
    canvas.drawPath(BooShape.body(m), Paint()..color = BooColors.muteBody);
    final lid = Paint()
      ..color = BooColors.muteLid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;
    for (final c in BooShape.eyes) {
      final rect = Rect.fromCircle(center: c + const Offset(0, -2), radius: 8);
      canvas.drawArc(rect, 20 * math.pi / 180, 140 * math.pi / 180, false, lid);
    }
  }

  void _padlockBadge(Canvas canvas, Offset c) {
    canvas.drawCircle(c, 19, Paint()..color = BooColors.lime);
    canvas.drawCircle(c, 16, Paint()..color = BooColors.ink);
    final lime = Paint()..color = BooColors.lime;
    final shackle = Paint()
      ..color = BooColors.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;
    canvas.drawArc(Rect.fromCircle(center: c + const Offset(0, -4), radius: 5.4), math.pi, math.pi, false, shackle);
    canvas.drawRect(Rect.fromLTWH(c.dx - 6.8, c.dy - 4.2, 1.4, 3.8), lime);
    canvas.drawRect(Rect.fromLTWH(c.dx + 5.4, c.dy - 4.2, 1.4, 3.8), lime);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - 8.2, c.dy - 1.2, 16.4, 12), const Radius.circular(2.6)),
      lime,
    );
    canvas.drawCircle(c + const Offset(0, 4.2), 1.9, Paint()..color = BooColors.ink);
  }

  /// Four-point sparkles at (x, y) with radius r, in ink.
  void _sparkles(Canvas canvas, List<(double, double, double)> stars) {
    for (final (x, y, r) in stars) {
      final path = Path()
        ..moveTo(x, y - r)
        ..cubicTo(x + r * 0.1, y - r * 0.3, x + r * 0.3, y - r * 0.1, x + r, y)
        ..cubicTo(x + r * 0.3, y + r * 0.1, x + r * 0.1, y + r * 0.3, x, y + r)
        ..cubicTo(x - r * 0.1, y + r * 0.3, x - r * 0.3, y + r * 0.1, x - r, y)
        ..cubicTo(x - r * 0.3, y - r * 0.1, x - r * 0.1, y - r * 0.3, x, y - r)
        ..close();
      canvas.drawPath(path, Paint()..color = BooColors.ink);
    }
  }

  @override
  bool shouldRepaint(BooPainter oldDelegate) =>
      oldDelegate.pose != pose ||
      oldDelegate.motion != motion ||
      oldDelegate.decorations != decorations ||
      oldDelegate.shadow != shadow ||
      oldDelegate.view != view;
}
