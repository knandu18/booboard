// SPDX-License-Identifier: GPL-3.0-or-later
//
// The plain content of a .boobackup file, before AppHostApi.sealBackup encrypts it. Layout:
//
//   {"format": 1, "createdAt": "2026-11-21T10:00:00.000Z", "appVersion": "1.0.0+1",
//    "sections": {
//      "settings":  { ...BooBoardSettings JSON... },
//      "learned":   { "learned_en": "<base64 LearnedData>" },
//      "shortcuts": [ {"trigger": "omw", "expansion": "on my way"} ],
//      "clipboard": [ {"text": "...", "ts": 1763719200000} ],       (pinned items only)
//      "emoji":     "<base64>",
//      "themes":    { "ocean.json": "<base64>", "photo.jpg": "<base64>" } } }
//
// Decoding is strict. Every size, count, name and value is checked before anything is written, and
// a failure names the rule that broke, never the content.
// PRIVACY: nothing in this file is logged.
import 'dart:convert';
import 'dart:typed_data';

import '../../core/data_sections.dart';
import '../../engine/learn/learned_data.dart';
import '../../settings/json_util.dart';
import '../../settings/booboard_settings.dart';
import '../custom_theme_files.dart';
import '../shortcuts_store.dart';

const int kBackupFormat = 1;

/// Largest plain payload accepted on import (the Kotlin side reads at most this many bytes).
const int kMaxBackupBytes = 64 * 1024 * 1024;

abstract final class BackupLimits {
  static const int maxLearnedLanguages = 16;
  static const int maxLearnedBlobBytes = 16 * 1024 * 1024;
  static const int maxEmojiBytes = 256 * 1024;
  static const int maxClipboardItems = 100;
  static const int maxClipboardChars = 10000;
  static const int maxSettingsChars = 256 * 1024;
  static const int maxThemes = 100;
  static const int maxAppVersionChars = 64;
  static final RegExp learnedName = RegExp(r'^learned_[a-z0-9_.-]{1,50}$');
}

/// The sections a user can include in a backup or restore.
enum BackupSection {
  settings('Settings'),
  learned('Learned words'),
  shortcuts('Personal shortcuts'),
  clipboard('Pinned clipboard items'),
  emoji('Emoji recents'),
  themes('Custom themes');

  const BackupSection(this.label);

  final String label;
}

/// Thrown by [BackupPayload.decode]. [rule] is a fixed identifier such as `bad_format`.
class BackupFormatException implements Exception {
  BackupFormatException(this.rule);

  final String rule;

  @override
  String toString() => 'BackupFormatException($rule)';
}

class BackupClipItem {
  const BackupClipItem({required this.text, required this.timestampMillis});

  final String text;
  final int timestampMillis;
}

/// The data inside a backup. A null or empty field means the section was not included.
class BackupContents {
  const BackupContents({
    this.settings,
    this.learned = const {},
    this.shortcuts,
    this.clipboard,
    this.emoji,
    this.themes = const {},
  });

  /// Raw BooBoardSettings JSON (validated by [BooBoardSettings.fromJson] before use).
  final Json? settings;

  /// Blob name (`learned_<language>`) to the raw LearnedData bytes.
  final Map<String, Uint8List> learned;
  final List<PersonalShortcut>? shortcuts;
  final List<BackupClipItem>? clipboard;
  final Uint8List? emoji;

  /// File name to bytes.
  final Map<String, Uint8List> themes;

  Set<BackupSection> get present => {
    if (settings != null) BackupSection.settings,
    if (learned.isNotEmpty) BackupSection.learned,
    if (shortcuts != null) BackupSection.shortcuts,
    if (clipboard != null) BackupSection.clipboard,
    if (emoji != null) BackupSection.emoji,
    if (themes.isNotEmpty) BackupSection.themes,
  };

  /// What the preview screen shows before the user confirms a restore.
  BackupSummary summary() {
    var words = 0;
    var languages = 0;
    for (final entry in learned.entries) {
      if (!DataBlobs.isLearnedWords(entry.key)) continue;
      languages++;
      final language = entry.key.substring(DataBlobs.learnedPrefix.length);
      words += LearnedData.decode(language, entry.value).words.length;
    }
    return BackupSummary(
      learnedWords: words,
      learnedLanguages: languages,
      shortcuts: shortcuts?.length ?? 0,
      clipboardItems: clipboard?.length ?? 0,
      emojiBytes: emoji?.length ?? 0,
      themes: themes.length,
      themeBytes: themes.values.fold(0, (sum, b) => sum + b.length),
    );
  }
}

/// Plain-language counts for the import preview.
class BackupSummary {
  const BackupSummary({
    required this.learnedWords,
    required this.learnedLanguages,
    required this.shortcuts,
    required this.clipboardItems,
    required this.emojiBytes,
    required this.themes,
    required this.themeBytes,
  });

  final int learnedWords;
  final int learnedLanguages;
  final int shortcuts;
  final int clipboardItems;
  final int emojiBytes;
  final int themes;
  final int themeBytes;
}

class BackupPayload {
  BackupPayload({required this.createdAt, required this.appVersion, required this.contents});

  final DateTime createdAt;
  final String appVersion;
  final BackupContents contents;

