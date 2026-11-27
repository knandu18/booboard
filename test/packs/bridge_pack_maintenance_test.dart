// SPDX-License-Identifier: GPL-3.0-or-later
//
// BridgePackMaintenance over the real Pigeon channels (answered by test handlers): how the platform's
// answers become the screen's model, for both ways packs reach a build (import and store).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/packs/pack_maintenance.dart';

const String _host = 'dev.flutter.pigeon.booboard.AppHostApi.';

TestDefaultBinaryMessenger get _messenger => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

void _answer(String call, Object? value) {
  _messenger.setMockMessageHandler(
    '$_host$call',
    (_) async => AppHostApi.pigeonChannelCodec.encodeMessage(<Object?>[value]),
  );
}

void _fail(String call, String code) {
  _messenger.setMockMessageHandler(
    '$_host$call',
    (_) async => AppHostApi.pigeonChannelCodec.encodeMessage(<Object?>[code, 'message', null]),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    for (final call in [
      'packDelivery',
      'packOffers',
      'requestPack',
      'packStorage',
      'verifyPacks',
      'installDeliveredPack',
    ]) {
      _messenger.setMockMessageHandler('$_host$call', null);
    }
  });

  test('an import-only build reports importOnly and never asks for offers', () async {
    _answer('packDelivery', 'import');
    final m = await BridgePackMaintenance.load(AppHostApi());
    expect(m.delivery, PackDelivery.importOnly);
    // No handler for packOffers: asking would throw. Import-only answers locally.
    expect(await m.offers(), isEmpty);
  });

  test('a store build lists offers with their status', () async {
    _answer('packDelivery', 'store');
    _answer('packOffers', [
      PackOfferMessage(
        id: 'translate-en-es',
        name: 'English → Spanish',
        sizeBytes: 100,
        status: PackOfferStatusMessage.downloading,
      ),
      PackOfferMessage(id: 'dict-ja-mozc', name: 'Japanese', sizeBytes: 200, status: PackOfferStatusMessage.ready),
    ]);
    final m = await BridgePackMaintenance.load(AppHostApi());
    expect(m.delivery, PackDelivery.storeDelivery);
    final offers = await m.offers();
    expect(offers.map((o) => o.id), ['translate-en-es', 'dict-ja-mozc']);
    expect(offers.map((o) => o.status), [PackOfferStatus.downloading, PackOfferStatus.ready]);
    expect(offers.first.sizeBytes, 100);
  });

  test('storage and verification map the platform answers', () async {
    _answer('packDelivery', 'import');
    _answer('packStorage', PackStorageMessage(freeBytes: 5000));
    _answer('verifyPacks', [
      PackCheckMessage(id: 'a', manifestOk: true, missingFiles: 0, damagedFiles: 0),
      PackCheckMessage(id: 'b', manifestOk: true, missingFiles: 1, damagedFiles: 2),
    ]);
    final m = await BridgePackMaintenance.load(AppHostApi());
    expect((await m.storage())?.freeBytes, 5000);
    final checks = await m.verifyInstalled();
    expect(checks.map((c) => c.ok), [true, false]);
    expect(checks.last.missingFiles, 1);
    expect(checks.last.damagedFiles, 2);
  });

  test('unknown storage stays unknown', () async {
    _answer('packDelivery', 'import');
    _answer('packStorage', null);
    final m = await BridgePackMaintenance.load(AppHostApi());
    expect(await m.storage(), isNull);
  });

  test('a refused request surfaces as a PlatformException', () async {
    _answer('packDelivery', 'import');
    _fail('requestPack', 'unsupported');
    final m = await BridgePackMaintenance.load(AppHostApi());
    await expectLater(m.request('x'), throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'unsupported')));
  });

  test('installing a delivered pack returns its name; not delivered surfaces the code', () async {
    _answer('packDelivery', 'store');
    _answer(
      'installDeliveredPack',
      PackInfoMessage(
        id: 'dict-ja-mozc',
        kind: PackKind.dictionary,
        name: 'Japanese dictionary (Mozc)',
        version: 1,
        languages: ['ja'],
        sizeBytes: 1,
        engine: 'mozc',
        license: 'BSD-3-Clause',
      ),
    );
    final m = await BridgePackMaintenance.load(AppHostApi());
    expect(await m.installDelivered('dict-ja-mozc'), 'Japanese dictionary (Mozc)');
    _fail('installDeliveredPack', 'not_delivered');
    await expectLater(
      m.installDelivered('dict-ja-mozc'),
      throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'not_delivered')),
    );
  });
}
