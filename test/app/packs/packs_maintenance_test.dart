// SPDX-License-Identifier: GPL-3.0-or-later
//
// Model packs, Wave 5-C: how the screen looks in each state of PackMaintenance (import-only, store
// delivery, verify, storage) and what each action does.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/packs/packs_screen.dart';
import 'package:booboard/src/app/privacy/privacy_format.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/packs/pack_catalog.dart';
import 'package:booboard/src/packs/pack_maintenance.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

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

/// A maintenance seam with every answer set by the test.
class _FakeMaintenance implements PackMaintenance {
  _FakeMaintenance({
    this.delivery = PackDelivery.importOnly,
    List<PackOffer> offers = const [],
    PackStorage? storage,
    this.checks,
    this.verifyError,
  }) : _offersReply = (() async => offers),
       _storageReply = (() async => storage);

  @override
  final PackDelivery delivery;
  final Future<List<PackOffer>> Function() _offersReply;
  final Future<PackStorage?> Function() _storageReply;
  final List<PackCheck>? checks;
  final Object? verifyError;
  final requested = <String>[];

  @override
  Future<List<PackOffer>> offers() => _offersReply();

  @override
  Future<void> request(String id) async => requested.add(id);

  @override
  Future<PackStorage?> storage() => _storageReply();

  @override
  Future<List<PackCheck>> verifyInstalled() async {
    if (verifyError != null) throw verifyError!;
    return checks ?? const [];
  }

  @override
  Future<String> installDelivered(String id) async => id;
}

Future<void> _pump(WidgetTester tester, AppFakes f, PackMaintenance maintenance) => pumpWithServices(
  tester,
  f.services,
  MaterialApp(
    localizationsDelegates: booboardLocalizationsDelegates,
    home: PacksScreen(maintenance: maintenance),
  ),
);

