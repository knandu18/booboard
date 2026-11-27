// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wave 3-A: the space-bar language picker inside the keyboard, with the fake host and editor.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/features/languages/languages_feature.dart';
import 'package:booboard/src/features/shared/panel_style.dart' show PanelSwitch;
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';
import 'package:booboard/src/keyboard/panels/keyboard_panel.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../../keyboard/support/app_harness.dart';

class _Probe extends KeyboardFeature {
  KeyboardSession? session;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return const KeyboardHooks();
  }
}

BooBoardSettings _settings({required List<String> enabled, String active = 'en'}) => BooBoardSettings(
  languages: LanguageSettings(enabled: enabled, active: active, layouts: const {'de': 'qwertz'}),
  typing: const TypingSettings(nextWordPrediction: false),
);

/// Shows the keyboard and opens the picker the way a long press on the space bar does.
Future<KeyboardSession> _openPicker(WidgetTester tester, AppHarness h, _Probe probe) async {
  await h.pump(tester, features: [probe]);
  await h.focus(tester);
  final session = probe.session!;
  createLanguagesFeature().attach(session).onLanguagePicker!.call();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  return session;
}

void main() {
  group('space-bar language picker', () {
    testWidgets('lists the enabled languages with their layouts; tapping one switches and closes the picker', (
      tester,
    ) async {
      final h = AppHarness(settings: _settings(enabled: ['en', 'de', 'ru']));
      final session = await _openPicker(tester, h, _Probe());

      expect(session.panel.value?.id, 'languages');
      expect(find.text('Deutsch  ·  QWERTZ'), findsOneWidget);
      expect(find.text('Русский  ·  ЙЦУКЕН'), findsOneWidget);

      await tester.tap(find.text('Deutsch  ·  QWERTZ'));
      await tester.pump(const Duration(milliseconds: 20));

      expect(session.activeLanguage.value, 'de');
      expect(session.panel.value, isNull);
    });

    testWidgets('Language settings opens the languages route and closes the picker', (tester) async {
      final h = AppHarness(settings: _settings(enabled: ['en', 'de']));
      final session = await _openPicker(tester, h, _Probe());

      await tester.tap(find.text('Language settings'));
      await tester.pump();

      verify(() => h.host.openSettings('languages')).called(1);
      expect(session.panel.value, isNull);
    });

    testWidgets('Switch keyboard opens the system keyboard picker', (tester) async {
      final h = AppHarness(settings: _settings(enabled: ['en', 'de']));
      await _openPicker(tester, h, _Probe());

      await tester.tap(find.text('Switch keyboard'));
      await tester.pump();

      verify(() => h.host.showInputMethodPicker()).called(1);
    });

    testWidgets('with one language the system picker opens instead of the BooBoard picker', (tester) async {
      final h = AppHarness(settings: _settings(enabled: ['en']));
      final probe = _Probe();
      await h.pump(tester, features: [probe]);
      await h.focus(tester);

      createLanguagesFeature().attach(probe.session!).onLanguagePicker!.call();
      await tester.pump();

      verify(() => h.host.showInputMethodPicker()).called(1);
      expect(probe.session!.panel.value, isNull);
    });

    testWidgets('no Hinglish switch while English is active', (tester) async {
      final h = AppHarness(settings: _settings(enabled: ['en', 'hi']));
      await _openPicker(tester, h, _Probe());
      expect(find.text('Type in Hinglish (English letters)'), findsNothing);
    });

    testWidgets('with a transliterating Hindi layout the switch writes hinglishOutput', (tester) async {
      final h = AppHarness(
        settings: _settings(enabled: ['en', 'hi'], active: 'hi'),
      );
      await _openPicker(tester, h, _Probe());
      expect(find.text('Type in Hinglish (English letters)'), findsOneWidget);
      await tester.tap(find.byType(PanelSwitch));
      await tester.pump(const Duration(milliseconds: 20));
      expect(h.store.value.languages.hinglishOutput, isTrue);
    });
  });
}