  Uint8List encode() {
    final c = contents;
    final sections = <String, Object?>{
      if (c.settings != null) 'settings': c.settings,
      if (c.learned.isNotEmpty) 'learned': {for (final e in c.learned.entries) e.key: base64.encode(e.value)},
      if (c.shortcuts != null) 'shortcuts': [for (final s in c.shortcuts!) s.toJson()],
      if (c.clipboard != null)
        'clipboard': [
          for (final i in c.clipboard!) {'text': i.text, 'ts': i.timestampMillis},
        ],
      if (c.emoji != null) 'emoji': base64.encode(c.emoji!),
      if (c.themes.isNotEmpty) 'themes': {for (final e in c.themes.entries) e.key: base64.encode(e.value)},
    };
    final json = <String, Object?>{
      'format': kBackupFormat,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'appVersion': appVersion,
      'sections': sections,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(json)));
  }

  /// Parses and validates a plain payload. Throws [BackupFormatException] on any violation.
  static BackupPayload decode(Uint8List bytes) {
    if (bytes.length > kMaxBackupBytes) throw BackupFormatException('too_large');
    final Object? root;
    try {
      root = jsonDecode(utf8.decode(bytes));
    } on Object {
      throw BackupFormatException('not_json');
    }
    if (root is! Map) throw BackupFormatException('bad_root');
    final format = root['format'];
    if (format is int && format > kBackupFormat) throw BackupFormatException('newer_format');
    if (format != kBackupFormat) throw BackupFormatException('bad_format');

    final createdRaw = root['createdAt'];
    final createdAt = createdRaw is String ? DateTime.tryParse(createdRaw) : null;
    if (createdAt == null) throw BackupFormatException('bad_created_at');
    final appVersion = root['appVersion'];
    if (appVersion is! String || appVersion.length > BackupLimits.maxAppVersionChars) {
      throw BackupFormatException('bad_app_version');
    }
    final sections = root['sections'];
    if (sections is! Map) throw BackupFormatException('bad_sections');

    return BackupPayload(
      createdAt: createdAt,
      appVersion: appVersion,
      contents: BackupContents(
        settings: _settings(sections['settings']),
        learned: _learned(sections['learned']),
        shortcuts: _shortcuts(sections['shortcuts']),
        clipboard: _clipboard(sections['clipboard']),
        emoji: _emoji(sections['emoji']),
        themes: _themes(sections['themes']),
      ),
    );
  }

  static Json? _settings(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) throw BackupFormatException('bad_settings');
    final json = raw.cast<String, Object?>();
    if (jsonEncode(json).length > BackupLimits.maxSettingsChars) throw BackupFormatException('settings_too_large');
    return json;
  }

  static Map<String, Uint8List> _learned(Object? raw) {
    if (raw == null) return const {};
    if (raw is! Map) throw BackupFormatException('bad_learned');
    if (raw.length > BackupLimits.maxLearnedLanguages) throw BackupFormatException('too_many_languages');
    final out = <String, Uint8List>{};
    for (final entry in raw.entries) {
      final name = entry.key;
      if (name is! String || !BackupLimits.learnedName.hasMatch(name)) {
        throw BackupFormatException('bad_learned_name');
      }
      final bytes = _base64(entry.value, 'bad_learned_blob', BackupLimits.maxLearnedBlobBytes);
      out[name] = bytes;
    }
    return out;
  }

  static List<PersonalShortcut>? _shortcuts(Object? raw) {
    if (raw == null) return null;
    if (raw is! List) throw BackupFormatException('bad_shortcuts');
    if (raw.length > ShortcutRules.maxShortcuts) throw BackupFormatException('too_many_shortcuts');
    final out = <PersonalShortcut>[];
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map) throw BackupFormatException('bad_shortcut');
      final trigger = item['trigger'];
      final expansion = item['expansion'];
      if (trigger is! String || expansion is! String) throw BackupFormatException('bad_shortcut');
      if (ShortcutRules.checkTrigger(trigger) != null || ShortcutRules.checkExpansion(expansion) != null) {
        throw BackupFormatException('bad_shortcut');
      }
      if (!seen.add(trigger.trim().toLowerCase())) throw BackupFormatException('duplicate_shortcut');
      out.add(PersonalShortcut(trigger: trigger.trim(), expansion: expansion.trim()));
    }
    return out;
  }

  static List<BackupClipItem>? _clipboard(Object? raw) {
    if (raw == null) return null;
    if (raw is! List) throw BackupFormatException('bad_clipboard');
    if (raw.length > BackupLimits.maxClipboardItems) throw BackupFormatException('too_many_clips');
    final out = <BackupClipItem>[];
    for (final item in raw) {
      if (item is! Map) throw BackupFormatException('bad_clip');
      final text = item['text'];
      final ts = item['ts'];
      if (text is! String || text.isEmpty || text.length > BackupLimits.maxClipboardChars) {
        throw BackupFormatException('bad_clip');
      }
      if (ts is! int || ts < 0) throw BackupFormatException('bad_clip');
      out.add(BackupClipItem(text: text, timestampMillis: ts));
    }
    return out;
  }

  static Uint8List? _emoji(Object? raw) {
    if (raw == null) return null;
    return _base64(raw, 'bad_emoji', BackupLimits.maxEmojiBytes);
  }

  static Map<String, Uint8List> _themes(Object? raw) {
    if (raw == null) return const {};
    if (raw is! Map) throw BackupFormatException('bad_themes');
    if (raw.length > BackupLimits.maxThemes) throw BackupFormatException('too_many_themes');
    final out = <String, Uint8List>{};
    for (final entry in raw.entries) {
      final name = entry.key;
      if (name is! String || !CustomThemeFiles.isSafeName(name)) throw BackupFormatException('bad_theme_name');
      out[name] = _base64(entry.value, 'bad_theme_file', CustomThemeFiles.maxBytesFor(name));
    }
    return out;
  }

  static Uint8List _base64(Object? value, String rule, int maxBytes) {
    if (value is! String) throw BackupFormatException(rule);
    final Uint8List bytes;
    try {
      bytes = base64.decode(value);
    } on FormatException {
      throw BackupFormatException(rule);
    }
    if (bytes.length > maxBytes) throw BackupFormatException('${rule}_too_large');
    return bytes;
  }
}
