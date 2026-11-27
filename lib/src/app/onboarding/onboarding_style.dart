// SPDX-License-Identifier: GPL-3.0-or-later
//
// The look of first-run setup (2026-11-26): lime paper all the way, a soft serif headline (Fraunces),
// black Boo with lime eyes floating above the text, black pill buttons. Pages fade and rise in.
// The approved prototype is .design/onboarding_v2.html (not in git); these are its values.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'booboard_mascot.dart';

/// Brand colours of the setup pages. Setup is a brand screen, so it keeps the lime paper in dark mode.
@immutable
class OnboardingPalette {
  const OnboardingPalette._();

  static const Color pending = Color(0xFFE8913A);

  static const OnboardingPalette light = OnboardingPalette._();

  static OnboardingPalette of(BuildContext context) => light;

  Color get paper => BooColors.lime;
  Color get ink => BooColors.ink;
  Color get secondary => const Color(0xFF2E2A24);
  Color get rule => BooColors.ink.withValues(alpha: 0.14);
  Color get button => BooColors.ink;
  Color get onButton => Colors.white;
  Color get field => Colors.white;
}

/// Status and navigation bar icons for a page whose top is lime: dark icons on top. [darkPage] makes
/// the navigation bar icons light, for a dark page under a lime top (Home in dark mode).
SystemUiOverlayStyle overlayOnLime({bool darkPage = false}) => SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: darkPage ? Brightness.light : Brightness.dark,
);

/// Serif headline. Text between asterisks is set in italic: "Turn on *BooBoard*".
class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle(this.text, {super.key, this.big = false, this.fontSize, this.textAlign});

  final String text;
  final bool big;

  /// Overrides the size (Home sets the offline promise smaller than a setup headline).
  final double? fontSize;
  final TextAlign? textAlign;

  static TextStyle style(Color color, {bool big = false}) => TextStyle(
    fontFamily: 'Fraunces',
    fontSize: big ? 56 : 42,
    height: big ? 0.9 : 0.95,
    letterSpacing: big ? -1.4 : -1.0,
    color: color,
    fontVariations: const [FontVariation('wght', 400), FontVariation('SOFT', 100), FontVariation('opsz', 144)],
  );

  /// Splits [text] on asterisks; odd parts are emphasised.
  static List<(String, bool)> parts(String text) {
    final out = <(String, bool)>[];
    final pieces = text.split('*');
    for (var i = 0; i < pieces.length; i++) {
      if (pieces[i].isNotEmpty) out.add((pieces[i], i.isOdd));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final palette = OnboardingPalette.of(context);
    var base = style(palette.ink, big: big);
    final size = fontSize;
    if (size != null) base = base.copyWith(fontSize: size, height: 1.02, letterSpacing: -size * 0.022);
    final spans = [
      for (final (part, em) in parts(text))
        TextSpan(
          text: part,
          style: em
              ? base.copyWith(
                  fontStyle: FontStyle.italic,
                  fontVariations: const [
                    FontVariation('wght', 400),
                    FontVariation('SOFT', 100),
                    FontVariation('WONK', 1),
                    FontVariation('opsz', 144),
                  ],
                )
              : null,
        ),
    ];
    return Semantics(
      header: true,
      label: text.replaceAll('*', ''),
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(style: base, children: spans),
          textAlign: textAlign,
        ),
      ),
    );
  }
}

/// Body copy under a headline.
class OnboardingLead extends StatelessWidget {
  const OnboardingLead(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodyLarge
        ?.copyWith(color: OnboardingPalette.of(context).secondary, height: 1.45, letterSpacing: -0.15),
  );
}

/// The small "Step 1 of 6" line above a headline.
class OnboardingStepLabel extends StatelessWidget {
  const OnboardingStepLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: OnboardingPalette.of(context).secondary, fontWeight: FontWeight.w600),
  );
}

/// A dark stadium pill (light in dark mode). [expand] fills the row.
class OnboardingPillButton extends StatelessWidget {
  const OnboardingPillButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = OnboardingPalette.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: palette.button,
        foregroundColor: palette.onButton,
        minimumSize: const Size(64, 54),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.15),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

/// A plain text button in the page's ink colour.
class OnboardingTextButton extends StatelessWidget {
  const OnboardingTextButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: OnboardingPalette.of(context).ink,
      minimumSize: const Size(64, 54),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
    child: Text(label),
  );
}

