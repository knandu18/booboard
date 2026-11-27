// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (orchestrator-owned, Wave 4): finding installed dictionary packs (Chinese, Japanese)
// and their folders from Dart. Packs are verified by Kotlin (PackStore) before the folder is
// returned; files sit at the paths the pack's manifest lists.
//
// Read pack files off the UI isolate (Isolate.run / compute), and never log their contents or paths.
import 'dart:io';

import '../bridge/messages.g.dart';
import '../engine/contracts.dart';

class InstalledPacks {
  const InstalledPacks(this._platform);

  final PlatformHostApi _platform;

  /// Installed dictionary packs for [language], best first (highest version, then id).
  Future<List<PackInfoMessage>> dictionariesFor(LanguageId language) async {
    final all = await _platform.listPacks();
    final out = [
      for (final p in all)
        if (p.kind == PackKind.dictionary && p.languages.contains(language)) p,
    ]..sort((a, b) => b.version != a.version ? b.version.compareTo(a.version) : a.id.compareTo(b.id));
    return out;
  }

  /// The folder of pack [id], or null when it is not installed (or failed verification).
  Future<Directory?> directory(String id) async {
    final path = await _platform.getPackDirectory(id);
    return path == null ? null : Directory(path);
  }

  /// The first installed dictionary pack for [language] whose engine is [engine] ('rime-ice',
  /// 'mozc', ...), with its folder; null when none is installed.
  Future<(PackInfoMessage, Directory)?> open(LanguageId language, {required String engine}) async {
    for (final p in await dictionariesFor(language)) {
      if (p.engine != engine) continue;
      final dir = await directory(p.id);
      if (dir != null) return (p, dir);
    }
    return null;
  }
}
