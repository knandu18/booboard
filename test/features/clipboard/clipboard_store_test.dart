// SPDX-License-Identifier: GPL-3.0-or-later
//
// Clipboard history: dedupe, the item cap, expiry, pins, clear-all, locked blobs and the chip preview.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/features/shared/panel_blob.dart';
import 'package:booboard/src/features/clipboard/clipboard_controller.dart';
import 'package:booboard/src/features/clipboard/clipboard_panel.dart';
import 'package:booboard/src/features/clipboard/clipboard_store.dart';
import 'package:booboard/src/settings/sections/clipboard_settings.dart';

const int _minute = 60 * 1000;

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
  late ClipboardSettings settings;

  ClipboardStore make({BlobExists? exists}) => ClipboardStore(
    blobs: blobs,
    settings: () => settings,
    exists: exists,
    clock: () => now,
    saveDelay: Duration.zero,
  );

  setUp(() {
    blobs = InMemorySecureBlobStore();
    now = 10 * 24 * 60 * _minute;
    settings = const ClipboardSettings(maxItems: 5, expiryMinutes: 60);
  });

  test('copies are newest first, and a repeat moves to the top instead of duplicating', () async {
    final store = make();
    await store.load();
    store.add('one');
    now += _minute;
    store.add('two');
    now += _minute;
    store.add('one');
    expect([for (final i in store.items) i.text], ['one', 'two']);
  });

  test('empty and oversized text is never stored', () async {
    final store = make();
    await store.load();
    expect(store.add(''), isFalse);
    expect(store.add('x' * (ClipboardStore.maxTextLength + 1)), isFalse);
    expect(store.items, isEmpty);
  });

  test('a full history makes room by dropping the oldest unpinned item', () async {
    final store = make();
    await store.load();
    for (var i = 1; i <= 5; i++) {
      store.add('item $i');
      now += _minute;
    }
    final oldest = store.items.last;
    store.setPinned(oldest.id, true);
    store.add('item 6');
    expect(store.items, hasLength(5));
    expect(store.items.any((i) => i.text == 'item 1'), isTrue, reason: 'the pinned item stays');
    expect(store.items.any((i) => i.text == 'item 2'), isFalse, reason: 'the oldest unpinned item goes');
  });

  test('a history of pinned items refuses a new copy rather than dropping a pin', () async {
    final store = make();
    await store.load();
    for (var i = 1; i <= 5; i++) {
      store.add('p$i');
      store.setPinned(store.items.first.id, true);
      now += _minute;
    }
    expect(store.add('new'), isFalse);
    expect(store.items, hasLength(5));
    expect(store.items.every((i) => i.pinned), isTrue);
  });

  test('unpinned items expire after expiryMinutes on load and on prune; pinned items never do', () async {
    final store = make();
    await store.load();
    store.add('keep');
    store.setPinned(store.items.first.id, true);
    store.add('gone');
    now += 61 * _minute;
    expect(store.prune(), 1);
    expect([for (final i in store.items) i.text], ['keep']);
    await store.flush();

    final reloaded = make();
    await reloaded.load();
    expect([for (final i in reloaded.items) i.text], ['keep']);
  });

  test('clear all keeps the pinned items', () async {
    final store = make();
    await store.load();
    store.add('a');
    store.setPinned(store.items.first.id, true);
    store.add('b');
    store.clearUnpinned();
    expect([for (final i in store.items) i.text], ['a']);
  });

  test('delete removes one item', () async {
    final store = make();
    await store.load();
    store.add('a');
    store.add('b');
    store.delete(store.items.first.id);
    expect([for (final i in store.items) i.text], ['a']);
  });

  test('history survives a reload, with pins', () async {
    final first = make();
    await first.load();
    first.add('secret note');
    first.setPinned(first.items.first.id, true);
    await first.flush();
    final second = make();
    await second.load();
    expect(second.items.single.text, 'secret note');
    expect(second.items.single.pinned, isTrue);
  });

  test('a locked history is not overwritten and accepts no copies', () async {
    final locked = _LockedBlobs();
    final store = ClipboardStore(
      blobs: locked,
      settings: () => settings,
      exists: (_) async => true,
      clock: () => now,
      saveDelay: Duration.zero,
    );
    await store.load();
    expect(store.locked, isTrue);
    expect(store.add('copy'), isFalse);
    store.clearUnpinned();
    await store.flush();
    expect(locked.writes, isEmpty);
  });

  test('reload reads what the other engine wrote (the privacy center wiped or restored it)', () async {
    final a = make();
    await a.load();
    a.add('from the keyboard');
    await a.flush();
    final b = make();
    await b.load();
    expect(b.items.single.text, 'from the keyboard');
    a.clearUnpinned();
    await a.flush();
    b.reload();
    await b.load(force: true);
    expect(b.items, isEmpty);
  });

  test('a blob that is not there yet is not locked', () async {
    final store = make(exists: (_) async => false);
    await store.load();
    expect(store.locked, isFalse);
  });

  group('chip preview', () {
    test('shows short text whole, and newlines as a return sign', () {
      expect(ClipboardController.previewOf('hi'), 'hi');
      expect(ClipboardController.previewOf('a\nb'), 'a⏎b');
      expect(ClipboardController.previewOf('a\r\nb'), 'a⏎b');
    });

    test('cuts long text after 20 characters, by character not by code unit', () {
      final text = '😀' * 25;
      final preview = ClipboardController.previewOf(text);
      expect(preview, '${'😀' * 20}…');
    });
  });

  group('expiry label', () {
    test('describes the common expiries in words', () {
      expect(expiryLabel(60), '1 hour');
      expect(expiryLabel(15), '15 minutes');
      expect(expiryLabel(24 * 60), '1 day');
      expect(expiryLabel(7 * 24 * 60), '1 week');
      expect(expiryLabel(2 * 60), '2 hours');
    });
  });
}
