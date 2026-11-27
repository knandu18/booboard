// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wave 3-A: the Languages screen and the onboarding language step. The store is a mock: the tests
// apply the change function the screen writes and check the languages section it produces.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show IconButton, Icons, Material, MaterialApp, TextField;
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/app_services.dart';
import 'package:booboard/src/app/onboarding/onboarding_languages.dart';
import 'package:booboard/src/app/screens/languages_screen.dart';
import 'package:booboard/src/app/shell/language_catalog.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../support/app_fakes.dart' show AppFakes;

/// Pumps [child] as a screen: a tall phone-sized view under a MaterialApp, with the services above it.
Future<void> _pumpScreen(WidgetTester tester, AppServices services, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 2000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    AppScope(
      services: services,
      child: MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// Applies the last change written to the store to [base] and returns the new languages section.
LanguageSettings _lastWrite(AppFakes fakes, BooBoardSettings base) {
  final captured = verify(() => fakes.store.update(captureAny(), sections: captureAny(named: 'sections'))).captured;
  final change = captured.first as BooBoardSettings Function(BooBoardSettings);
  expect(captured.last, [SettingsSection.languages]);
  return change(base).languages;
}

void main() {
  setUpAll(() {
    registerFallbackValue((BooBoardSettings s) => s);
  });

  group('Languages screen', () {
    testWidgets('enabled languages show their layout; changing it writes the layout choice', (tester) async {
      const base = BooBoardSettings(
        languages: LanguageSettings(enabled: ['en', 'de'], layouts: {'de': 'qwertz'}),
      );
      final fakes = AppFakes(settings: base);
      await _pumpScreen(tester, fakes.services, const LanguagesScreen());

      expect(find.text('Deutsch'), findsWidgets);
      expect(find.text('QWERTZ'), findsOneWidget);
      await tester.tap(find.text('QWERTZ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('QWERTZ (ÄÖÜ keys)').last);
      await tester.pumpAndSettle();

      expect(_lastWrite(fakes, base).layouts['de'], 'qwertz_umlaut');
    });

    testWidgets('adding a language appends it to the enabled list', (tester) async {
      const base = BooBoardSettings(languages: LanguageSettings(enabled: ['en']));
      final fakes = AppFakes(settings: base);
      await _pumpScreen(tester, fakes.services, const LanguagesScreen());

      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      expect(_lastWrite(fakes, base).enabled, ['en', 'fr']);
    });

    testWidgets('the last enabled language cannot be removed', (tester) async {
      const base = BooBoardSettings(languages: LanguageSettings(enabled: ['en']));
      final fakes = AppFakes(settings: base);
      await _pumpScreen(tester, fakes.services, const LanguagesScreen());

      final remove = tester.widget<IconButton>(find.byType(IconButton).first);
      expect(remove.onPressed, isNull);
    });

    testWidgets('removing a language keeps the others and makes the first one active when needed', (tester) async {
      const base = BooBoardSettings(
        languages: LanguageSettings(enabled: ['de', 'en'], active: 'de'),
      );
      final fakes = AppFakes(settings: base);
      await _pumpScreen(tester, fakes.services, const LanguagesScreen());

      await tester.tap(find.byTooltip('Remove German'));
      await tester.pumpAndSettle();

      final written = _lastWrite(fakes, base);
      expect(written.enabled, ['en']);
      expect(written.active, 'en');
    });

    testWidgets('dragging a language below the next one reorders the enabled list', (tester) async {
      const base = BooBoardSettings(languages: LanguageSettings(enabled: ['en', 'de', 'fr']));
      final fakes = AppFakes(settings: base);
      await _pumpScreen(tester, fakes.services, const LanguagesScreen());

      await tester.drag(find.byIcon(Icons.drag_indicator).first, const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(_lastWrite(fakes, base).enabled.first, isNot('en'));
    });

    testWidgets('the multilingual switch writes the languages section', (tester) async {
      const base = BooBoardSettings(languages: LanguageSettings(enabled: ['en', 'ar'], multilingual: true));
      final fakes = AppFakes(settings: base);
      await _pumpScreen(tester, fakes.services, const LanguagesScreen());

      await tester.tap(find.text('Multilingual typing'));
      await tester.pumpAndSettle();
      expect(_lastWrite(fakes, base).multilingual, isFalse);
    });
  });

  group('language catalog', () {
    test('names come from the registry', () {
      expect(languageLabel('de'), 'Deutsch');
      expect(languageLabel('pt-BR'), 'Português (Brasil)');
      expect(layoutLabel('qwertz_umlaut'), 'QWERTZ (ÄÖÜ keys)');
      expect(layoutLabel('no-such-layout'), 'no-such-layout');
    });

    test('the system locale maps to a supported language, Portuguese by region', () {
      expect(supportedLocaleLanguage(const Locale('pt', 'PT')), 'pt-PT');
      expect(supportedLocaleLanguage(const Locale('pt', 'BR')), 'pt-BR');
      expect(supportedLocaleLanguage(const Locale('fr', 'CA')), 'fr');
      expect(supportedLocaleLanguage(const Locale('xx')), isNull);
    });

    test('search finds languages by English or native name, ignoring accents', () {
      expect(searchLanguages('ger').map((l) => l.id), contains('de'));
      expect(searchLanguages('espanol').map((l) => l.id), contains('es'));
      expect(searchLanguages('Русск').map((l) => l.id), contains('ru'));
      expect(searchLanguages('zzzz'), isEmpty);
    });
  });

  group('onboarding language step', () {
    testWidgets('search narrows the list and tapping a language adds it to the selection', (tester) async {
      const base = BooBoardSettings(languages: LanguageSettings(enabled: ['en']));
      final fakes = AppFakes(settings: base);
      await _pumpScreen(
        tester,
        fakes.services,
        const Material(child: SizedBox(height: 900, child: OnboardingLanguagePicker())),
      );

      await tester.enterText(find.byType(TextField), 'ger');
      await tester.pump();
      expect(find.textContaining('Deutsch'), findsOneWidget);
      expect(find.textContaining('Español'), findsNothing);

      await tester.tap(find.textContaining('Deutsch'));
      await tester.pumpAndSettle();

      final written = _lastWrite(fakes, base);
      expect(written.enabled, ['en', 'de']);
    });
  });
}
