// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/privacy/privacy_format.dart';
import 'package:booboard/src/security/shortcuts_store.dart';

void main() {
  // The helpers take the localisations directly, so the tests look up English without a widget.
  final en = lookupAppLocalizations(const Locale('en'));

  test('counts use thousands separators', () {
    expect(formatCount(0), '0');
    expect(formatCount(999), '999');
    expect(formatCount(1240), '1,240');
    expect(formatCount(1234567), '1,234,567');
  });

  test('byte sizes read in plain units', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(14 * 1024), '14 KB');
    expect(formatBytes(2 * 1024 * 1024 + 400 * 1024), '2.4 MB');
    expect(formatBytes(40 * 1024 * 1024), '40 MB');
  });

  test('stored blobs get friendly names and never show their raw names', () {
    expect(friendlyBlobName('learned_en', en), 'Learned words (English)');
    expect(friendlyBlobName('learned_xx', en), 'Learned words (xx)');
    expect(friendlyBlobName('clipboard', en), 'Clipboard history');
    expect(friendlyBlobName('emoji', en), 'Emoji recents');
    expect(friendlyBlobName('shortcuts', en), 'Personal shortcuts');
    expect(friendlyBlobName('seen_apps', en), 'Apps list');
    expect(friendlyBlobName('mystery', en), 'Other stored data');
  });

  test('time ago reads naturally', () {
    const now = 10000000000;
    expect(timeAgo(now - 5000, nowMillis: now, l10n: en), 'just now');
    expect(timeAgo(now - 60000, nowMillis: now, l10n: en), '1 minute ago');
    expect(timeAgo(now - 3 * 3600000, nowMillis: now, l10n: en), '3 hours ago');
    expect(timeAgo(now - 2 * 86400000, nowMillis: now, l10n: en), '2 days ago');
  });

  test('plural counts agree with the number', () {
    expect(en.countShortcuts(1), '1 shortcut');
    expect(en.countShortcuts(12), '12 shortcuts');
    expect(en.countWords(1240), '1240 words');
    expect(en.countBlockedWords(1), '1 blocked word');
  });

  test('passphrase strength: short is refused, variety and length raise the rating', () {
    expect(PassphraseRules.strength('short'), PassphraseStrength.tooShort);
    expect(PassphraseRules.strength('abcdefgh'), PassphraseStrength.weak);
    expect(PassphraseRules.strength('Correct Horse 9'), PassphraseStrength.good);
    expect(PassphraseRules.strength('Correct-Horse-Battery-9!'), PassphraseStrength.strong);
    expect(PassphraseStrength.strong.fraction, 1);
    expect(PassphraseStrength.tooShort.fraction, 0);
    expect(PassphraseStrength.tooShort.label(en), isNotEmpty);
  });

  test('every refused shortcut has a message', () {
    for (final p in ShortcutProblem.values) {
      expect(shortcutProblemText(p, en), isNotEmpty);
    }
    expect(shortcutProblemText(ShortcutProblem.tooManyShortcuts, en), contains('500'));
  });
}
