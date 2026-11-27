// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A (settings app). The shell: BooBoard's brand and Material You themes, the lock gate
// around everything, named routes (launch route and route requests from the keyboard), and the
// first-run setup. Keep BooBoardSettingsApp's constructor stable. main() wraps it in AppScope.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/log.dart';
import 'about/notices.dart';
import 'app_services.dart';
import 'l10n.dart';
import 'privacy/app_lock_gate.dart';
import 'routes.dart';
import 'shell/app_router.dart';
import 'shell/booboard_theme.dart';

class BooBoardSettingsApp extends StatefulWidget {
  const BooBoardSettingsApp({super.key});

  @override
  State<BooBoardSettingsApp> createState() => _BooBoardSettingsAppState();
}

class _BooBoardSettingsAppState extends State<BooBoardSettingsApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<String>? _routeRequests;
  AppServices? _services;

  /// False until the launch route and the system colours are read.
  bool _ready = false;
  String _initialRoute = BooBoardRoutes.home;
  List<int>? _palettes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    _services = AppScope.of(context);
    unawaited(_start(_services!));
  }

  @override
  void dispose() {
    unawaited(_routeRequests?.cancel());
    super.dispose();
  }

  Future<void> _start(AppServices services) async {
    BooBoardNotices.register();
    final launch = await _read(() => services.app.takeLaunchRoute());
    final colors = await _read(() => services.platform.getSystemColors());
    if (!mounted) return;
    final done = services.settings.value.languages.onboardingDone;
    setState(() {
      _initialRoute = launch ?? (done ? BooBoardRoutes.home : BooBoardRoutes.onboarding);
      _palettes = colors?.palettes;
      _ready = true;
    });
    _routeRequests = services.routeRequests.listen(_openRoute);
  }

  /// A host call that may fail (the app keeps running with defaults when it does).
  Future<T?> _read<T>(Future<T?> Function() call) async {
    try {
      return await call();
    } on Object catch (e) {
      BooBoardLog.w('App', 'host call failed', e.runtimeType);
      return null;
    }
  }

  /// The keyboard asked for a screen while the app is open: show it on top of the current one,
  /// keeping the first page (home, or setup on first run).
  void _openRoute(String route) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    unawaited(navigator.pushNamedAndRemoveUntil(route, (r) => r.isFirst));
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final services = _services!;
    return ListenableBuilder(
      listenable: services.settings,
      builder: (context, _) {
        final contrast = contrastLevelOf(services.settings.value.appearance.contrast);
        final palettes = _palettes;
        return MaterialApp(
          title: 'BooBoard',
          debugShowCheckedModeBanner: false,
          // Wave 4-C fills lib/l10n/app_<locale>.arb; screens read strings with AppLocalizations.of(context).
          localizationsDelegates: booboardLocalizationsDelegates,
          supportedLocales: booboardSupportedLocales,
          navigatorKey: _navigatorKey,
          theme: booboardThemeData(booboardSchemeFor(Brightness.light, palettes: palettes, contrastLevel: contrast)),
          darkTheme: booboardThemeData(booboardSchemeFor(Brightness.dark, palettes: palettes, contrastLevel: contrast)),
          themeMode: ThemeMode.system,
          initialRoute: _initialRoute,
          onGenerateRoute: routeFor,
          // The lock covers every screen, not just home.
          builder: (context, child) => AppLockGate(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
