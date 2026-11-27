// SPDX-License-Identifier: GPL-3.0-or-later
//
// Import side of a backup. Merge keeps what is on the phone and adds the backup; Replace makes the
// chosen sections match the backup. Every section is checked for readable existing data before the
// first write, so a locked phone can never cost the user their current data.
import 'dart:math' as math;
import 'dart:typed_data';

import '../../bridge/messages.g.dart';
import '../../core/data_sections.dart';
import '../../core/secure_blob_store.dart';
import '../../engine/learn/learned_data.dart';
import '../../settings/booboard_settings.dart';
import '../../settings/settings_store.dart';
import '../custom_theme_files.dart';
import '../shortcuts_store.dart';
import 'backup_collect.dart';
import 'backup_payload.dart';

enum RestoreMode { merge, replace }

/// Thrown before anything is written, when existing encrypted data cannot be read now.
class RestoreLockedException implements Exception {
  const RestoreLockedException();

  @override
  String toString() => 'RestoreLockedException';
}

class RestoreReport {
  const RestoreReport({
    this.learnedLanguages = 0,
    this.shortcutsAdded = 0,
    this.shortcutsSkipped = 0,
    this.clipboardAdded = 0,
    this.clipboardSkipped = false,
    this.emojiKept = false,
    this.themesAdded = 0,
    this.themesSkipped = 0,
    this.settingsApplied = false,
  });

  final int learnedLanguages;
  final int shortcutsAdded;

  /// Duplicates of shortcuts already on the phone (merge), or over the limit.
  final int shortcutsSkipped;
  final int clipboardAdded;

  /// True when the phone's clipboard layout is unknown, so it was left alone.
  final bool clipboardSkipped;

  /// Merge kept the phone's own emoji recents.
  final bool emojiKept;
  final int themesAdded;

  /// Theme files that already existed on the phone (merge keeps the phone's copy).
  final int themesSkipped;
  final bool settingsApplied;
}

/// Combines two learned-word sets for one language. Counts add up, the decayed scores are compared
/// as of [today] and the higher one is kept, and blocked words lose every count. Only [LearnedData.encode]
/// is meant to be called on the result.
LearnedData mergeLearnedData(LearnedData local, LearnedData imported, int today) {
  final out = LearnedData(local.language);

  for (final key in {...local.words.keys, ...imported.words.keys}) {
    final a = local.words[key];
    final b = imported.words[key];
    if (a == null || b == null) {
      final w = (a ?? b)!;
      out.words[key] = LearnedWord(w.surface, commits: w.commits, score: w.scoreAt(today), day: today, novel: w.novel);
    } else {
      out.words[key] = LearnedWord(
        a.surface,
        commits: a.commits + b.commits,
        score: math.max(a.scoreAt(today), b.scoreAt(today)),
        day: today,
        novel: a.novel || b.novel,
      );
    }
  }

  for (final previous in {...local.bigrams.keys, ...imported.bigrams.keys}) {
    final a = local.bigrams[previous] ?? const <String, LearnedBigram>{};
    final b = imported.bigrams[previous] ?? const <String, LearnedBigram>{};
    final inner = <String, LearnedBigram>{};
    for (final next in {...a.keys, ...b.keys}) {
      final score = math.max(a[next]?.scoreAt(today) ?? 0, b[next]?.scoreAt(today) ?? 0);
      inner[next] = LearnedBigram(score: score, day: today);
    }
    if (inner.isNotEmpty) out.bigrams[previous] = inner;
  }

  out.blocked.addAll(local.blocked);
  out.blocked.addAll(imported.blocked);
  for (final word in out.blocked.toList()) {
    out.removeWord(word);
  }
  return out;
}

