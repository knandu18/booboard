// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A (redesigned 2026-11-26). The pages of first-run setup: a welcome page, then six
// steps. Each page is lime paper with a scene on top (Boo floating, or a setup demo) and the page's
// headline, text and controls below. The screen (onboarding_screen.dart) owns the status values, the
// progress row and the buttons.
import 'package:material_ui/material_ui.dart';

import 'booboard_mascot.dart';
import 'onboarding_demos.dart';
import 'onboarding_languages.dart';
import 'onboarding_style.dart';

import 'package:booboard/src/app/l10n.dart';

/// The shared layout: the progress row, the scene, then the page's content and the [footer].
class OnboardingPageLayout extends StatelessWidget {
  const OnboardingPageLayout({
    super.key,
    required this.scene,
    required this.body,
    required this.footer,
    this.top,
    this.bodyScrolls = true,
  });

  final Widget scene;
  final Widget? top;
  final List<Widget> body;
  final Widget footer;

  /// False for a page whose content has its own scrolling list (languages).
  final bool bodyScrolls;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final content = [for (var i = 0; i < body.length; i++) _riseIn(i, body[i])];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?top,
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, -16 * (1 - v)),
                      child: Transform.scale(scale: 0.96 + 0.04 * v, child: child),
                    ),
                  ),
                  child: scene,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: bodyScrolls
                ? ListView(padding: EdgeInsets.zero, children: content)
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: footer),
        ),
      ],
    );
  }

  /// Wraps [child] in [RiseIn]. An [Expanded] or [Flexible] must stay the Column's direct child, so
  /// the animation goes inside it instead.
  static Widget _riseIn(int index, Widget child) => child is Flexible
      ? Flexible(
          key: child.key,
          flex: child.flex,
          fit: child.fit,
          child: RiseIn(index: index, child: child.child),
        )
      : RiseIn(index: index, child: child);
}

const SizedBox _gap = SizedBox(height: 12);

/// A scene of [height] with Boo in the middle and optional [around] it (bubbles, sparkles).
Widget _booScene(
  BuildContext context, {
  required double height,
  required double size,
  double look = 0,
  List<Widget> around = const [],
}) => SizedBox(
  height: height,
  child: Stack(
    alignment: Alignment.center,
    children: [
      ...around,
      Semantics(
        image: true,
        label: context.l10n.onboardingMascotLabel,
        child: AnimatedBoo(size: size, look: look),
      ),
    ],
  ),
);

/// Welcome: Boo says hello.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.footer});

  final Widget footer;

  @override
  Widget build(BuildContext context) => OnboardingPageLayout(
    scene: Padding(padding: const EdgeInsets.only(top: 24), child: _booScene(context, height: 290, size: 150)),
    body: [
      OnboardingTitle(context.l10n.onboardingWelcomeTitle, big: true),
      _gap,
      OnboardingLead(context.l10n.onboardingWelcomeBody),
    ],
    footer: footer,
  );
}

/// Step 1: turn BooBoard on in Android's keyboard list.
class EnableStep extends StatelessWidget {
  const EnableStep({super.key, required this.enabled, required this.top, required this.footer});

  final bool enabled;
  final Widget top;
  final Widget footer;

  @override
  Widget build(BuildContext context) => OnboardingPageLayout(
    top: top,
    scene: const Padding(padding: EdgeInsets.only(top: 6), child: EnableDemo()),
    body: [
      OnboardingStepLabel(context.l10n.onboardingStepOf('1', '6')),
      const SizedBox(height: 6),
      OnboardingTitle(context.l10n.onboardingTurnOnTitle),
      _gap,
      OnboardingLead(context.l10n.onboardingTurnOnBody),
      const SizedBox(height: 14),
      OnboardingStatusPill(
        done: enabled,
        text: enabled ? context.l10n.onboardingKeyboardOn : context.l10n.onboardingKeyboardOff,
      ),
    ],
    footer: footer,
  );
}

