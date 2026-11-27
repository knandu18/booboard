// SPDX-License-Identifier: GPL-3.0-or-later
//
// Every route opens its screen; unknown routes go home; first run opens setup; the home tiles
// navigate.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/app/app.dart';
import 'package:booboard/src/app/routes.dart';
import 'package:booboard/src/app/shell/app_router.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import 'support/app_fakes.dart';

void main() {
  for (final route in [...BooBoardRoutes.all, voiceRoute]) {
    testWidgets('launch route "$route" opens its screen', (tester) async {
      disableAnimationsForTest(tester);
      final fakes = AppFakes(launchRoute: route);
      disableAnimationsForTest(tester);
      await pumpWithServices(tester, fakes.services, const BooBoardSettingsApp());
      expect(find.byKey(ValueKey<String>('route:$route')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('an unknown launch route goes home', (tester) async {
    disableAnimationsForTest(tester);
    final fakes = AppFakes(launchRoute: 'no-such-screen');
    await pumpWithServices(tester, fakes.services, const BooBoardSettingsApp());
    expect(find.byKey(const ValueKey<String>('route:home')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('first run without a launch route opens setup', (tester) async {
    disableAnimationsForTest(tester);
    final fakes = AppFakes();
    disableAnimationsForTest(tester);
    await pumpWithServices(tester, fakes.services, const BooBoardSettingsApp());
    expect(find.byKey(const ValueKey<String>('route:onboarding')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('after setup a launch goes home', (tester) async {
    disableAnimationsForTest(tester);
    final fakes = AppFakes(settings: const BooBoardSettings(languages: LanguageSettings(onboardingDone: true)));
    await pumpWithServices(tester, fakes.services, const BooBoardSettingsApp());
    expect(find.byKey(const ValueKey<String>('route:home')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('home lists every section and opens it', (tester) async {
    disableAnimationsForTest(tester);
    final fakes = AppFakes(
      launchRoute: BooBoardRoutes.home,
      settings: const BooBoardSettings(languages: LanguageSettings(onboardingDone: true)),
    );
    await pumpWithServices(tester, fakes.services, const BooBoardSettingsApp());
    for (final title in [
      'Languages',
      'Typing',
      'Feel',
      'Themes',
      'Panels',
      'Voice',
      'Translation',
      'Images',
      'Privacy',
      'About BooBoard',
      'booboard.com',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text(title), findsOneWidget);
    }
    await tapText(tester, 'Typing');
    expect(find.byKey(const ValueKey<String>('route:typing')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('home shows the setup card while BooBoard is not enabled', (tester) async {
    disableAnimationsForTest(tester);
    final fakes = AppFakes(
      launchRoute: BooBoardRoutes.home,
      enabled: false,
      settings: const BooBoardSettings(languages: LanguageSettings(onboardingDone: true)),
    );
    await pumpWithServices(tester, fakes.services, const BooBoardSettingsApp());
    expect(find.text('Finish setting up BooBoard').hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('home hides the setup card once BooBoard is enabled and selected', (tester) async {
    disableAnimationsForTest(tester);
    final fakes = AppFakes(
      launchRoute: BooBoardRoutes.home,
      settings: const BooBoardSettings(languages: LanguageSettings(onboardingDone: true)),
    );
    await pumpWithServices(tester, fakes.services, const BooBoardSettingsApp());
    expect(find.text('Finish setting up BooBoard').hitTestable(), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final (label, route) in [('Images', BooBoardRoutes.images), ('About BooBoard', BooBoardRoutes.about)]) {
    testWidgets('home opens $route from "$label"', (tester) async {
      disableAnimationsForTest(tester);
      final fakes = AppFakes(
        launchRoute: BooBoardRoutes.home,
        settings: const BooBoardSettings(languages: LanguageSettings(onboardingDone: true)),
      );
      await pumpWithServices(tester, fakes.services, const BooBoardSettingsApp());
      await tapText(tester, label);
      expect(find.byKey(ValueKey<String>('route:$route')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('home opens booboard.com in the browser', (tester) async {
    disableAnimationsForTest(tester);
    final fakes = AppFakes(
      launchRoute: BooBoardRoutes.home,
      settings: const BooBoardSettings(languages: LanguageSettings(onboardingDone: true)),
    );
    await pumpWithServices(tester, fakes.services, const BooBoardSettingsApp());
    await tapText(tester, 'booboard.com');
    verify(() => fakes.app.openWebsite()).called(1);
    expect(find.byKey(const ValueKey<String>('route:home')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('home shows "Not your keyboard yet" while BooBoard is on but not chosen', (tester) async {
    disableAnimationsForTest(tester);
    final fakes = AppFakes(
      launchRoute: BooBoardRoutes.home,
      selected: false,
      settings: const BooBoardSettings(languages: LanguageSettings(onboardingDone: true)),
    );
    await pumpWithServices(tester, fakes.services, const BooBoardSettingsApp());
    expect(find.text('Not your keyboard yet').hitTestable(), findsOneWidget);
    expect(find.text('Finish setting up BooBoard').hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the lime top keeps its height whether setup is finished or not, and the page fills the screen', (
    tester,
  ) async {
    disableAnimationsForTest(tester);
    final heights = <double>[];
    for (final selected in [true, false]) {
      final fakes = AppFakes(
        launchRoute: BooBoardRoutes.home,
        selected: selected,
        settings: const BooBoardSettings(languages: LanguageSettings(onboardingDone: true)),
      );
      await pumpWithServices(tester, fakes.services, const BooBoardSettingsApp());
      final top = find.byKey(const ValueKey<String>('home:top'));
      heights.add(tester.getSize(top).height);
      // The footer ends at the bottom of the 1600 px test screen: no blank band below the page.
      expect(tester.getBottomLeft(find.text('booboard.com')).dy, greaterThan(1500));
      await tester.pumpWidget(const SizedBox());
    }
    expect(heights.first, heights.last);
  });
}