class BackupRestorer {
  BackupRestorer({
    required this.store,
    required this.platform,
    required this.shortcuts,
    required this.settings,
    required this.themes,
    required this.notify,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SecureBlobStore store;
  final PlatformHostApi platform;
  final ShortcutsStore shortcuts;
  final SettingsStore settings;
  final CustomThemeFiles themes;
  final Future<void> Function(List<String> sections) notify;
  final DateTime Function() _clock;

  Future<RestoreReport> apply(
    BackupContents contents, {
    required Set<BackupSection> include,
    required RestoreMode mode,
  }) async {
    final replace = mode == RestoreMode.replace;
    // Validate the settings section before anything is written: a malformed section must not leave a
    // half-applied restore (in replace mode the learned blobs are deleted first).
    final incomingSettings = contents.settings;
    final parsedSettings = include.contains(BackupSection.settings) && incomingSettings != null
        ? BooBoardSettings.fromJson(incomingSettings)
        : null;
    final blobNames = {for (final b in await platform.secureList()) b.name};

    // Checks first: every existing blob that a merge will read must be readable now.
    final existing = <String, Uint8List?>{};
    final needsRead = <String>[
      if (!replace && include.contains(BackupSection.learned)) ...contents.learned.keys,
      if (!replace && include.contains(BackupSection.clipboard) && contents.clipboard != null) DataBlobs.clipboard,
      if (!replace && include.contains(BackupSection.emoji) && contents.emoji != null) DataBlobs.emoji,
    ];
    for (final name in needsRead) {
      if (!blobNames.contains(name)) continue;
      final s = store;
      if (s is StrictSecureBlobRead) {
        // SEC-06: only a locked phone stops the restore. A damaged blob reads as null and is merged as
        // empty, so the backup's copy replaces it instead of failing with "phone is locked" forever.
        try {
          existing[name] = await (s as StrictSecureBlobRead).readStrict(name);
        } on SecureStoreLockedException {
          throw const RestoreLockedException();
        }
      } else {
        final bytes = await s.read(name);
        if (bytes == null) throw const RestoreLockedException();
        existing[name] = bytes;
      }
    }

    var learnedLanguages = 0;
    if (include.contains(BackupSection.learned) && contents.learned.isNotEmpty) {
      final today = dayNumber(_clock());
      if (replace) {
        for (final name in blobNames) {
          if (name.startsWith(DataBlobs.learnedPrefix)) await store.delete(name);
        }
      }
      for (final entry in contents.learned.entries) {
        if (!DataBlobs.isLearnedWords(entry.key)) {
          // Chinese and Japanese picks have formats of their own: a merge keeps what this device has.
          if (replace || existing[entry.key] == null) await store.write(entry.key, entry.value);
          continue;
        }
        final language = entry.key.substring(DataBlobs.learnedPrefix.length);
        final imported = LearnedData.decode(language, entry.value);
        final out = replace
            ? imported
            : mergeLearnedData(LearnedData.decode(language, existing[entry.key]), imported, today);
        await store.write(entry.key, out.encode());
        learnedLanguages++;
      }
    }

    var shortcutsAdded = 0;
    var shortcutsSkipped = 0;
    final incomingShortcuts = contents.shortcuts;
    if (include.contains(BackupSection.shortcuts) && incomingShortcuts != null) {
      if (replace) {
        await shortcuts.replaceAll(incomingShortcuts);
        shortcutsAdded = incomingShortcuts.length;
      } else {
        final next = [...await shortcuts.list()];
        final keys = {for (final s in next) s.trigger.toLowerCase()};
        for (final s in incomingShortcuts) {
          if (keys.contains(s.trigger.toLowerCase()) || next.length >= ShortcutRules.maxShortcuts) {
            shortcutsSkipped++;
            continue;
          }
          keys.add(s.trigger.toLowerCase());
          next.add(s);
          shortcutsAdded++;
        }
        await shortcuts.replaceAll(next);
      }
    }

    var clipboardAdded = 0;
    var clipboardSkipped = false;
    final incomingClips = contents.clipboard;
    if (include.contains(BackupSection.clipboard) && incomingClips != null) {
      // Replace starts empty. Merge needs a clipboard layout it understands, or it leaves the phone's alone.
      final phoneEntries = replace
          ? const <({String text, int ts, bool pinned})>[]
          : ClipboardBackupCodec.decodeEntries(existing[DataBlobs.clipboard]);
      if (phoneEntries == null) {
        clipboardSkipped = true;
      } else {
        final next = [...phoneEntries];
        final texts = {for (final e in next) e.text};
        for (final item in incomingClips) {
          if (next.length >= ClipboardBackupCodec.maxItems || !texts.add(item.text)) continue;
          next.add((text: item.text, ts: item.timestampMillis, pinned: true));
          clipboardAdded++;
        }
        await store.write(DataBlobs.clipboard, ClipboardBackupCodec.encode(next));
      }
    }

    var emojiKept = false;
    final incomingEmoji = contents.emoji;
    if (include.contains(BackupSection.emoji) && incomingEmoji != null) {
      if (!replace && existing[DataBlobs.emoji] != null) {
        emojiKept = true;
      } else {
        await store.write(DataBlobs.emoji, incomingEmoji);
      }
    }

    var themesAdded = 0;
    var themesSkipped = 0;
    if (include.contains(BackupSection.themes) && contents.themes.isNotEmpty) {
      if (replace) await themes.deleteAll();
      for (final entry in contents.themes.entries) {
        if (!replace && await themes.exists(entry.key)) {
          themesSkipped++;
          continue;
        }
        await themes.write(entry.key, entry.value);
        themesAdded++;
      }
    }

    var settingsApplied = false;
    if (parsedSettings != null) {
      await settings.update((_) => parsedSettings, sections: SettingsSection.all);
      settingsApplied = true;
    }

    await notify([DataSections.all]);
    return RestoreReport(
      learnedLanguages: learnedLanguages,
      shortcutsAdded: shortcutsAdded,
      shortcutsSkipped: shortcutsSkipped,
      clipboardAdded: clipboardAdded,
      clipboardSkipped: clipboardSkipped,
      emojiKept: emojiKept,
      themesAdded: themesAdded,
      themesSkipped: themesSkipped,
      settingsApplied: settingsApplied,
    );
  }
}
