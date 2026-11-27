// SPDX-License-Identifier: GPL-3.0-or-later
//
// Hiding emoji the device cannot draw: the version fast path, batching, the cache key and failures.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/features/emoji/emoji_data.dart';
import 'package:booboard/src/features/emoji/emoji_glyphs.dart';
import 'package:booboard/src/features/emoji/emoji_store.dart';

class _MockPlatform extends Mock implements PlatformHostApi {}

AppInfoMessage _app(int sdk, [String version = '1.0.0']) => AppInfoMessage(
  packageName: 'app.booboard.keyboard',
  versionName: version,
  versionCode: 1,
  sdkInt: sdk,
  isDebugBuild: true,
);

void main() {
  late EmojiData data;
  late _MockPlatform platform;
  late EmojiStore store;
  late List<List<String>> batches;
  late int now;

  setUpAll(() {
    registerFallbackValue(<String>[]);
    data = decodeEmojiData(File('assets/emoji/emoji.dat').readAsBytesSync());
  });

  setUp(() {
    platform = _MockPlatform();
    batches = [];
    now = 0;
    store = EmojiStore(
      blobs: InMemorySecureBlobStore(),
      learningOff: () => false,
      clock: () => now,
      saveDelay: Duration.zero,
    );
    when(() => platform.getAppInfo()).thenAnswer((_) async => _app(37));
  });

  /// Answers every batch as drawable, except the texts in [missing]. Records what was asked.
  void answerWith({Set<String> missing = const {}}) {
    when(() => platform.hasGlyphs(any())).thenAnswer((inv) async {
      final batch = inv.positionalArguments.first as List<String>;
      batches.add(batch);
      return [for (final t in batch) !missing.contains(t)];
    });
  }

  test('emoji the font is known to draw are never sent; the rest go in batches of at most 200', () async {
    answerWith();
    final glyphs = EmojiGlyphs(platform: platform, store: store);
    expect(await glyphs.ensureChecked(data), isTrue);

    final sent = [for (final b in batches) ...b];
    final guaranteed = EmojiGlyphs.guaranteedVersion(37);
    final expected = <String>{};
    for (final i in data.items) {
      if (i.version <= guaranteed) continue;
      expected.add(i.text);
      for (final t in i.tones ?? const <String?>[]) {
        if (t != null) expected.add(t);
      }
    }
    expect(sent.toSet(), expected);
    expect(sent.length, expected.length, reason: 'each text is asked once');
    expect(batches.every((b) => b.length <= EmojiGlyphs.batchSize), isTrue);
  });

  test('emoji the device cannot draw are hidden, and the rest are not', () async {
    final newest = data.items.lastWhere((i) => i.version > EmojiGlyphs.guaranteedVersion(37));
    answerWith(missing: {newest.text});
    final glyphs = EmojiGlyphs(platform: platform, store: store);
    await glyphs.ensureChecked(data);
    expect(store.isHidden(newest.text), isTrue);
    expect(store.isHidden('🍕'), isFalse);
  });

  test('the answer is cached by SDK and app version: a second open sends nothing', () async {
    answerWith();
    final glyphs = EmojiGlyphs(platform: platform, store: store);
    await glyphs.ensureChecked(data);
    final firstRound = batches.length;
    expect(firstRound, greaterThan(0));
    expect(store.glyphKey, '37|1.0.0');

    await glyphs.ensureChecked(data);
    expect(batches.length, firstRound, reason: 'the cached answer is reused');

    when(() => platform.getAppInfo()).thenAnswer((_) async => _app(37, '1.0.1'));
    await glyphs.ensureChecked(data);
    expect(batches.length, greaterThan(firstRound), reason: 'a new app version checks again');
    expect(store.glyphKey, '37|1.0.1');
  });

  test('when the platform cannot answer, nothing is cached and every emoji is kept', () async {
    when(() => platform.hasGlyphs(any())).thenThrow(StateError('no font service'));
    final glyphs = EmojiGlyphs(platform: platform, store: store);
    expect(await glyphs.ensureChecked(data), isFalse);
    expect(store.glyphKey, isEmpty);
    expect(store.isHidden(data.items.last.text), isFalse);
  });

  test('the guaranteed version rises with the SDK, and stays conservative', () {
    expect(EmojiGlyphs.guaranteedVersion(26), lessThan(EmojiGlyphs.guaranteedVersion(31)));
    expect(EmojiGlyphs.guaranteedVersion(31), lessThan(EmojiGlyphs.guaranteedVersion(34)));
    expect(EmojiGlyphs.guaranteedVersion(37), lessThan(180), reason: 'Emoji 18.0 is always checked');
  });
}
