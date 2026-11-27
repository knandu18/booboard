// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A. Home, the page people see when they open BooBoard after setup (lime look,
// 2026-11-26; prototype .design/home_v2_body.html): a lime top with floating Boo, the offline promise
// (Fraunces, italic ending) and the setup status, growing to fill tall screens, then small cards for each section, a lime Privacy card, and a footer with About
// and booboard.com. In dark mode the page and cards turn dark; the lime top and Privacy card stay.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/log.dart';
import '../app_services.dart';
import '../l10n.dart';
import '../onboarding/booboard_mascot.dart';
import '../onboarding/onboarding_style.dart';
import '../routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppServices? _services;
  late final AppLifecycleListener _lifecycle;

  /// Null until the first read.
  bool? _enabled;
  bool? _selected;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_refresh()));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    _services = AppScope.of(context);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final services = _services;
    if (services == null) return;
    try {
      final enabled = await services.app.isBooBoardEnabled();
      final selected = await services.app.isBooBoardSelected();
      if (!mounted) return;
      setState(() {
        _enabled = enabled;
        _selected = selected;
      });
    } on Object catch (e) {
      BooBoardLog.w('Home', 'setup status unavailable', e.runtimeType);
    }
  }

  /// Boo's width: bigger on taller screens (the lime top has more room there), the same whether
  /// setup is finished or not.
  static double _booSize(double height) => (92 + (height - 780) * 0.2).clamp(92, 140).toDouble();

  void _open(String route) => unawaited(Navigator.of(context).pushNamed(route));

  Future<void> _openWebsite() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.websiteNoBrowser;
    try {
      await _services?.app.openWebsite();
    } on PlatformException catch (e) {
      BooBoardLog.w('Home', 'website link failed', e.code);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = _HomeColors.of(context);
    final sections = <(IconData, String, String)>[
      (Icons.language, l10n.settingsLanguages, BooBoardRoutes.languages),
      (Icons.keyboard_outlined, l10n.settingsTyping, BooBoardRoutes.typing),
      (Icons.vibration, l10n.settingsFeel, BooBoardRoutes.feel),
      (Icons.palette_outlined, l10n.settingsThemes, BooBoardRoutes.themes),
      (Icons.dashboard_customize_outlined, l10n.settingsPanels, BooBoardRoutes.panels),
      (Icons.mic_none_outlined, l10n.settingsVoice, BooBoardRoutes.voice),
      (Icons.translate, l10n.settingsTranslation, BooBoardRoutes.translate),
      (Icons.image_outlined, l10n.homeImages, BooBoardRoutes.images),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayOnLime(darkPage: colors.dark),
      child: Scaffold(
        backgroundColor: colors.page,
        // The lime top takes any spare height, so the page always reaches the bottom of the screen.
        // On short screens (or with large text) the page scrolls instead.
        body: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _Hero(
                        key: const ValueKey<String>('home:top'),
                        enabled: _enabled,
                        selected: _selected,
                        booSize: _booSize(viewport.maxHeight),
                        onFinishSetup: () => _open(BooBoardRoutes.onboarding),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.paddingOf(context).bottom + 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < sections.length; i += 2)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    for (var k = i; k < i + 2; k++) ...[
                                      if (k > i) const SizedBox(width: 8),
                                      Expanded(
                                        child: k < sections.length
                                            ? _SectionCard(
                                                icon: sections[k].$1,
                                                title: sections[k].$2,
                                                colors: colors,
                                                onTap: () => _open(sections[k].$3),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          _PrivacyCard(
                            title: l10n.settingsPrivacy,
                            subtitle: l10n.homePrivacySubtitle,
                            onTap: () => _open(BooBoardRoutes.privacy),
                          ),
                          const SizedBox(height: 8),
                          _Footer(
                            colors: colors,
                            onAbout: () => _open(BooBoardRoutes.about),
                            onWebsite: () => unawaited(_openWebsite()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The page colours below the lime top. Light: warm paper and white cards. Dark: near-black page and
/// dark cards with light text.
@immutable
class _HomeColors {
  const _HomeColors({
    required this.dark,
    required this.page,
    required this.card,
    required this.text,
    required this.secondary,
  });

  static const _HomeColors light = _HomeColors(
    dark: false,
    page: Color(0xFFF6F5EE),
    card: Colors.white,
    text: BooColors.ink,
    secondary: Color(0xFF5A544E),
  );

  static const _HomeColors darkMode = _HomeColors(
    dark: true,
    page: Color(0xFF121012),
    card: Color(0xFF262123),
    text: Color(0xFFF3F1EC),
    secondary: Color(0xFFB8B2AC),
  );

  static _HomeColors of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? darkMode : light;

  final bool dark;
  final Color page;
  final Color card;
  final Color text;
  final Color secondary;
}

/// The lime top: floating Boo, the offline promise in the serif headline font, and the setup status.
/// While setup is not finished, a black pill button leads back to setup. The top is always as tall as
/// the "not finished" version (an invisible copy sets the height), so it keeps the same height when setup
/// is done; its parent may make it taller still, and the content stays centred.
class _Hero extends StatelessWidget {
  const _Hero({
    super.key,
    required this.enabled,
    required this.selected,
    required this.booSize,
    required this.onFinishSetup,
  });

  final bool? enabled;
  final bool? selected;
  final double booSize;
  final VoidCallback onFinishSetup;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final known = enabled != null && selected != null;
    final done = enabled == true && selected == true;
    final status = enabled == false
        ? l10n.onboardingKeyboardOff
        : (selected == false ? l10n.onboardingKeyboardNotYours : l10n.onboardingKeyboardIsYours);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BooColors.lime,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 8, 24, 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sets the height: the longest version of the content, never shown.
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: _content(context, status: l10n.onboardingKeyboardNotYours, showStatus: true, done: false),
            ),
            Positioned.fill(
              child: Center(
                child: _content(context, status: status, showStatus: known, done: done, live: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context, {
    required String status,
    required bool showStatus,
    required bool done,
    bool live = false,
  }) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (live)
          Semantics(
            image: true,
            label: l10n.appName,
            child: ExcludeSemantics(child: AnimatedBoo(size: booSize)),
          )
        else
          SizedBox(width: booSize * 1.2, height: booSize * 1.53),
        const SizedBox(height: 4),
        OnboardingTitle(l10n.homeOfflinePromise, fontSize: 32, textAlign: TextAlign.center),
        if (showStatus) ...[
          const SizedBox(height: 16),
          OnboardingStatusPill(done: done, text: status, alignment: Alignment.center),
          if (!done) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OnboardingPillButton(label: l10n.homeFinishSetup, onPressed: live ? onFinishSetup : null),
            ),
          ],
        ],
      ],
    );
  }
}

/// A small card: a lime circle with the section's icon and the section name.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.colors, required this.onTap});

  final IconData icon;
  final String title;
  final _HomeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: colors.card,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _IconCircle(icon: icon, fill: BooColors.lime, iconColor: BooColors.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: colors.text, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The wide lime Privacy card (lime in light and dark mode).
class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: BooColors.lime,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: [
              const _IconCircle(icon: Icons.shield_outlined, fill: BooColors.ink, iconColor: BooColors.lime),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        color: BooColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.15,
                      ),
                    ),
                    Text(subtitle, style: text.bodySmall?.copyWith(color: const Color(0xFF2E2A24), fontSize: 12.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: BooColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, required this.fill, required this.iconColor});

  final IconData icon;
  final Color fill;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
    child: Icon(icon, size: 19, color: iconColor),
  );
}

/// "About BooBoard · booboard.com". The website opens in the browser; BooBoard itself stays offline.
class _Footer extends StatelessWidget {
  const _Footer({required this.colors, required this.onAbout, required this.onWebsite});

  final _HomeColors colors;
  final VoidCallback onAbout;
  final VoidCallback onWebsite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = TextButton.styleFrom(
      foregroundColor: colors.secondary,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton.icon(
          style: style,
          onPressed: onAbout,
          icon: const Icon(Icons.info_outline, size: 18),
          label: Text(l10n.homeAboutBooBoard),
        ),
        ExcludeSemantics(
          child: Text('·', style: TextStyle(color: colors.secondary)),
        ),
        Semantics(
          hint: l10n.websiteOpenHint,
          child: TextButton(
            style: style,
            onPressed: onWebsite,
            child: const Text(booboardWebsite, style: TextStyle(decoration: TextDecoration.underline)),
          ),
        ),
      ],
    );
  }
}

/// BooBoard's website as shown in the app. The address that opens is fixed on the platform side.
const String booboardWebsite = 'booboard.com';
