// SPDX-License-Identifier: GPL-3.0-or-later
//
// Emoji recents, skin-tone memory, the glyph cache and their privacy rules.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/data_sections.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/features/shared/panel_blob.dart';
import 'package:booboard/src/features/emoji/emoji_store.dart';

const _day = 24 * 3600 * 1000;

/// A blob store that behaves like a locked Keystore: reads come back empty, and writes are recorded.
class _LockedBlobs implements SecureBlobStore {
  final List<String> writes = [];

  @override
  Future<Uint8List?> read(String name) async => null;

  @override
  Future<void> write(String name, Uint8List data) async => writes.add(name);

  @override
  Future<void> delete(String name) async {}

  @override
  Future<void> wipeAll() async {}
}

void main() {
  late InMemorySecureBlobStore blobs;
  late int now;
  late bool incognito;

  EmojiStore make({BlobExists? exists}) => EmojiStore(
    blobs: blobs,
    learningOff: () => incognito,
    exists: exists,
    clock: () => now,
    saveDelay: Duration.zero,
  );

  setUp(() {
    blobs = InMemorySecureBlobStore();
    now = 1000000000000;
    incognito = false;
  });

  group('recents', () {
    test('ranks by use with a half-life, so a fresh use can beat older, more frequent ones', () async {
      final store = make();
      await store.load();
      store.recordUse('🍕');
      store.recordUse('🍕');
      now += 14 * _day; // two half-lives: the pizza count drops to 0.5
      store.recordUse('🍣');
      expect(store.recents(), ['🍣', '🍕']);
    });

    test('keeps at most 32 recents', () async {
      final store = make();
      await store.load();
      for (var i = 0; i < 40; i++) {
        store.recordUse(String.fromCharCode(0x1F600 + i));
        now += 1000;
      }
      expect(store.recents(), hasLength(EmojiStore.maxRecents));
    });

    test('incognito records nothing and writes nothing', () async {
      final store = make();
      await store.load();
      incognito = true;
      store.recordUse('🍕');
      await store.flush();
      expect(store.recents(), isEmpty);
      expect(await blobs.read(DataBlobs.emoji), isNull);
    });
  });

  group('skin tones', () {
    test('a choice is remembered per emoji and becomes the default for new ones', () async {
      final store = make();
      await store.load();
      expect(store.toneFor('👋'), 0);
      store.rememberTone('👋', 3);
      expect(store.toneFor('👋'), 3);
      expect(store.toneFor('🖐'), 3, reason: 'the last choice is the default for a new emoji');
      store.rememberTone('🖐', 0);
      expect(store.toneFor('🖐'), 0);
      expect(store.toneFor('👋'), 3);
    });

    test('a tone choice made in incognito is not kept', () async {
      final store = make();
      await store.load();
      incognito = true;
      store.rememberTone('👋', 2);
      expect(store.toneFor('👋'), 0);
    });
  });

  group('persistence', () {
    test('recents, tones and the glyph cache survive a reload', () async {
      final first = make();
      await first.load();
      first.recordUse('👋🏽');
      first.rememberTone('👋', 3);
      first.setHidden('34|1.0', {'🫩'});
      await first.flush();

      final second = make();
      await second.load();
      expect(second.recents(), ['👋🏽']);
      expect(second.toneFor('👋'), 3);
      expect(second.glyphKey, '34|1.0');
      expect(second.isHidden('🫩'), isTrue);
      expect(second.isHidden('🍕'), isFalse);
    });

    test('a locked blob is never overwritten', () async {
      final locked = _LockedBlobs();
      final store = EmojiStore(
        blobs: locked,
        learningOff: () => false,
        exists: (_) async => true,
        clock: () => now,
        saveDelay: Duration.zero,
      );
      await store.load();
      expect(store.locked, isTrue);
      store.recordUse('🍕');
      await store.flush();
      expect(locked.writes, isEmpty);
    });

    test('a blob that does not exist yet is not treated as locked', () async {
      final store = make(exists: (_) async => false);
      await store.load();
      expect(store.locked, isFalse);
    });

    test('reload reads the data the other engine wrote', () async {
      final a = make();
      await a.load();
      a.recordUse('🍕');
      await a.flush();
      final b = make();
      await b.load();
      expect(b.recents(), ['🍕']);
      a.recordUse('🍣');
      await a.flush();
      b.reload();
      await b.load();
      expect(b.recents(), containsAll(['🍕', '🍣']));
    });
  });

  group('glyph cache', () {
    test('setHidden keeps the set in memory while incognito, and writes once the phone is not incognito', () async {
      final store = make();
      await store.load();
      incognito = true;
      store.setHidden('k', {'x'});
      await store.flush();
      expect(await blobs.read(DataBlobs.emoji), isNull);
      incognito = false;
      await store.flush();
      final again = make();
      await again.load();
      expect(again.isHidden('x'), isTrue);
    });
  });
}
