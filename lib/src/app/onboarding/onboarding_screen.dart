// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A (redesigned 2026-11-25). First-run setup, also reachable from Home while setup is
// incomplete: a welcome page, then six steps. Status comes from the Android side and is re-read on
// resume and, on the switch step, every 500 ms (the input-method picker returns focus without a
// resume). Moving between pages, the old page fades out and the next one rises in.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/log.dart';
import '../../settings/booboard_settings.dart';
import '../app_services.dart';
import '../routes.dart';
import '../shell/settings_actions.dart';
import 'booboard_mascot.dart';
import 'onboarding_steps.dart';
import 'onboarding_style.dart';

import 'package:booboard/src/app/l10n.dart';

/// The welcome page plus six numbered steps.
const int _pageCount = 7;
const int _stepCount = 6;
const int _enablePage = 1, _switchPage = 2, _privacyPage = 3;
const Duration _switchPoll = Duration(milliseconds: 500);
const Duration _pageFade = Duration(milliseconds: 320);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  AppServices? _services;
  late final AppLifecycleListener _lifecycle;
  Timer? _poll;
  int _page = 0;
  bool _enabled = false;
  bool _selected = false;
  bool? _internet;
  bool _debugBuild = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_refresh()));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    final services = AppScope.of(context);
    _services = services;
    unawaited(_refresh());
    unawaited(_readBuildInfo(services));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _readBuildInfo(AppServices services) async {
    try {
      final info = await services.platform.getAppInfo();
      if (mounted) setState(() => _debugBuild = info.isDebugBuild);
    } on Object catch (e) {
      BooBoardLog.w('Onboarding', 'app info unavailable', e.runtimeType);
    }
  }

  Future<void> _refresh() async {
    final services = _services;
    if (services == null) return;
    try {
      final enabled = await services.app.isBooBoardEnabled();
      final selected = await services.app.isBooBoardSelected();
      final internet = await services.platform.hasInternetPermission();
      if (!mounted) return;
      setState(() {
        _enabled = enabled;
        _selected = selected;
        _internet = internet;
      });
    } on Object catch (e) {
      BooBoardLog.w('Onboarding', 'status check failed', e.runtimeType);
    }
  }

  void _goTo(int page) {
    final next = page.clamp(0, _pageCount - 1);
    if (next != _page) _show(next);
  }

  void _show(int page) {
    _poll?.cancel();
    _poll = null;
    if (page == _switchPage) {
      _poll = Timer.periodic(_switchPoll, (_) => unawaited(_refresh()));
    }
    setState(() => _page = page);
    if (page == _switchPage) unawaited(_refresh());
  }

  void _finish() {
    writeSettings(
      context,
      SettingsSection.languages,
      (s) => s.copyWith(languages: s.languages.copyWith(onboardingDone: true)),
    );
    _leave();
  }

  /// Closes setup. On first run this screen is the root, so it is replaced by home.
  void _leave() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      unawaited(navigator.pushReplacementNamed(BooBoardRoutes.home));
    }
  }

  /// The top row: six progress dashes and the close button.
  Widget _top() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          DashProgress(step: _page, total: _stepCount, label: l10n.onboardingStepOf('$_page', '$_stepCount')),
          const Spacer(),
          IconButton(
            tooltip: l10n.onboardingCloseSetup,
            onPressed: _leave,
            style: IconButton.styleFrom(
              foregroundColor: BooColors.ink,
              side: const BorderSide(color: BooColors.ink, width: 1.5),
            ),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  /// Back on the left, the main button on the right. On the first two steps the main button does
  /// the step's action until the step is done, then becomes Next.
  Widget _footer() {
    final l10n = context.l10n;
    final app = _services?.app;
    final String label;
    final VoidCallback onPressed;
    if (_page == 0) {
      label = l10n.onboardingWelcomeStart;
      onPressed = () => _goTo(1);
    } else if (_page == _enablePage && !_enabled) {
      label = l10n.onboardingOpenKeyboardSettings;
      onPressed = () => unawaited(app?.openInputMethodSettings());
    } else if (_page == _switchPage && !_selected) {
      label = l10n.onboardingChooseKeyboard;
      onPressed = () => unawaited(app?.showInputMethodPicker());
    } else if (_page == _pageCount - 1) {
      label = l10n.onboardingDone;
      onPressed = _finish;
    } else {
      label = l10n.onboardingNext;
      onPressed = () => _goTo(_page + 1);
    }
    return Row(
      children: [
        if (_page > 0) OnboardingTextButton(label: l10n.onboardingBack, onPressed: () => _goTo(_page - 1)),
        if (_page > 0) const SizedBox(width: 6),
        Expanded(
          child: OnboardingPillButton(label: label, onPressed: onPressed),
        ),
      ],
    );
  }

  Widget _pageBody() {
    final top = _top();
    final footer = _footer();
    return switch (_page) {
      0 => WelcomeStep(footer: footer),
      _enablePage => EnableStep(enabled: _enabled, top: top, footer: footer),
      _switchPage => SwitchStep(enabled: _enabled, selected: _selected, top: top, footer: footer),
      _privacyPage => PrivacyStep(internet: _internet, debugBuild: _debugBuild, top: top, footer: footer),
      4 => LanguagesStep(top: top, footer: footer),
      5 => TryStep(top: top, footer: footer),
      _ => FinishStep(top: top, footer: footer),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = OnboardingPalette.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Setup stays lime in dark mode, so the status bar keeps dark icons.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayOnLime(),
      child: Scaffold(
        backgroundColor: palette.paper,
        body: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : _pageFade,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          // The old page fades out first; the new page's own parts rise in (RiseIn).
          layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: KeyedSubtree(key: ValueKey<int>(_page), child: _pageBody()),
        ),
      ),
    );
  }
}