/// A status pill: white with an orange dot while pending ("Not on yet"), ink with lime text and a lime
/// dot when done ("BooBoard is on").
class OnboardingStatusPill extends StatelessWidget {
  const OnboardingStatusPill({
    super.key,
    required this.done,
    required this.text,
    this.alignment = AlignmentDirectional.centerStart,
  });

  final bool done;
  final String text;

  /// Where the pill sits in its row (Home centres it).
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    const ink = BooColors.ink, lime = BooColors.lime;
    return Semantics(
      liveRegion: true,
      child: Align(
        alignment: alignment,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(color: done ? ink : Colors.white, borderRadius: BorderRadius.circular(60)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: done ? lime : OnboardingPalette.pending),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: done ? lime : ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One numbered row with thin rules: a serif number, a bold title and an optional line under it.
class OnboardingNumberedRow extends StatelessWidget {
  const OnboardingNumberedRow({super.key, required this.number, required this.title, this.body, this.trailing});

  final int number;
  final String title;
  final String? body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = OnboardingPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.rule)),
      ),
      child: Row(
        crossAxisAlignment: trailing == null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            child: Text('$number', style: OnboardingTitle.style(BooColors.ink).copyWith(fontSize: 26, height: 1.0)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: palette.ink),
                ),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(body!, style: TextStyle(fontSize: 14, height: 1.35, color: palette.secondary)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Six short dashes; the ones for finished steps are ink, the rest faint.
class DashProgress extends StatelessWidget {
  const DashProgress({super.key, required this.step, required this.total, required this.label});

  final int step;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 18,
              height: 4,
              margin: const EdgeInsetsDirectional.only(end: 5),
              decoration: BoxDecoration(
                color: BooColors.ink.withValues(alpha: i <= step ? 1 : 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    ),
  );
}

/// A white speech bubble with a few serif words ("Hola", "Try me").
class OnboardingBubble extends StatelessWidget {
  const OnboardingBubble(this.text, {super.key, this.italic = false});

  final String text;
  final bool italic;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Text(
      text,
      style: OnboardingTitle.style(BooColors.ink)
          .copyWith(fontSize: 17, height: 1.1, letterSpacing: 0, fontStyle: italic ? FontStyle.italic : null),
    ),
  );
}

/// Children rise into place one after another when a page appears.
class RiseIn extends StatelessWidget {
  const RiseIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = 0.1 + 0.06 * index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: (550 + delay * 1000).round()),
      builder: (context, raw, child) {
        final total = 0.55 + delay;
        final local = ((raw * total - delay) / 0.55).clamp(0.0, 1.0);
        final v = Curves.easeOutCubic.transform(local);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 22 * (1 - v)), child: child),
        );
      },
      child: child,
    );
  }
}

/// Boo floating: a slow lean, a bob with a little squash, a hem that waves left to right, eyes that
/// follow the lean, and a floor shadow that shrinks as Boo rises. Still when animations are off.
/// [size] is Boo's width; the widget is 1.2 x 1.53 times that (room for the float and the shadow).
class AnimatedBoo extends StatefulWidget {
  const AnimatedBoo({
    super.key,
    required this.size,
    this.pose = BooBoardPose.open,
    this.look = 0,
    this.decorations = false,
  });

  final double size;
  final BooBoardPose pose;

  /// Where the eyes look: -1 left, 0 ahead, 1 right.
  final double look;
  final bool decorations;

  @override
  State<AnimatedBoo> createState() => _AnimatedBooState();
}

class _AnimatedBooState extends State<AnimatedBoo> with SingleTickerProviderStateMixin {
  // One long loop; the motion uses elapsed seconds, so the loop length never shows.
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(minutes: 10));
  final double _phase = math.Random().nextDouble() * 6;

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
    final still = MediaQuery.disableAnimationsOf(context);
    final size = Size(widget.size * 1.2, widget.size * 1.53);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final motion = still
              ? BooMotion(look: widget.look)
              : BooMotion.at(_c.value * 600, look: widget.look, phase: _phase);
          return CustomPaint(
            size: size,
            painter: BooPainter.tall(pose: widget.pose, motion: motion, decorations: widget.decorations),
          );
        },
      ),
    );
  }
}
