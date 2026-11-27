// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/data_sections.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/security/shortcuts_store.dart';

void main() {
  late InMemorySecureBlobStore blobs;
  late ShortcutsStore store;

  setUp(() {
    blobs = InMemorySecureBlobStore();
    store = ShortcutsStore(blobs);
  });

  group('validation', () {
    test('triggers: letters, digits and apostrophes in any script, 1 to 32 characters', () {
      expect(ShortcutRules.checkTrigger('omw'), isNull);
      expect(ShortcutRules.checkTrigger("don't"), isNull);
      expect(ShortcutRules.checkTrigger('café'), isNull);
      expect(ShortcutRules.checkTrigger('नमस्ते'), isNull); // Devanagari uses combining marks
      expect(ShortcutRules.checkTrigger('   '), ShortcutProblem.emptyTrigger);
      expect(ShortcutRules.checkTrigger('a b'), ShortcutProblem.triggerCharacters);
      expect(ShortcutRules.checkTrigger('a-b'), ShortcutProblem.triggerCharacters);
      expect(ShortcutRules.checkTrigger('a' * 32), isNull);
      expect(ShortcutRules.checkTrigger('a' * 33), ShortcutProblem.triggerTooLong);
    });

    test('expansions: not empty, at most 500 characters', () {
      expect(ShortcutRules.checkExpansion('on my way'), isNull);
      expect(ShortcutRules.checkExpansion('  '), ShortcutProblem.emptyExpansion);
      expect(ShortcutRules.checkExpansion('x' * 500), isNull);
      expect(ShortcutRules.checkExpansion('x' * 501), ShortcutProblem.expansionTooLong);
    });
  });

  test('add, list in order, and persist across store instances', () async {
    expect(await store.add('omw', 'on my way'), isNull);
    expect(await store.add('addr', 'your address'), isNull);
    expect([for (final s in await store.list()) s.trigger], ['omw', 'addr']);

    final reopened = ShortcutsStore(blobs);
    final back = await reopened.list();
    expect(back.map((s) => s.expansion), ['on my way', 'your address']);
  });

  test('triggers are unique case-insensitively', () async {
    await store.add('omw', 'on my way');
    expect(await store.add('OMW', 'other'), ShortcutProblem.duplicateTrigger);
    expect((await store.list()).single.expansion, 'on my way');
  });

  test('update keeps its position and may keep its own trigger', () async {
    await store.add('omw', 'on my way');
    await store.add('addr', 'your address');
    expect(await store.update('omw', 'OMW', 'on my way, sorry'), isNull);
    expect(await store.update('addr', 'omw', 'x'), ShortcutProblem.duplicateTrigger);
    final list = await store.list();
    expect(list.first.trigger, 'OMW');
    expect(list.first.expansion, 'on my way, sorry');
  });

  test('remove deletes one shortcut', () async {
    await store.add('omw', 'on my way');
    await store.add('addr', 'your address');
    await store.remove('OMW');
    expect([for (final s in await store.list()) s.trigger], ['addr']);
  });

  test('the list is capped at 500 shortcuts', () async {
    await store.replaceAll([
      for (var i = 0; i < ShortcutRules.maxShortcuts; i++) PersonalShortcut(trigger: 't$i', expansion: 'x'),
    ]);
    expect(await store.add('onemore', 'x'), ShortcutProblem.tooManyShortcuts);
  });

  test('clear deletes the stored blob', () async {
    await store.add('omw', 'on my way');
    await store.clear();
    expect(await blobs.read(DataBlobs.shortcuts), isNull);
    expect(await store.list(), isEmpty);
  });

  test('decode drops corrupt, invalid and duplicate entries instead of failing', () {
    final raw = jsonEncode([
      {'trigger': 'omw', 'expansion': 'on my way'},
      {'trigger': 'a b', 'expansion': 'invalid'},
      {'trigger': 'OMW', 'expansion': 'duplicate'},
      {'trigger': 'addr'},
      'not a map',
      {'trigger': 'addr', 'expansion': 'your address'},
    ]);
    final decoded = ShortcutsStore.decode(Uint8List.fromList(utf8.encode(raw)));
    expect([for (final s in decoded) s.trigger], ['omw', 'addr']);
    expect(ShortcutsStore.decode(Uint8List.fromList(utf8.encode('{bad'))), isEmpty);
    expect(ShortcutsStore.decode(null), isEmpty);
  });
}
