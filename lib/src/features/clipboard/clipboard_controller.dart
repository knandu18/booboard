// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Watches the clipboard (Kotlin's clipboard watcher through events.clipboard), records
// text clips into the history and shows the "recent copy" chip for 60 s.
//
// Rules (from the plan, "Privacy and security"):
//   * Recorded only when clipboard.history is on, the keyboard is not incognito and the clip is not
//     sensitive (ClipDescription.EXTRA_IS_SENSITIVE).
//   * A sensitive clip is never stored and never shown. Its chip reads "Paste ••••", and tapping it reads
//     the clipboard again at that moment.
//   * The chip is in memory only. It is not shown while incognito, even for ordinary text.
import 'dart:async';

import 'package:characters/characters.dart';

import '../../bridge/messages.g.dart';
import '../../keyboard/keyboard_session.dart';
import '../../keyboard/panels/keyboard_panel.dart';
import 'clipboard_store.dart';

/// Chip id shared by the plain and the masked recent-copy chip, so a new copy replaces the old one.
const String recentChipId = 'clipboard.recent';

/// Chips show for this long.
const Duration recentChipTtl = Duration(seconds: 60);

/// Longest preview in the chip label, in characters.
const int previewLength = 20;

class ClipboardController {
  ClipboardController({required this.session, required this.store});

  final KeyboardSession session;
  final ClipboardStore store;

  /// Called for every clipboard change (events.clipboard).
  void onClip(ClipMessage clip) {
    final text = clip.text;
    if (text.isEmpty) return;
    final settings = session.services.settings.value.clipboard;
    if (clip.isSensitive) {
      if (settings.recentChip) _showMasked();
      return;
    }
    final incognito = session.input.isIncognito;
    if (settings.history && !incognito) unawaited(_record(text));
    if (settings.recentChip && !incognito) _showChip(text);
  }

  Future<void> _record(String text) async {
    try {
      await store.load();
      store.add(text);
    } on Object {
      // The history is best effort: a failed read or write never blocks typing.
    }
  }

  void _showChip(String text) {
    session.showChip(
      StripChip(
        id: recentChipId,
        label: 'Paste "${previewOf(text)}"',
        semanticLabel: 'Paste recent copy',
        priority: 5,
        expiresAfter: recentChipTtl,
        onTap: () {
          session.removeChip(recentChipId);
          session.input.insertText(text);
        },
      ),
    );
  }

  void _showMasked() {
    session.showChip(
      StripChip(
        id: recentChipId,
        label: 'Paste ••••',
        semanticLabel: 'Paste sensitive copy',
        priority: 5,
        expiresAfter: recentChipTtl,
        onTap: () => unawaited(_pasteCurrent()),
      ),
    );
  }

  /// Reads the clipboard again at this moment, for a masked chip.
  Future<void> _pasteCurrent() async {
    session.removeChip(recentChipId);
    try {
      final clip = await session.services.host.getPrimaryClip();
      final text = clip?.text ?? '';
      if (text.isNotEmpty) session.input.insertText(text);
    } on Object {
      // Nothing to paste: the clipboard was cleared or the platform refused.
    }
  }

  /// A short, single-line view of [text] for a chip: newlines become ⏎, and the rest is cut at 20 characters.
  static String previewOf(String text) {
    final flat = text.replaceAll(RegExp(r'\r\n?|\n'), '⏎');
    final chars = flat.characters;
    if (chars.length <= previewLength) return flat;
    return '${chars.take(previewLength).string}…';
  }
}
