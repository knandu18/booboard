// SPDX-License-Identifier: GPL-3.0-or-later
//
// Japanese settings: the layout choice, flick only, half-width space, the dictionary pack status and
// clearing the learned words. Writes go through SettingsStore.update with the languages or japanese sections.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/app/japanese/japanese_screen.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/engine/lang/japanese/japanese_learning.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../support/app_fakes.dart';

BooBoardSettings _applied(AppFakes fakes, {BooBoardSettings base = const BooBoardSettings()}) {
  final change =
      verify(() => fakes.store.update(captureAny(), sections: any(named: 'sections'))).captured.last
          as BooBoardSettings Function(BooBoardSettings);
  return change(base);
}

void main() {
  setUpAll(() {
    registerFallbackValue((BooBoardSettings s) => s);
    registerFallbackValue(<String>[]);
  });

  late AppFakes fakes;

  Future<void> pump(
    WidgetTester tester, {
    BooBoardSettings settings = const BooBoardSettings(),
    bool withPack = false,
  }) async {
    fakes = AppFakes(settings: settings);
    when(() => fakes.platform.listPacks()).thenAnswer(
      (_) async => [
        if (withPack)
          PackInfoMessage(
            id: 'dict-ja-mozc',
            kind: PackKind.dictionary,
            name: 'Japanese dictionary (Mozc)',
            version: 1,
            languages: const ['ja'],
            sizeBytes: 20 * 1024 * 1024,
            engine: 'mozc',
            license: 'BSD-3-Clause',
          ),
      ],
    );
    await pumpWithServices(
      tester,
      fakes.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: JapaneseScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the layout, the typing options, the pack and clear learned words', (tester) async {
    await pump(tester);
    expect(find.text('Japanese'), findsWidgets, reason: 'the page title');
    expect(find.text('12-key (flick)'), findsOneWidget);
    expect(find.text('Romaji (QWERTY)'), findsOneWidget);
    expect(find.text('Flick only'), findsOneWidget);
    expect(find.text('Half-width space'), findsOneWidget);
    expect(find.text('Dictionary pack'), findsOneWidget);
    expect(find.textContaining('Not installed'), findsOneWidget);
    expect(find.text('Clear learned words'), findsOneWidget);
  });

  testWidgets('an installed dictionary pack is named', (tester) async {
    await pump(tester, withPack: true);
    expect(find.textContaining('Japanese dictionary (Mozc) is installed'), findsOneWidget);
  });

  testWidgets('choosing romaji writes the default Japanese layout', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Romaji (QWERTY)'));
    await tester.pumpAndSettle();
    final s = _applied(fakes);
    expect(s.languages.layouts['ja'], 'romaji_ja');
    expect(s.languages.layouts['en'], 'qwerty', reason: 'other languages are kept');
  });

  testWidgets('flick only writes the japanese section', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Flick only'));
    await tester.pumpAndSettle();
    expect(_applied(fakes).japanese.flickOnly, isTrue);
  });

  testWidgets('clearing the learned words deletes the blob after confirmation', (tester) async {
    await pump(tester);
    await fakes.services.secureStore.write(JapaneseLearning.blobName, Uint8List.fromList('{"v":1,"w":{}}'.codeUnits));
    await tester.tap(find.text('Clear learned words'));
    await tester.pumpAndSettle();
    expect(find.text('Clear learned Japanese words?'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(await fakes.services.secureStore.read(JapaneseLearning.blobName), isNull);
  });

  testWidgets('cancelling the clear keeps the learned words', (tester) async {
    await pump(tester);
    await fakes.services.secureStore.write(JapaneseLearning.blobName, Uint8List.fromList([1, 2, 3]));
    await tester.tap(find.text('Clear learned words'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await fakes.services.secureStore.read(JapaneseLearning.blobName), isNotNull);
  });
}
