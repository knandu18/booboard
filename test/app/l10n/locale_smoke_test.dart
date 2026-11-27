// SPDX-License-Identifier: GPL-3.0-or-later
//
// The main settings screens build in every shipped language at font scale 1.3, without exceptions
// or overflow. German and Hindi have the longest strings, so they are checked first.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/app/about/about_screen.dart';
import 'package:booboard/src/app/images/images_screen.dart';
import 'package:booboard/src/app/app_services.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/screens/feel_screen.dart';
import 'package:booboard/src/app/screens/home_screen.dart';
import 'package:booboard/src/app/screens/languages_screen.dart';
import 'package:booboard/src/app/screens/panels_screen.dart';
import 'package:booboard/src/app/screens/typing_screen.dart';
import 'package:booboard/src/app/screens/voice_screen.dart';
import 'package:booboard/src/app/shell/booboard_theme.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../../app/support/app_fakes.dart';

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

const List<String> _locales = ['de', 'hi', 'en', 'es', 'fr', 'pt', 'id'];

void main() {
  for (final code in _locales) {
    for (final entry in _screens.entries) {
      testWidgets('${entry.key} builds in $code at font scale 1.3', (tester) async {
        disableAnimationsForTest(tester);
        final fakes = AppFakes(settings: const BooBoardSettings(languages: LanguageSettings(onboardingDone: true)));
        await tester.pumpWidget(
          AppScope(
            services: fakes.services,
            child: MaterialApp(
              locale: Locale(code),
              supportedLocales: booboardSupportedLocales,
              localizationsDelegates: booboardLocalizationsDelegates,
              theme: booboardThemeData(booboardBrandScheme(Brightness.light)),
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
}
