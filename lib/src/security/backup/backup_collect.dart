// SPDX-License-Identifier: GPL-3.0-or-later
//
// Export side of a backup: reads the chosen sections from their stores. Nothing is written here.
import 'dart:convert';
import 'dart:typed_data';

import '../../bridge/messages.g.dart';
import '../../core/data_sections.dart';
import '../../core/secure_blob_store.dart';
import '../../settings/json_util.dart';
import '../../settings/settings_store.dart';
import '../custom_theme_files.dart';
import '../shortcuts_store.dart';
import 'backup_payload.dart';

/// Thrown when an encrypted blob exists but cannot be read now (locked phone or changed key). An
/// export must never silently leave a section out, so the whole export stops.
class BackupLockedException implements Exception {
  const BackupLockedException();

  @override
  String toString() => 'BackupLockedException';
}

/// The clipboard blob's layout, owned by the clipboard feature (`ClipboardStore`):
/// `{"v": 1, "items": [{"id": String, "text": String, "time": int, "pinned": bool}]}` with times in
/// epoch milliseconds. [decodeEntries] returns null for any other layout, so a restore never
/// overwrites a clipboard it does not understand.
abstract final class ClipboardBackupCodec {
  static const int maxItems = BackupLimits.maxClipboardItems;

  static List<({String text, int ts, bool pinned})>? decodeEntries(Uint8List? bytes) {
    if (bytes == null) return const [];
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map || json['v'] != 1) return null;
      final items = json['items'];
      if (items is! List) return null;
      final out = <({String text, int ts, bool pinned})>[];
      for (final item in items) {
        if (item is! Map) return null;
        final text = item['text'];
        final time = item['time'];
        final pinned = item['pinned'] ?? false;
        if (text is! String || time is! num || pinned is! bool) return null;
        out.add((text: text, ts: time.toInt(), pinned: pinned));
      }
      return out;
    } on Object {
      return null;
    }
  }

  static List<BackupClipItem> pinnedFrom(Uint8List? bytes) {
    final entries = decodeEntries(bytes) ?? const [];
    return [
      for (final e in entries)
        if (e.pinned) BackupClipItem(text: e.text, timestampMillis: e.ts),
    ];
  }

  /// Item ids only need to be unique within the list; the keyboard reloads the history after a restore.
  static Uint8List encode(List<({String text, int ts, bool pinned})> entries) => Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'v': 1,
        'items': [
          for (final (i, e) in entries.indexed) {'id': '${e.ts}-r$i', 'text': e.text, 'time': e.ts, 'pinned': e.pinned},
        ],
      }),
    ),
  );
}

class BackupCollector {
  BackupCollector({
    required this.store,
    required this.platform,
    required this.shortcuts,
    required this.settings,
    required this.themes,
  });

  final SecureBlobStore store;
  final PlatformHostApi platform;
  final ShortcutsStore shortcuts;
  final SettingsStore settings;
  final CustomThemeFiles themes;

  /// Reads the sections in [include]. Throws [BackupLockedException] when a blob is unreadable.
  Future<BackupContents> collect({required Set<BackupSection> include, bool includeThemeImages = false}) async {
    Json? settingsJson;
    if (include.contains(BackupSection.settings)) settingsJson = settings.value.toJson();

    final learned = <String, Uint8List>{};
    if (include.contains(BackupSection.learned)) {
      final names = await _blobNames();
      for (final name in names) {
        if (!name.startsWith(DataBlobs.learnedPrefix)) continue;
        final bytes = await _readOrNull(name);
        if (bytes != null) learned[name] = bytes;
      }
    }

    final shortcutList = include.contains(BackupSection.shortcuts) ? await shortcuts.list() : null;

    List<BackupClipItem>? clipboard;
    if (include.contains(BackupSection.clipboard)) {
      clipboard = ClipboardBackupCodec.pinnedFrom(await _readOrNull(DataBlobs.clipboard));
    }

    Uint8List? emoji;
    if (include.contains(BackupSection.emoji)) emoji = await _readOrNull(DataBlobs.emoji);

    final themeFiles = <String, Uint8List>{};
    if (include.contains(BackupSection.themes)) {
      for (final file in await themes.list()) {
        if (!CustomThemeFiles.isSafeName(file.name)) continue;
        if (file.isImage && !includeThemeImages) continue;
        if (file.sizeBytes > CustomThemeFiles.maxBytesFor(file.name)) continue;
        final bytes = await themes.read(file.name);
        if (bytes != null) themeFiles[file.name] = bytes;
      }
    }

    return BackupContents(
      settings: settingsJson,
      learned: learned,
      shortcuts: shortcutList,
      clipboard: clipboard,
      emoji: emoji,
      themes: themeFiles,
    );
  }

  Future<List<String>> _blobNames() async => [for (final b in await platform.secureList()) b.name];

  /// A missing blob is null. A blob that exists but cannot be read right now (locked phone or
  /// changed key) stops the export rather than leaving that section out silently.
  Future<Uint8List?> _readOrNull(String name) async {
    final bytes = await store.read(name);
    if (bytes != null) return bytes;
    if (!(await _blobNames()).contains(name)) return null;
    throw const BackupLockedException();
  }
}
