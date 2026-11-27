// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/data_sections.dart';
import 'package:booboard/src/core/seen_apps.dart';
import 'package:booboard/src/engine/lang/chinese/learned_phrases.dart';
import 'package:booboard/src/engine/lang/japanese/japanese_learning.dart';
import 'package:booboard/src/engine/learn/learned_data.dart';
import 'package:booboard/src/security/backup/backup_collect.dart';
import 'package:booboard/src/security/backup/backup_payload.dart';
import 'package:booboard/src/security/backup/backup_restore.dart';
import 'package:booboard/src/security/custom_theme_files.dart';
import 'package:booboard/src/security/data_wiper.dart';
import 'package:booboard/src/security/shortcuts_store.dart';
import 'package:booboard/src/settings/booboard_settings.dart';
import 'package:booboard/src/settings/settings_store.dart';

import 'support/fakes.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// A learned blob for [language] with [words] committed at [day] and [blocked].
Uint8List _learned(
  String language, {
  Map<String, int> words = const {},
  int day = 1000,
  List<String> blocked = const [],
}) {
  final d = LearnedData(language);
  for (final e in words.entries) {
    for (var i = 0; i < e.value; i++) {
      d.commitWord(e.key, e.key, day, novel: false);
    }
  }
  d.blocked.addAll(blocked);
  return d.encode();
}

int _wordCount(Uint8List? bytes, String language) => LearnedData.decode(language, bytes).words.length;