/// Step 2: choose BooBoard as the keyboard in use. The screen polls while this step shows.
class SwitchStep extends StatelessWidget {
  const SwitchStep({super.key, required this.enabled, required this.selected, required this.top, required this.footer});

  final bool enabled;
  final bool selected;
  final Widget top;
  final Widget footer;

  @override
  Widget build(BuildContext context) => OnboardingPageLayout(
    top: top,
    scene: const Padding(padding: EdgeInsets.only(top: 6), child: SwitchDemo()),
    body: [
      OnboardingStepLabel(context.l10n.onboardingStepOf('2', '6')),
      const SizedBox(height: 6),
      OnboardingTitle(context.l10n.onboardingSwitchTitle),
      _gap,
      OnboardingLead(context.l10n.onboardingSwitchBody),
      const SizedBox(height: 14),
      OnboardingStatusPill(
        done: selected,
        text: selected
            ? context.l10n.onboardingKeyboardIsYours
            : (enabled ? context.l10n.onboardingKeyboardNotYours : context.l10n.onboardingTurnOnFirst),
      ),
    ],
    footer: footer,
  );
}

/// Step 3: why Android's "may collect your text" warning does not apply to BooBoard.
class PrivacyStep extends StatelessWidget {
  const PrivacyStep({
    super.key,
    required this.internet,
    required this.debugBuild,
    required this.top,
    required this.footer,
  });

  /// Null while the permission is still being read.
  final bool? internet;
  final bool debugBuild;
  final Widget top;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String internetTitle;
    final String internetBody;
    if (internet == null) {
      internetTitle = l10n.onboardingInternetAccess;
      internetBody = l10n.onboardingCheckingPermissions;
    } else if (internet!) {
      internetTitle = l10n.onboardingInternetAccess;
      internetBody = debugBuild ? l10n.onboardingDebugInternet : l10n.onboardingReleaseInternet;
    } else {
      internetTitle = l10n.onboardingFactNoInternet;
      internetBody = l10n.onboardingNoInternet;
    }
    return OnboardingPageLayout(
      top: top,
      // Boo glances sideways: nobody is watching.
      scene: _booScene(
        context,
        height: 140,
        size: 74,
        look: -1,
        around: [
          Align(
            alignment: const Alignment(0.5, -0.8),
            child: ExcludeSemantics(child: OnboardingBubble(l10n.onboardingShh, italic: true)),
          ),
        ],
      ),
      body: [
        OnboardingStepLabel(l10n.onboardingStepOf('3', '6')),
        const SizedBox(height: 6),
        OnboardingTitle(l10n.onboardingWarningTitle),
        _gap,
        OnboardingLead(l10n.onboardingWarningBody),
        const SizedBox(height: 10),
        OnboardingNumberedRow(number: 1, title: internetTitle, body: internetBody),
        OnboardingNumberedRow(number: 2, title: l10n.onboardingEverythingHere, body: l10n.onboardingEverythingHereBody),
        OnboardingNumberedRow(number: 3, title: l10n.onboardingFactOpenSource, body: l10n.onboardingFactOpenSourceBody),
      ],
      footer: footer,
    );
  }
}

/// Step 4: languages, with search. Several can be on at once.
class LanguagesStep extends StatelessWidget {
  const LanguagesStep({super.key, required this.top, required this.footer});

  final Widget top;
  final Widget footer;

  /// Greetings that drift around Boo.
  static const List<(String, Alignment)> _words = [
    ('Hola', Alignment(-0.9, -0.7)),
    ('नमस्ते', Alignment(0.92, -0.85)),
    ('Bonjour', Alignment(-0.82, 0.8)),
    ('Olá', Alignment(0.86, 0.55)),
  ];

  @override
  Widget build(BuildContext context) => OnboardingPageLayout(
    top: top,
    scene: _booScene(
      context,
      height: 150,
      size: 68,
      around: [
        for (final (word, align) in _words)
          Align(
            alignment: align,
            child: ExcludeSemantics(child: OnboardingBubble(word)),
          ),
      ],
    ),
    bodyScrolls: false,
    body: [
      OnboardingStepLabel(context.l10n.onboardingStepOf('4', '6')),
      const SizedBox(height: 6),
      OnboardingTitle(context.l10n.onboardingLanguagesTitle),
      const SizedBox(height: 14),
      const Expanded(child: OnboardingLanguagePicker()),
    ],
    footer: footer,
  );
}

