// SPDX-License-Identifier: GPL-3.0-or-later
//
// Light and dark builds of every settings screen, at font scale 1.3, without exceptions.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/about/about_screen.dart';
import 'package:booboard/src/app/images/images_screen.dart';
import 'package:booboard/src/app/app_services.dart';
import 'package:booboard/src/app/screens/feel_screen.dart';
import 'package:booboard/src/app/screens/home_screen.dart';
import 'package:booboard/src/app/screens/languages_screen.dart';
import 'package:booboard/src/app/screens/panels_screen.dart';
import 'package:booboard/src/app/screens/typing_screen.dart';
import 'package:booboard/src/app/screens/voice_screen.dart';
import 'package:booboard/src/app/shell/booboard_theme.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import 'support/app_fakes.dart';

const Map<String, Widget Function()> _screens = {
  'home': HomeScreen.new,
  'languages': LanguagesScreen.new,
  'typing': TypingScreen.new,
  'feel': FeelScreen.new,
  'panels': PanelsScreen.new,
  'voice': VoiceScreen.new,
  'about': AboutScreen.new,
  'images': ImagesScreen.new,
};

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final entry in _screens.entries) {
      testWidgets('${entry.key} builds in ${brightness.name} at font scale 1.3', (tester) async {
        disableAnimationsForTest(tester);
        final fakes = AppFakes(settings: const BooBoardSettings(languages: LanguageSettings(onboardingDone: true)));
        await tester.pumpWidget(
          AppScope(
            services: fakes.services,
            child: MaterialApp(
              localizationsDelegates: booboardLocalizationsDelegates,
              theme: booboardThemeData(booboardBrandScheme(Brightness.light)),
              darkTheme: booboardThemeData(booboardBrandScheme(Brightness.dark)),
              themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: entry.value(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(Scaffold), findsWidgets);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('the brand scheme is ink and lime: ink buttons in light mode, lime as the accent', (tester) async {
    final light = booboardBrandScheme(Brightness.light);
    final dark = booboardBrandScheme(Brightness.dark);
    expect(light.primary, const Color(0xFF161015));
    expect(light.secondaryContainer, const Color(0xFFE3F794));
    expect(light.surface, const Color(0xFFF6F5EE));
    expect(dark.primary, const Color(0xFFE3F794));
    expect(dark.surface, const Color(0xFF121012));
    expect(dark.brightness, Brightness.dark);
    expect(light.brightness, Brightness.light);
  });
}