void main() {
  testWidgets('import-only builds explain how to get packs and copy the release link', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => const []);
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await _pump(tester, f, _FakeMaintenance());

    expect(find.text('How downloads stay private'), findsOneWidget);
    expect(find.textContaining('BooBoard has no internet permission and never connects.'), findsOneWidget);
    expect(
      find.text('Google Play downloads these packs, not BooBoard. BooBoard itself never uses the network.'),
      findsNothing,
    );
    expect(find.text('Download'), findsNWidgets(kPackCatalog.length), reason: 'every published pack is offered');

    final copy = find.text('Copy the release page link');
    await tester.ensureVisible(copy);
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(copied, [kPackReleasePageUrl]);
    expect(find.text('Link copied. Open it on another device.'), findsOneWidget);
  });

  testWidgets('Download hands only the pack file name to the browser and skips installed packs', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_translation()]);
    when(() => f.app.openPackDownload(any())).thenAnswer((_) async {});

    await _pump(tester, f, _FakeMaintenance());

    expect(
      find.text('Download'),
      findsNWidgets(kPackCatalog.length - 1),
      reason: 'the installed translation pack is not offered',
    );
    expect(find.text('English → Spanish'), findsOneWidget, reason: 'only as an installed pack');
    final voice = find.ancestor(
      of: find.text('Voice typing in English (Parakeet; needs about 700 MB of memory while you dictate)'),
      matching: find.byType(ListTile),
    );
    await tester.tap(find.descendant(of: voice, matching: find.text('Download')));
    await tester.pumpAndSettle();
    verify(() => f.app.openPackDownload('voice-parakeet-en.boopack')).called(1);
    expect(find.textContaining('Your browser is downloading'), findsOneWidget);
  });

  testWidgets('without a browser the screen says to copy the link instead', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => const []);
    when(() => f.app.openPackDownload(any())).thenThrow(PlatformException(code: 'no_browser'));

    await _pump(tester, f, _FakeMaintenance());
    await tester.tap(find.text('Download').first);
    await tester.pumpAndSettle();
    expect(find.text('No browser can open the link. Copy the release page link instead.'), findsOneWidget);
  });

  testWidgets('store delivery offers the packs that are not installed, with a Get button', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_translation()]);
    final maintenance = _FakeMaintenance(
      delivery: PackDelivery.storeDelivery,
      offers: const [
        PackOffer(id: 'translate-en-es', name: 'English → Spanish', sizeBytes: 1, status: PackOfferStatus.ready),
        PackOffer(
          id: 'dict-ja-mozc',
          name: 'Japanese dictionary',
          sizeBytes: 20 * 1024 * 1024,
          status: PackOfferStatus.notRequested,
        ),
        PackOffer(
          id: 'voice-parakeet-en',
          name: 'Parakeet English',
          sizeBytes: 161 * 1024 * 1024,
          status: PackOfferStatus.waitingForNetwork,
        ),
      ],
    );
    await _pump(tester, f, maintenance);

    expect(find.text('Get through Google Play'), findsOneWidget);
    expect(
      find.text('Google Play downloads these packs, not BooBoard. BooBoard itself never uses the network.'),
      findsOneWidget,
    );
    expect(find.text('Packs are files you add yourself.'), findsNothing);
    // The pack that is already installed is not offered again.
    expect(find.text('Japanese dictionary'), findsOneWidget);
    expect(find.text('Parakeet English'), findsOneWidget);
    expect(find.text('161 MB · Waiting for Wi-Fi or mobile data'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Get'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(TextButton, 'Get').first);
    await tester.pumpAndSettle();
    expect(maintenance.requested, ['dict-ja-mozc']);
  });

  testWidgets('verify reports intact packs, then damaged ones', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_translation()]);
    await _pump(
      tester,
      f,
      _FakeMaintenance(
        checks: const [PackCheck(id: 'translate-en-es', manifestOk: true, missingFiles: 0, damagedFiles: 0)],
      ),
    );
    await tester.tap(find.text('Verify installed packs'));
    await tester.pumpAndSettle();
    expect(find.text('1 installed packs checked. All files match.'), findsOneWidget);
  });

  testWidgets('verify names the damaged packs', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_translation()]);
    await _pump(
      tester,
      f,
      _FakeMaintenance(
        checks: const [PackCheck(id: 'translate-en-es', manifestOk: true, missingFiles: 1, damagedFiles: 0)],
      ),
    );
    await tester.tap(find.text('Verify installed packs'));
    await tester.pumpAndSettle();
    expect(find.text('1 installed packs have damaged or missing files. Delete them and import again.'), findsOneWidget);
  });

  testWidgets('in a build without maintenance, verify says so and changes nothing', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_translation()]);
    await _pump(tester, f, const UnavailablePackMaintenance());
    await tester.tap(find.text('Verify installed packs'));
    await tester.pumpAndSettle();
    expect(find.text('Checking installed packs is not available in this version of BooBoard.'), findsOneWidget);
  });

  testWidgets('a failed verify says nothing was changed', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_translation()]);
    await _pump(tester, f, _FakeMaintenance(verifyError: StateError('storage error')));
    await tester.tap(find.text('Verify installed packs'));
    await tester.pumpAndSettle();
    expect(find.text('BooBoard could not check the packs. Nothing was changed.'), findsOneWidget);
  });

  testWidgets('verify is not offered when nothing is installed', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => const []);
    await _pump(tester, f, _FakeMaintenance());
    await tester.tap(find.text('Verify installed packs'));
    await tester.pumpAndSettle();
    expect(find.text('1 installed packs checked. All files match.'), findsNothing);
    expect(find.text('Checking installed packs is not available in this version of BooBoard.'), findsNothing);
  });

  testWidgets('the footer shows free space when the build can tell', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_translation()]);
    await _pump(tester, f, _FakeMaintenance(storage: PackStorage(freeBytes: 500 * 1024 * 1024)));
    expect(find.textContaining('${formatBytes(500 * 1024 * 1024)} free on this phone.'), findsOneWidget);
  });

  testWidgets('without storage information the footer says only what is installed', (tester) async {
    final f = AppFakes();
    when(() => f.platform.listPacks()).thenAnswer((_) async => [_translation()]);
    await _pump(tester, f, _FakeMaintenance());
    expect(find.textContaining('free on this phone'), findsNothing);
    expect(find.textContaining('Installed packs use'), findsOneWidget);
  });
}