/// Step 5: a test field and a short checklist.
class TryStep extends StatefulWidget {
  const TryStep({super.key, required this.top, required this.footer});

  final Widget top;
  final Widget footer;

  @override
  State<TryStep> createState() => _TryStepState();
}

class _TryStepState extends State<TryStep> {
  final List<bool> _done = List.filled(3, false);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = OnboardingPalette.of(context);
    final tasks = [l10n.onboardingTryTyping, l10n.onboardingTrySwipe, l10n.onboardingTryAccents];
    return OnboardingPageLayout(
      top: widget.top,
      scene: _booScene(
        context,
        height: 150,
        size: 74,
        around: [
          Align(
            alignment: const Alignment(0.6, -0.75),
            child: ExcludeSemantics(child: OnboardingBubble(l10n.onboardingTryMe)),
          ),
        ],
      ),
      body: [
        OnboardingStepLabel(l10n.onboardingStepOf('5', '6')),
        const SizedBox(height: 6),
        OnboardingTitle(l10n.onboardingTryTitle),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: l10n.onboardingTryField,
            filled: true,
            fillColor: palette.field,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: palette.ink, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < tasks.length; i++)
          Semantics(
            checked: _done[i],
            button: true,
            child: InkWell(
              onTap: () => setState(() => _done[i] = !_done[i]),
              child: OnboardingNumberedRow(
                number: i + 1,
                title: tasks[i],
                trailing: _RoundCheck(on: _done[i]),
              ),
            ),
          ),
      ],
      footer: widget.footer,
    );
  }
}

/// A round tick: an ink ring, filled ink with a lime tick when on.
class _RoundCheck extends StatelessWidget {
  const _RoundCheck({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? BooColors.ink : Colors.transparent,
      border: Border.all(color: BooColors.ink, width: 1.5),
    ),
    child: on ? const Icon(Icons.check, size: 15, color: BooColors.lime) : null,
  );
}

/// Step 6: the last page; the screen's Done button stores that setup is finished.
class FinishStep extends StatelessWidget {
  const FinishStep({super.key, required this.top, required this.footer});

  final Widget top;
  final Widget footer;

  @override
  Widget build(BuildContext context) => OnboardingPageLayout(
    top: top,
    scene: _booScene(
      context,
      height: 250,
      size: 124,
      around: [
        const Positioned.fill(
          child: ExcludeSemantics(child: CustomPaint(painter: _Sparkles())),
        ),
      ],
    ),
    body: [
      OnboardingTitle(context.l10n.onboardingAllSetTitle, big: true),
      _gap,
      OnboardingLead(context.l10n.onboardingAllSetBody),
    ],
    footer: footer,
  );
}

/// Four ink sparkles around Boo on the last page.
class _Sparkles extends CustomPainter {
  const _Sparkles();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final paint = Paint()..color = BooColors.ink;
    for (final (dx, dy, r) in const [
      (-96.0, -70.0, 11.0),
      (88.0, -90.0, 8.0),
      (82.0, 62.0, 10.0),
      (-100.0, 58.0, 6.0),
    ]) {
      final x = cx + dx, y = cy + dy;
      canvas.drawPath(
        Path()
          ..moveTo(x, y - r)
          ..cubicTo(x + r * 0.1, y - r * 0.3, x + r * 0.3, y - r * 0.1, x + r, y)
          ..cubicTo(x + r * 0.3, y + r * 0.1, x + r * 0.1, y + r * 0.3, x, y + r)
          ..cubicTo(x - r * 0.1, y + r * 0.3, x - r * 0.3, y + r * 0.1, x - r, y)
          ..cubicTo(x - r * 0.3, y - r * 0.1, x - r * 0.1, y - r * 0.3, x, y - r)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Sparkles oldDelegate) => false;
}
