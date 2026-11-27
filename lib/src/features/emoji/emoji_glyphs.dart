// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Hides the emoji the device font cannot draw.
//
// Fast first cut: an emoji whose Unicode version is at or below what the platform font is known to
// have for this SDK is shown without asking. The rest go to PlatformHostApi.hasGlyphs in batches of
// 200, on first open. The result is cached in DataBlobs.emoji under `<sdkInt>|<versionName>`, so a
// new Android version or app update checks again.
import '../../bridge/messages.g.dart';
import '../../core/log.dart';
import 'emoji_data.dart';
import 'emoji_store.dart';

class EmojiGlyphs {
  EmojiGlyphs({required this.platform, required this.store});

  final PlatformHostApi platform;
  final EmojiStore store;

  static const int batchSize = 200;

  /// The newest emoji version (times ten) the platform font is known to draw for [sdkInt]. Deliberately
  /// low: anything newer is checked, so a guess never shows a missing glyph.
  static int guaranteedVersion(int sdkInt) {
    if (sdkInt >= 34) return 150; // Android 14 ships Emoji 15.0.
    if (sdkInt >= 31) return 130; // Android 12 ships Emoji 13.0.
    return 50;
  }

  /// Makes sure [store] knows which emoji are hidden for this device and app build. Returns false when
  /// the platform could not answer (the panel then shows everything).
  Future<bool> ensureChecked(EmojiData data) async {
    final AppInfoMessage app;
    try {
      app = await platform.getAppInfo();
    } on Object catch (e) {
      BooBoardLog.w('Emoji', 'app info unavailable', e.runtimeType);
      return false;
    }
    final key = '${app.sdkInt}|${app.versionName}';
    if (store.glyphKey == key) return true;
    final guaranteed = guaranteedVersion(app.sdkInt);
    final candidates = <String>[];
    for (final item in data.items) {
      if (item.version <= guaranteed) continue;
      candidates.add(item.text);
      final tones = item.tones;
      if (tones == null) continue;
      for (final t in tones) {
        if (t != null) candidates.add(t);
      }
    }
    final hidden = <String>{};
    final sw = Stopwatch()..start();
    try {
      for (var start = 0; start < candidates.length; start += batchSize) {
        final end = start + batchSize < candidates.length ? start + batchSize : candidates.length;
        final batch = candidates.sublist(start, end);
        final drawable = await platform.hasGlyphs(batch);
        for (var i = 0; i < batch.length; i++) {
          if (!drawable[i]) hidden.add(batch[i]);
        }
      }
    } on Object catch (e) {
      BooBoardLog.w('Emoji', 'glyph check failed', e.runtimeType);
      return false;
    }
    store.setHidden(key, hidden);
    BooBoardLog.d(
      'Emoji',
      'glyph check: ${candidates.length} checked, ${hidden.length} hidden in ${sw.elapsedMilliseconds} ms',
    );
    return true;
  }
}
