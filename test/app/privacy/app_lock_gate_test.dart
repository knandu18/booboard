// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../security/support/fakes.dart';

import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/app/privacy/app_lock_gate.dart';
import 'package:booboard/src/security/app_auth.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import 'privacy_harness.dart';

void main() {
  late PrivacyHarness h;

  setUp(() {
    registerSecurityFallbacks();
  });

  tearDown(() => h.dispose());

  testWidgets('with app lock on, the content stays hidden until the device check passes', (tester) async {
    h = PrivacyHarness(settings: const BooBoardSettings(privacy: PrivacySettings(appLock: true)));
    final auth = FakeAuth();
    await tester.pumpWidget(h.host(AppLockGate(authenticator: auth, child: const Text('SECRET'))));
    await tester.pump();

    expect(find.text('SECRET'), findsNothing);
    expect(find.text('BooBoard is locked'), findsOneWidget);
    expect(auth.calls, 1);
    verify(() => h.app.setSecureScreen(true)).called(1);

    auth.pending.single.complete(AuthOutcome.success);
    await tester.pumpAndSettle();

    expect(find.text('SECRET'), findsOneWidget);
    expect(find.text('BooBoard is locked'), findsNothing);
    verify(() => h.app.setSecureScreen(false)).called(1);
  });

  testWidgets('a cancelled prompt keeps the app locked, and Unlock asks again', (tester) async {
    h = PrivacyHarness(settings: const BooBoardSettings(privacy: PrivacySettings(appLock: true)));
    final auth = FakeAuth()..answers.add(AuthOutcome.cancelled);
    await tester.pumpWidget(h.host(AppLockGate(authenticator: auth, child: const Text('SECRET'))));
    await tester.pumpAndSettle();

    expect(find.text('SECRET'), findsNothing);
    expect(find.text('Unlock'), findsOneWidget);

    auth.answers.add(AuthOutcome.success);
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(auth.calls, 2);
    expect(find.text('SECRET'), findsOneWidget);
  });

  testWidgets('an unavailable device lock explains itself and stays locked', (tester) async {
    h = PrivacyHarness(settings: const BooBoardSettings(privacy: PrivacySettings(appLock: true)));
    final auth = FakeAuth()..answers.add(AuthOutcome.unavailable);
    await tester.pumpWidget(h.host(AppLockGate(authenticator: auth, child: const Text('SECRET'))));
    await tester.pumpAndSettle();

    expect(find.text('SECRET'), findsNothing);
    expect(find.textContaining('not available right now'), findsOneWidget);
  });

  testWidgets('with app lock off, the content shows at once and nothing is asked', (tester) async {
    h = PrivacyHarness();
    final auth = FakeAuth();
    await tester.pumpWidget(h.host(AppLockGate(authenticator: auth, child: const Text('SECRET'))));
    await tester.pump();

    expect(find.text('SECRET'), findsOneWidget);
    expect(auth.calls, 0);
  });

  testWidgets('returning after the timeout locks again; returning sooner does not', (tester) async {
    h = PrivacyHarness(
      settings: const BooBoardSettings(privacy: PrivacySettings(appLock: true, appLockTimeoutSeconds: 30)),
    );
    var now = DateTime(2026, 11, 21, 10);
    final auth = FakeAuth()..answers.add(AuthOutcome.success);
    await tester.pumpWidget(h.host(AppLockGate(authenticator: auth, clock: () => now, child: const Text('SECRET'))));
    await tester.pumpAndSettle();
    expect(find.text('SECRET'), findsOneWidget);

    // Leave for 10 seconds: under the timeout, so no prompt.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    now = now.add(const Duration(seconds: 10));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(auth.calls, 1);
    expect(find.text('SECRET'), findsOneWidget);

    // Leave for 45 seconds: over the timeout, so the lock comes back and asks.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    now = now.add(const Duration(seconds: 45));
    auth.answers.add(AuthOutcome.success);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(auth.calls, 2);
    expect(find.text('SECRET'), findsOneWidget);
  });
}
