// SPDX-License-Identifier: GPL-3.0-or-later
//
// Shared setup for the privacy widget tests: a fake device lock, a settings app with fake stores,
// and a MaterialApp host with AppScope above it.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/app_services.dart';
import 'package:booboard/src/security/app_auth.dart';
import 'package:booboard/src/settings/booboard_settings.dart';
import 'package:booboard/src/settings/settings_store.dart';

import '../../security/support/fakes.dart';

/// Answers queued in [answers]; otherwise waits on [pending] for the test to complete.
class FakeAuth implements AppAuthenticator {
  FakeAuth({this.secure = true});

  bool secure;
  int calls = 0;
  final List<AuthOutcome> answers = [];
  final List<Completer<AuthOutcome>> pending = [];

  @override
  Future<bool> isDeviceSecure() async => secure;

  @override
  Future<AuthOutcome> authenticate(String reason) {
    calls++;
    if (answers.isNotEmpty) return Future.value(answers.removeAt(0));
    final c = Completer<AuthOutcome>();
    pending.add(c);
    return c.future;
  }
}

class PrivacyHarness {
  PrivacyHarness({BooBoardSettings settings = const BooBoardSettings()})
    : store = FakeBlobStore(),
      platform = MockPlatform(),
      app = MockAppHost() {
    stubPlatform(platform, store);
    stubApp(app, platform);
    services = AppServices(settings: SettingsStore.memory(settings), secureStore: store, platform: platform, app: app);
    SecureScreenGuard.instance = SecureScreenGuard(app);
  }

  final FakeBlobStore store;
  final MockPlatform platform;
  final MockAppHost app;
  late final AppServices services;

  void dispose() => SecureScreenGuard.instance = null;

  /// Wraps [child] the way the settings app does.
  Widget host(Widget child) => AppScope(
    services: services,
    child: MaterialApp(
      localizationsDelegates: booboardLocalizationsDelegates,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4))),
      home: child,
    ),
  );
}

/// The privacy center reads the theme folder with real file I/O, which only completes outside the
/// fake clock. Let that I/O finish, then pump the widgets it fed.
Future<void> settleIo(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
  }
}
