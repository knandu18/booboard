// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (orchestrator-owned): names of the encrypted data blobs and of the
// change notifications that tell the other engine to reload them.
//
// Both engines (keyboard and settings app) run in one process but in separate
// isolates. Data lives in SecureBlobStore; when one engine changes a blob it
// calls `PlatformHostApi.notifySettingsChanged([DataSections.x])` and the other
// engine reloads. Settings sections ('typing', 'privacy', ...) travel the same
// way, so these ids all start with 'data.' to keep them apart.

/// SecureBlobStore names. Each must match `[a-z0-9_.-]{1,64}`.
abstract final class DataBlobs {
  /// Learned words for one language: `learned_<languageId>` (Wave 1-B format, `LearnedData`).
  static String learned(String languageId) => 'learned_$languageId';
  static const String learnedPrefix = 'learned_';

  /// Chinese phrases learned from candidate picks (Wave 4-A, its own format, not `LearnedData`).
  static const String learnedZhPhrases = 'learned_zh_phrases';

  /// Japanese conversion picks (Wave 4-B, its own format, not `LearnedData`).
  static const String learnedJaWords = 'learned_ja_words';

  /// `learned_*` blobs in a format of their own: wiped, sized and backed up as they are, never decoded
  /// as `LearnedData` and never opened in the learned-words viewer.
  static const Set<String> learnedOpaque = {learnedZhPhrases, learnedJaWords};

  /// True for a `learned_<languageId>` blob in the `LearnedData` format.
  static bool isLearnedWords(String name) => name.startsWith(learnedPrefix) && !learnedOpaque.contains(name);

  /// Clipboard history (Wave 2-D).
  static const String clipboard = 'clipboard';

  /// Emoji recents and per-emoji skin tones (Wave 2-D).
  static const String emoji = 'emoji';

  /// Personal shortcuts, such as "omw" -> "on my way" (Wave 2-B).
  static const String shortcuts = 'shortcuts';

  /// Apps the keyboard was used in, for the incognito app picker (see `SeenAppsStore`).
  static const String seenApps = 'seen_apps';
}

/// Change notifications for [DataBlobs], sent with `notifySettingsChanged`.
abstract final class DataSections {
  static const String learned = 'data.learned';
  static const String clipboard = 'data.clipboard';
  static const String emoji = 'data.emoji';
  static const String shortcuts = 'data.shortcuts';
  static const String seenApps = 'data.seen_apps';

  /// A model pack was installed or deleted (Wave 3): re-read `PlatformHostApi.listPacks`.
  static const String packs = 'data.packs';

  /// Everything was wiped or restored from a backup: reload every blob.
  static const String all = 'data.all';

  /// True if [sections] asks the receiver to reload [section].
  static bool affects(List<String> sections, String section) => sections.contains(section) || sections.contains(all);
}
