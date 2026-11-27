// SPDX-License-Identifier: GPL-3.0-or-later
//
// First-run setup (redesigned 2026-11-25): a welcome page, then six steps. The setup steps follow
// the enabled and selected status, the switch step polls, finishing stores onboardingDone, there is
// no Skip, and pages fade when animations are on. Setup is lime with black Boo (2026-11-26), also in
// dark mode. Most tests turn animations off: Boo and the setup demos loop forever, which
// pumpAndSettle would wait on.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/app/app.dart';
import 'package:booboard/src/app/app_services.dart';
import 'package:booboard/src/app/onboarding/booboard_mascot.dart';
import 'package:booboard/src/app/onboarding/onboarding_style.dart';
import 'package:booboard/src/app/routes.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import 'support/app_fakes.dart';

Future<void> _open(WidgetTester tester, AppFakes fakes, {bool animations = false}) async {
  if (!animations) {
    disableAnimationsForTest(tester);
  }
  await tester.pumpWidget(const SizedBox());
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(AppScope(services: fakes.services, child: const BooBoardSettingsApp()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('setup opens on the welcome page with Boo', (tester) async {
    final fakes = AppFakes(launchRoute: BooBoardRoutes.onboarding);
    await _open(tester, fakes);
    expect(find.text("Hi, I'm Boo."), findsOneWidget);
    expect(find.text("Let's set up"), findsOneWidget);
    expect(find.bySemanticsLabel('Boo, the BooBoard ghost'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('enable step: the main button opens keyboard settings until BooBoard is on, then is Next', (
    tester,
  ) async {
    final fakes = AppFakes(launchRoute: BooBoardRoutes.onboarding, enabled: false, selected: false);
    await _open(tester, fakes);
    await _tap(tester, "Let's set up");
    expect(find.text('Turn on BooBoard'), findsOneWidget);
    expect(find.text('Not on yet'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await _tap(tester, 'Open keyboard settings');
    verify(() => fakes.app.openInputMethodSettings()).called(1);

    when(() => fakes.app.isBooBoardEnabled()).thenAnswer((_) async => true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('BooBoard is on'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Open keyboard settings'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('switch step polls every 500 ms until BooBoard is selected', (tester) async {
    final fakes = AppFakes(launchRoute: BooBoardRoutes.onboarding, selected: false);
    await _open(tester, fakes);
    await _tap(tester, "Let's set up");
    await _tap(tester, 'Next');
    expect(find.text('Make it yours'), findsOneWidget);
    expect(find.text('Not your keyboard yet'), findsOneWidget);
    expect(find.text('Choose keyboard'), findsOneWidget);

    when(() => fakes.app.isBooBoardSelected()).thenAnswer((_) async => true);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('BooBoard is your keyboard'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the privacy step shows that the app has no internet permission', (tester) async {
    final fakes = AppFakes(launchRoute: BooBoardRoutes.onboarding, internet: false);
    await _open(tester, fakes);
    await _tap(tester, "Let's set up");
    for (var i = 0; i < 2; i++) {
      await _tap(tester, 'Next');
    }
    expect(find.text('About that warning'), findsOneWidget);
    expect(find.text('No internet permission'), findsOneWidget);
    expect(find.text('Open source'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('finishing setup stores onboardingDone and opens home', (tester) async {
    final fakes = AppFakes(launchRoute: BooBoardRoutes.onboarding);
    await _open(tester, fakes);
    await _tap(tester, "Let's set up");
    for (var i = 0; i < 5; i++) {
      await _tap(tester, 'Next');
    }
    expect(find.text("You're all set."), findsOneWidget);
    await _tap(tester, 'Done');
    await tester.pump(const Duration(milliseconds: 500));

    final update = capturedUpdate(fakes.store, 'languages');
    expect(update(const BooBoardSettings()).languages.onboardingDone, isTrue);
    expect(find.byKey(const ValueKey<String>('route:home')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('every language is on the languages step and can be chosen; no theme picker there', (tester) async {
    final fakes = AppFakes(launchRoute: BooBoardRoutes.onboarding);
    await _open(tester, fakes);
    await _tap(tester, "Let's set up");
    for (var i = 0; i < 3; i++) {
      await _tap(tester, 'Next');
    }
    expect(find.text('Your languages'), findsOneWidget);
    expect(find.text('Oceanblue'), findsNothing);
    expect(find.textContaining('(soon)'), findsNothing);
    await tester.tap(find.textContaining('Español'));
    await tester.pump();
    final update = capturedUpdate(fakes.store, 'languages');
    expect(update(const BooBoardSettings()).languages.enabled, ['en', 'es']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with animations on, the old page fades out while the next one comes in', (tester) async {
    final fakes = AppFakes(launchRoute: BooBoardRoutes.onboarding);
    await _open(tester, fakes, animations: true);
    await tester.tap(find.text("Let's set up"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text("Hi, I'm Boo."), findsOneWidget, reason: 'the welcome page is still fading out');
    expect(find.text('Turn on BooBoard'), findsOneWidget, reason: 'the next page is already coming in');

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text("Hi, I'm Boo."), findsNothing);
    expect(find.text('Turn on BooBoard'), findsOneWidget);
    expect(find.byType(DashProgress), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('setup is lime with black Boo, also in dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final fakes = AppFakes(launchRoute: BooBoardRoutes.onboarding);
    await _open(tester, fakes);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, BooColors.lime);
    expect(find.byType(AnimatedBoo), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  // The rise-in animation once wrapped the language list's Expanded, which broke the page on
  // devices; with animations off the wrapper is skipped, so this has to run with them on.
  testWidgets('with animations on, the languages step lays out its list and keeps Next at the bottom', (tester) async {
    final fakes = AppFakes(launchRoute: BooBoardRoutes.onboarding);
    await _open(tester, fakes, animations: true);
    Future<void> step(String label) async {
      await tester.tap(find.text(label));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await step("Let's set up");
    for (var i = 0; i < 3; i++) {
      await step('Next');
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Your languages'), findsOneWidget);
    expect(find.textContaining('Español'), findsOneWidget);
    expect(tester.getCenter(find.text('Next')).dy, greaterThan(1400), reason: 'Next stays in the footer');
    expect(tester.getTopLeft(find.text('Your languages')).dy, greaterThan(150), reason: 'title sits below the band');

    await step('Next');
    expect(tester.takeException(), isNull);
    expect(find.text('Give it a try'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