void main() {
  registerSecurityFallbacks();

  group('mergeLearnedData', () {
    test('counts add up, decayed scores keep the higher value, and blocked words lose their counts', () {
      const today = 1000;
      final local = LearnedData('en')
        ..commitWord('hello', 'hello', today, novel: false)
        ..commitWord('hello', 'hello', today, novel: false)
        ..commitWord('spam', 'spam', today, novel: false);
      final imported = LearnedData('en')
        ..commitWord('hello', 'hello', today - 100, novel: false)
        ..commitWord('world', 'world', today, novel: false)
        ..commitWord('spam', 'spam', today, novel: false)
        ..blocked.add('spam')
        ..commitBigram('hello', 'world', today);

      final merged = mergeLearnedData(local, imported, today);

      expect(merged.words['hello']!.commits, 3);
      expect(merged.words['hello']!.scoreAt(today), 2.0); // local (2) beats the decayed imported copy
      expect(merged.words['world']!.commits, 1);
      expect(merged.words.containsKey('spam'), isFalse);
      expect(merged.blocked, {'spam'});
      expect(merged.bigramScore('hello', 'world', today), 1.0);
    });

    test('an imported copy with a higher decayed score wins the score', () {
      const today = 1000;
      final local = LearnedData('en')..commitWord('cat', 'cat', 0, novel: false); // very old
      final imported = LearnedData('en')
        ..commitWord('cat', 'cat', today, novel: false)
        ..commitWord('cat', 'cat', today, novel: false);
      final merged = mergeLearnedData(local, imported, today);
      expect(merged.words['cat']!.scoreAt(today), closeTo(2.0, 1e-9));
      expect(merged.words['cat']!.commits, 3);
    });
  });

  group('BackupRestorer', () {
    late FakeBlobStore store;
    late MockPlatform platform;
    late ShortcutsStore shortcuts;
    late SettingsStore settings;
    late Directory themesRoot;
    late CustomThemeFiles themes;
    late List<List<String>> notified;
    late BackupRestorer restorer;

    setUp(() {
      store = FakeBlobStore();
      platform = MockPlatform();
      stubPlatform(platform, store);
      shortcuts = ShortcutsStore(store);
      settings = SettingsStore.memory();
      themesRoot = Directory.systemTemp.createTempSync('booboard_restore_test');
      themes = CustomThemeFiles(themesRoot.path);
      notified = [];
      restorer = BackupRestorer(
        store: store,
        platform: platform,
        shortcuts: shortcuts,
        settings: settings,
        themes: themes,
        notify: (sections) async => notified.add(sections),
        clock: () => DateTime.fromMillisecondsSinceEpoch(1000 * 60 * 60 * 24 * 1000),
      );
    });

    tearDown(() {
      if (themesRoot.existsSync()) themesRoot.deleteSync(recursive: true);
    });

    Set<BackupSection> all() => BackupSection.values.toSet();

    test('shortcuts merge keeps the phone copy of a duplicate and adds new ones', () async {
      await shortcuts.add('omw', 'on my way');
      final report = await restorer.apply(
        const BackupContents(
          shortcuts: [
            PersonalShortcut(trigger: 'OMW', expansion: 'other'),
            PersonalShortcut(trigger: 'addr', expansion: 'your address'),
          ],
        ),
        include: {BackupSection.shortcuts},
        mode: RestoreMode.merge,
      );
      final list = await shortcuts.list();
      expect([for (final s in list) s.trigger], ['omw', 'addr']);
      expect(list.first.expansion, 'on my way');
      expect(report.shortcutsAdded, 1);
      expect(report.shortcutsSkipped, 1);
    });

    test('shortcuts replace makes the list match the backup', () async {
      await shortcuts.add('omw', 'on my way');
      await restorer.apply(
        const BackupContents(
          shortcuts: [PersonalShortcut(trigger: 'addr', expansion: 'your address')],
        ),
        include: {BackupSection.shortcuts},
        mode: RestoreMode.replace,
      );
      expect([for (final s in await shortcuts.list()) s.trigger], ['addr']);
    });

    test('learned replace removes other languages and writes only the backup', () async {
      store.blobs['learned_en'] = _learned('en', words: {'hello': 1});
      store.blobs['learned_fr'] = _learned('fr', words: {'bonjour': 1});
      await restorer.apply(
        BackupContents(
          learned: {
            'learned_de': _learned('de', words: {'hallo': 2}),
          },
        ),
        include: {BackupSection.learned},
        mode: RestoreMode.replace,
      );
      expect(store.blobs.keys.toSet(), {'learned_de'});
      expect(_wordCount(store.blobs['learned_de'], 'de'), 1);
    });

    test('Chinese and Japanese learned blobs are restored byte for byte, never decoded as LearnedData', () async {
      final zhBackup = _bytes('{"zh":"backup"}');
      final jaBackup = _bytes('{"ja":"backup"}');
      final zhPhone = _bytes('{"zh":"phone"}');
      store.blobs[DataBlobs.learnedZhPhrases] = zhPhone;
      final contents = BackupContents(
        learned: {
          'learned_en': _learned('en', words: {'hello': 1}),
          DataBlobs.learnedZhPhrases: zhBackup,
          DataBlobs.learnedJaWords: jaBackup,
        },
      );
      expect(contents.summary().learnedLanguages, 1);
      expect(contents.summary().learnedWords, 1);

      await restorer.apply(contents, include: {BackupSection.learned}, mode: RestoreMode.merge);
      expect(store.blobs[DataBlobs.learnedZhPhrases], zhPhone); // a merge keeps the phone's copy
      expect(store.blobs[DataBlobs.learnedJaWords], jaBackup);

      await restorer.apply(contents, include: {BackupSection.learned}, mode: RestoreMode.replace);
      expect(store.blobs[DataBlobs.learnedZhPhrases], zhBackup);
      expect(store.blobs[DataBlobs.learnedJaWords], jaBackup);
      expect(_wordCount(store.blobs['learned_en'], 'en'), 1);
    });

    test('the blob names match the ones the Chinese and Japanese engines write', () {
      expect(learnedZhBlobName, DataBlobs.learnedZhPhrases);
      expect(JapaneseLearning.blobName, DataBlobs.learnedJaWords);
      expect(DataBlobs.isLearnedWords('learned_en'), isTrue);
      expect(DataBlobs.isLearnedWords(DataBlobs.learnedJaWords), isFalse);
    });

    test('learned merge adds counts and unions blocked words', () async {
      store.blobs['learned_en'] = _learned('en', words: {'hello': 1}, blocked: ['spam']);
      final report = await restorer.apply(
        BackupContents(
          learned: {
            'learned_en': _learned('en', words: {'hello': 1, 'world': 1}, blocked: ['junk']),
          },
        ),
        include: {BackupSection.learned},
        mode: RestoreMode.merge,
      );
      final merged = LearnedData.decode('en', store.blobs['learned_en']);
      expect(merged.words['hello']!.commits, 2);
      expect(merged.words.containsKey('world'), isTrue);
      expect(merged.blocked, {'spam', 'junk'});
      expect(report.learnedLanguages, 1);
    });

    test('a locked blob stops the merge before anything is written', () async {
      store.blobs['learned_en'] = _learned('en', words: {'hello': 1});
      store.locked.add('learned_en');
      final before = Map<String, Uint8List>.from(store.blobs);
      final writesBefore = store.writes;

      await expectLater(
        restorer.apply(
          BackupContents(
            learned: {
              'learned_en': _learned('en', words: {'world': 1}),
            },
            shortcuts: const [PersonalShortcut(trigger: 'omw', expansion: 'on my way')],
            settings: BooBoardSettings(privacy: const PrivacySettings(learning: false)).toJson(),
          ),
          include: all(),
          mode: RestoreMode.merge,
        ),
        throwsA(isA<RestoreLockedException>()),
      );

      expect(store.writes, writesBefore);
      expect(store.blobs, before);
      expect(await shortcuts.list(), isEmpty);
      expect(settings.value.privacy.learning, isTrue);
      expect(notified, isEmpty);
    });

    test('a damaged blob no longer blocks a merge: the backup copy replaces it (SEC-06)', () async {
      store.blobs['learned_en'] = _learned('en', words: {'hello': 1});
      store.damaged.add('learned_en');

      final report = await restorer.apply(
        BackupContents(
          learned: {
            'learned_en': _learned('en', words: {'world': 1}),
          },
        ),
        include: {BackupSection.learned},
        mode: RestoreMode.merge,
      );

      final restored = LearnedData.decode('en', store.blobs['learned_en']);
      expect(restored.words.keys, ['world']);
      expect(report.learnedLanguages, 1);
    });

    test('theme merge keeps existing files; replace clears the folder first', () async {
      await themes.write('ocean.json', _bytes('phone ocean'));
      await themes.write('old.json', _bytes('old'));
      final backup = BackupContents(themes: {'ocean.json': _bytes('backup ocean'), 'mint.json': _bytes('mint')});

      final merged = await restorer.apply(backup, include: {BackupSection.themes}, mode: RestoreMode.merge);
      expect(merged.themesAdded, 1);
      expect(merged.themesSkipped, 1);
      expect(await themes.read('ocean.json'), _bytes('phone ocean'));
      expect(await themes.exists('mint.json'), isTrue);

      await restorer.apply(backup, include: {BackupSection.themes}, mode: RestoreMode.replace);
      expect(await themes.read('ocean.json'), _bytes('backup ocean'));
      expect(await themes.exists('old.json'), isFalse);
    });

    test('an unknown clipboard layout on the phone is left alone when merging', () async {
      store.blobs[DataBlobs.clipboard] = _bytes('{"opaque": true}');
      final report = await restorer.apply(
        const BackupContents(clipboard: [BackupClipItem(text: 'pinned', timestampMillis: 5)]),
        include: {BackupSection.clipboard},
        mode: RestoreMode.merge,
      );
      expect(report.clipboardSkipped, isTrue);
      expect(store.blobs[DataBlobs.clipboard], _bytes('{"opaque": true}'));
    });

    test('clipboard merge adds pinned items without duplicates', () async {
      store.blobs[DataBlobs.clipboard] = _bytes(
        jsonEncode({
          'v': 1,
          'items': [
            {'id': '1-0', 'text': 'kept', 'time': 1, 'pinned': false},
          ],
        }),
      );
      final report = await restorer.apply(
        const BackupContents(
          clipboard: [
            BackupClipItem(text: 'pinned', timestampMillis: 5),
            BackupClipItem(text: 'kept', timestampMillis: 6),
          ],
        ),
        include: {BackupSection.clipboard},
        mode: RestoreMode.merge,
      );
      final entries = ClipboardBackupCodec.decodeEntries(store.blobs[DataBlobs.clipboard])!;
      expect([for (final e in entries) e.text], ['kept', 'pinned']);
      expect(report.clipboardAdded, 1);
    });

    test('emoji recents: merge keeps the phone copy, replace takes the backup', () async {
      store.blobs[DataBlobs.emoji] = _bytes('phone');
      var report = await restorer.apply(
        BackupContents(emoji: _bytes('backup')),
        include: {BackupSection.emoji},
        mode: RestoreMode.merge,
      );
      expect(report.emojiKept, isTrue);
      expect(store.blobs[DataBlobs.emoji], _bytes('phone'));

      report = await restorer.apply(
        BackupContents(emoji: _bytes('backup')),
        include: {BackupSection.emoji},
        mode: RestoreMode.replace,
      );
      expect(store.blobs[DataBlobs.emoji], _bytes('backup'));
      expect(report.emojiKept, isFalse);
    });

    test('settings are applied and every restore notifies the keyboard', () async {
      final report = await restorer.apply(
        BackupContents(settings: BooBoardSettings(privacy: const PrivacySettings(learning: false)).toJson()),
        include: {BackupSection.settings},
        mode: RestoreMode.merge,
      );
      expect(settings.value.privacy.learning, isFalse);
      expect(report.settingsApplied, isTrue);
      expect(notified, [
        [DataSections.all],
      ]);
    });

    test('sections not chosen by the user are not touched', () async {
      await shortcuts.add('omw', 'on my way');
      await restorer.apply(
        const BackupContents(
          shortcuts: [PersonalShortcut(trigger: 'addr', expansion: 'x')],
        ),
        include: {BackupSection.learned},
        mode: RestoreMode.replace,
      );
      expect([for (final s in await shortcuts.list()) s.trigger], ['omw']);
    });
  });

  group('BackupCollector', () {
    test('exports pinned clipboard items only, and refuses to skip a locked blob', () async {
      final store = FakeBlobStore();
      final platform = MockPlatform();
      stubPlatform(platform, store);
      store.blobs[DataBlobs.clipboard] = _bytes(
        jsonEncode({
          'v': 1,
          'items': [
            {'id': '1-0', 'text': 'pin', 'time': 1, 'pinned': true},
            {'id': '2-1', 'text': 'temp', 'time': 2, 'pinned': false},
          ],
        }),
      );
      final collector = BackupCollector(
        store: store,
        platform: platform,
        shortcuts: ShortcutsStore(store),
        settings: SettingsStore.memory(),
        themes: CustomThemeFiles('/unused/themes'),
      );

      final contents = await collector.collect(include: {BackupSection.clipboard});
      expect([for (final c in contents.clipboard!) c.text], ['pin']);

      store.locked.add('learned_en');
      store.blobs['learned_en'] = _learned('en', words: {'hello': 1});
      await expectLater(collector.collect(include: {BackupSection.learned}), throwsA(isA<BackupLockedException>()));
    });
  });

  group('DataWiper', () {
    late FakeBlobStore store;
    late MockPlatform platform;
    late SettingsStore settings;
    late ShortcutsStore shortcuts;
    late SeenAppsStore seenApps;
    late Directory root;
    late List<List<String>> notified;
    late DataWiper wiper;

    setUp(() {
      store = FakeBlobStore();
      platform = MockPlatform();
      stubPlatform(platform, store);
      settings = SettingsStore.memory();
      shortcuts = ShortcutsStore(store);
      seenApps = SeenAppsStore(store);
      root = Directory.systemTemp.createTempSync('booboard_wipe_test');
      notified = [];
      wiper = DataWiper(
        store: store,
        platform: platform,
        seenApps: seenApps,
        shortcuts: shortcuts,
        settings: settings,
        themes: CustomThemeFiles('${root.path}/themes'),
        notify: (sections) async => notified.add(sections),
      );
    });

    tearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    test('a category deletes its own blobs and notifies only its section', () async {
      store.blobs['learned_en'] = _learned('en', words: {'hello': 1});
      store.blobs['learned_de'] = _learned('de', words: {'hallo': 1});
      store.blobs[DataBlobs.clipboard] = _bytes('[]');
      await shortcuts.add('omw', 'on my way');

      await wiper.wipe({WipeCategory.learned});

      expect(store.blobs.containsKey('learned_en'), isFalse);
      expect(store.blobs.containsKey('learned_de'), isFalse);
      expect(store.blobs.containsKey(DataBlobs.clipboard), isTrue);
      expect(store.blobs.containsKey(DataBlobs.shortcuts), isTrue);
      expect(notified, [
        [DataSections.learned],
      ]);
    });

    test('shortcuts and apps categories clear their stores and notify', () async {
      await shortcuts.add('omw', 'on my way');
      store.blobs[DataBlobs.seenApps] = _bytes('[]');

      await wiper.wipe({WipeCategory.shortcuts, WipeCategory.apps});

      expect(await shortcuts.list(), isEmpty);
      expect(store.blobs.containsKey(DataBlobs.seenApps), isFalse);
      expect(notified, [
        [DataSections.shortcuts, DataSections.seenApps],
      ]);
    });

    test('wiping custom themes falls back to the default theme when one was selected', () async {
      await settings.update(
        (s) => s.copyWith(appearance: s.appearance.copyWith(themeId: 'my-custom')),
        sections: const [],
      );
      await CustomThemeFiles('${root.path}/themes').write('my-custom.json', _bytes('{}'));

      await wiper.wipe({WipeCategory.themes});

      expect(await CustomThemeFiles('${root.path}/themes').list(), isEmpty);
      expect(settings.value.appearance.themeId, 'booboard_glass_dark');
    });

    test('erase everything wipes the store and custom themes, and resets settings only when asked', () async {
      await settings.update((s) => s.copyWith(privacy: const PrivacySettings(learning: false)), sections: const []);
      store.blobs['learned_en'] = _learned('en');
      await CustomThemeFiles('${root.path}/themes').write('a.json', _bytes('{}'));

      await wiper.wipeEverything(resetSettings: false);
      expect(store.blobs, isEmpty);
      expect(await CustomThemeFiles('${root.path}/themes').list(), isEmpty);
      expect(settings.value.privacy.learning, isFalse);

      await wiper.wipeEverything(resetSettings: true);
      expect(settings.value.privacy.learning, isTrue);
      expect(notified.last, [DataSections.all]);
    });
  });
}
