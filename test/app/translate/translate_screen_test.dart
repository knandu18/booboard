// SPDX-License-Identifier: GPL-3.0-or-later
//
// Settings → Translation: on or off, the default pair, the installed directions, and the packs link.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/translate/translate_screen.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../support/app_fakes.dart';

PackInfoMessage _pack() => PackInfoMessage(
  id: 'translate-en-es',
  kind: PackKind.translation,
  name: 'English → Spanish',
  version: 1,
  languages: const ['en', 'es'],
  sizeBytes: 110 * 1024 * 1024,
  engine: 'opus-mt-onnx',
  license: 'Apache-2.0',
);

void main() {
  const settings = BooBoardSettings(
    translate: TranslateSettings(enabled: true, from: 'en', to: 'es'),
  );

  testWidgets('shows the default pair, whether its pack is installed, and the privacy note', (tester) async {
    final f = AppFakes(settings: settings);
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_pack()]);
    await pumpWithServices(
      tester,
      f.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: TranslateScreen()),
    );

    expect(find.text('Offline translation'), findsOneWidget);
    expect(find.text('English → Spanish'), findsNWidgets(2), reason: 'the default pair and the installed direction');
    expect(find.text('Pack installed'), findsOneWidget);
    expect(find.text('Translation runs on this phone. Nothing you translate is saved.'), findsOneWidget);
  });

  testWidgets('a pair without a pack says so', (tester) async {
    final f = AppFakes(
      settings: const BooBoardSettings(
        translate: TranslateSettings(from: 'en', to: 'ru'),
      ),
    );
    when(() => f.platform.listPacks()).thenAnswer((_) async => const []);
    await pumpWithServices(
      tester,
      f.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: TranslateScreen()),
    );
    expect(find.text('Pack not installed. Get it in Model packs.'), findsOneWidget);
    expect(find.text('No translation packs installed'), findsOneWidget);
  });

  testWidgets('the switch turns translation off and on', (tester) async {
    final f = AppFakes(settings: settings);
    when(() => f.platform.listPacks()).thenAnswer((_) async => const []);
    await pumpWithServices(
      tester,
      f.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: TranslateScreen()),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    verify(() => f.store.update(any(), sections: any(named: 'sections'))).called(1);
  });

  testWidgets('choosing a default pair saves it under the translate section', (tester) async {
    final f = AppFakes(settings: settings);
    when(() => f.platform.listPacks()).thenAnswer((_) async => const []);
    await pumpWithServices(
      tester,
      f.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: TranslateScreen()),
    );

    await tester.tap(find.text('English → Spanish').first);
    await tester.pumpAndSettle();
    expect(find.text('Default language pair'), findsOneWidget);
    await tester.tap(find.text('English → French'));
    await tester.pumpAndSettle();
    verify(() => f.store.update(any(), sections: const ['translate'])).called(1);
  });
}
