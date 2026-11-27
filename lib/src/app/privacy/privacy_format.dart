// SPDX-License-Identifier: GPL-3.0-or-later
//
// Plain-language helpers for the privacy screens: friendly names for stored blobs, byte sizes,
// counts and the backup passphrase strength. Pure Dart, so they are unit-tested directly. Words
// come from the localisations passed in (AppLocalizations), so no BuildContext is needed.
import '../../core/data_sections.dart';
import '../../engine/lang/registry.dart';
import '../../security/shortcuts_store.dart';

import 'package:booboard/src/app/l10n.dart';

/// The language's name in English (LanguageInfo), or its code when it is not known.
String languageName(String code) => languageInfo(code).englishName;

/// What a stored blob holds, for the privacy center's list. Never shows contents.
String friendlyBlobName(String name, AppLocalizations l10n) {
  if (name == DataBlobs.learnedZhPhrases) return l10n.privacyStoredChinesePhrases;
  if (name == DataBlobs.learnedJaWords) return l10n.privacyStoredJapaneseWords;
  if (name.startsWith(DataBlobs.learnedPrefix)) {
    return l10n.privacyStoredLearned(languageName(name.substring(DataBlobs.learnedPrefix.length)));
  }
  return switch (name) {
    DataBlobs.clipboard => l10n.panelsClipboardHistory,
    DataBlobs.emoji => l10n.privacyStoredEmoji,
    DataBlobs.shortcuts => l10n.privacyPersonalShortcuts,
    DataBlobs.seenApps => l10n.privacyStoredApps,
    _ => l10n.privacyStoredOther,
  };
}

/// "1,240": thousands separators with a comma, for counts shown to the user.
String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Bytes as "512 B", "14 KB" or "2.4 MB". Unit abbreviations are not translated.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
}

/// "just now", "5 minutes ago", "2 days ago", given the milliseconds since the epoch.
String timeAgo(int millis, {required int nowMillis, required AppLocalizations l10n}) {
  final seconds = ((nowMillis - millis) / 1000).round();
  if (seconds < 60) return l10n.timeJustNow;
  final minutes = seconds ~/ 60;
  if (minutes < 60) return l10n.timeMinutesAgo(minutes);
  final hours = minutes ~/ 60;
  if (hours < 24) return l10n.timeHoursAgo(hours);
  return l10n.timeDaysAgo(hours ~/ 24);
}

/// Message for a refused shortcut.
String shortcutProblemText(ShortcutProblem problem, AppLocalizations l10n) => switch (problem) {
  ShortcutProblem.emptyTrigger => l10n.shortcutProblemEmptyTrigger,
  ShortcutProblem.triggerTooLong => l10n.shortcutProblemTriggerTooLong(ShortcutRules.maxTriggerLength),
  ShortcutProblem.triggerCharacters => l10n.shortcutProblemTriggerCharacters,
  ShortcutProblem.emptyExpansion => l10n.shortcutProblemEmptyExpansion,
  ShortcutProblem.expansionTooLong => l10n.shortcutProblemExpansionTooLong(ShortcutRules.maxExpansionLength),
  ShortcutProblem.duplicateTrigger => l10n.shortcutProblemDuplicate,
  ShortcutProblem.tooManyShortcuts => l10n.shortcutProblemTooMany(ShortcutRules.maxShortcuts),
};

enum PassphraseStrength {
  tooShort,
  weak,
  fair,
  good,
  strong;

  /// The word for this strength, in the current language.
  String label(AppLocalizations l10n) => switch (this) {
    PassphraseStrength.tooShort => l10n.strengthTooShort,
    PassphraseStrength.weak => l10n.strengthWeak,
    PassphraseStrength.fair => l10n.strengthFair,
    PassphraseStrength.good => l10n.strengthGood,
    PassphraseStrength.strong => l10n.strengthStrong,
  };

  /// Fraction for a meter, 0 to 1.
  double get fraction => switch (this) {
    PassphraseStrength.tooShort => 0,
    PassphraseStrength.weak => 0.25,
    PassphraseStrength.fair => 0.5,
    PassphraseStrength.good => 0.75,
    PassphraseStrength.strong => 1,
  };
}

abstract final class PassphraseRules {
  static const int minLength = 8;

  /// A simple estimate from length and character variety. It only guides the user: the real
  /// protection is the 600,000-iteration key derivation.
  static PassphraseStrength strength(String passphrase) {
    final length = passphrase.runes.length;
    if (length < minLength) return PassphraseStrength.tooShort;
    final classes = [
      RegExp(r'[a-z]').hasMatch(passphrase),
      RegExp(r'[A-Z]').hasMatch(passphrase),
      RegExp(r'[0-9]').hasMatch(passphrase),
      RegExp(r'[^A-Za-z0-9]').hasMatch(passphrase) || passphrase.runes.any((r) => r > 127),
    ].where((b) => b).length;
    var score = 0;
    if (length >= 12) score++;
    if (length >= 16) score++;
    if (classes >= 3) score++;
    if (classes >= 4 || length >= 24) score++;
    return switch (score) {
      0 => PassphraseStrength.weak,
      1 => PassphraseStrength.fair,
      2 || 3 => PassphraseStrength.good,
      _ => PassphraseStrength.strong,
    };
  }
}
