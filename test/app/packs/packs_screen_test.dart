// SPDX-License-Identifier: GPL-3.0-or-later
//
// Settings → Model packs: the installed list, import errors, and delete with a confirmation.
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/packs/packs_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/bridge/messages.g.dart';

import '../support/app_fakes.dart';

PackInfoMessage _translation() => PackInfoMessage(
  id: 'translate-en-es',
  kind: PackKind.translation,
  name: 'English → Spanish',
  version: 1,
  languages: const ['en', 'es'],
  sizeBytes: 110 * 1024 * 1024,
  engine: 'opus-mt-onnx',
  license: 'Apache-2.0',
);

PackInfoMessage _voice() => PackInfoMessage(
  id: 'voice-parakeet-en',
  kind: PackKind.voice,
  name: 'Parakeet English',
  version: 1,
  languages: const ['en'],
  sizeBytes: 74 * 1024 * 1024,
  engine: 'sherpa-onnx-nemo-transducer',
  license: 'CC-BY-4.0',
);

PackInfoMessage _image() => PackInfoMessage(
  id: 'images-lcm-dreamshaper-v7',
  kind: PackKind.image,
  name: 'Images (LCM Dreamshaper v7)',
  version: 1,
  languages: const ['en'],
  sizeBytes: 1700 * 1024 * 1024,
  engine: 'sdcpp-gguf',
  license: 'CreativeML-OpenRAIL-M',
);

void main() {
  testWidgets('an installed image pack gets its own Images group; without one the group is not there', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_image(), _voice()]);
    await pumpWithServices(
      tester,
      f.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: PacksScreen()),
    );
    await tester.scrollUntilVisible(
      find.text('Images (LCM Dreamshaper v7)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Images'), findsOneWidget);
    expect(find.text('Images (LCM Dreamshaper v7)'), findsOneWidget);
    expect(find.textContaining('CreativeML-OpenRAIL-M'), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('without an image pack there is no Images group', (tester) async {
    final g = AppFakes();
    when(() => g.platform.listPacks()).thenAnswer((_) async => [_voice()]);
    await pumpWithServices(
      tester,
      g.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: PacksScreen()),
    );
    expect(find.text('Images'), findsNothing);
  });

  testWidgets('lists voice and translation packs with sizes and licences', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_voice(), _translation()]);
    await pumpWithServices(
      tester,
      f.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: PacksScreen()),
    );

    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('Translation'), findsOneWidget);
    expect(find.text('Parakeet English'), findsOneWidget);
    expect(find.text('English → Spanish'), findsOneWidget);
    expect(find.textContaining('Apache-2.0'), findsOneWidget);
    expect(find.textContaining('CC-BY-4.0'), findsOneWidget);
    expect(
      find.text('Packs are checked before they are installed. They contain data only, never code.'),
      findsOneWidget,
    );
  });

  testWidgets('an empty list says so for each kind', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => const []);
    await pumpWithServices(
      tester,
      f.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: PacksScreen()),
    );
    expect(find.text('No voice packs installed'), findsOneWidget);
    expect(find.text('No translation packs installed'), findsOneWidget);
  });

  testWidgets('an import that fails says why, and nothing is installed', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => const []);
    when(() => f.app.openDocument(any())).thenAnswer((_) async => 'content://downloads/pack.boopack');
    when(() => f.app.importPack(any())).thenThrow(PlatformException(code: 'bad_signature'));
    await pumpWithServices(
      tester,
      f.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: PacksScreen()),
    );

    await tester.tap(find.text('Import a pack file'));
    await tester.pumpAndSettle();
    expect(find.text('This pack is not signed for BooBoard, so nothing was installed.'), findsOneWidget);
    verifyNever(() => f.platform.notifySettingsChanged(any()));
  });

  testWidgets('a cancelled file picker changes nothing', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => const []);
    when(() => f.app.openDocument(any())).thenAnswer((_) async => null);
    await pumpWithServices(
      tester,
      f.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: PacksScreen()),
    );

    await tester.tap(find.text('Import a pack file'));
    await tester.pumpAndSettle();
    verifyNever(() => f.app.importPack(any()));
  });

  testWidgets('delete asks first, then removes the pack and tells the keyboard', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_translation()]);
    when(() => f.app.deletePack(any())).thenAnswer((_) async {});
    await pumpWithServices(
      tester,
      f.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: PacksScreen()),
    );

    await tester.tap(find.byTooltip('Delete English → Spanish'));
    await tester.pumpAndSettle();
    expect(find.text('Delete English → Spanish?'), findsOneWidget);
    verifyNever(() => f.app.deletePack(any()));

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    verify(() => f.app.deletePack('translate-en-es')).called(1);
    verify(() => f.platform.notifySettingsChanged(const ['data.packs'])).called(1);
  });

  testWidgets('cancelling the delete keeps the pack', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_translation()]);
    await pumpWithServices(
      tester,
      f.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: PacksScreen()),
    );

    await tester.tap(find.byTooltip('Delete English → Spanish'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => f.app.deletePack(any()));
  });
}
