// SPDX-License-Identifier: GPL-3.0-or-later
//
// D2 / SEC-17: which privacy settings a restore would change.
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/security/backup/privacy_changes.dart';
import 'package:booboard/src/settings/sections/privacy_settings.dart';

void main() {
  test('identical privacy settings change nothing', () {
    expect(privacyChanges(const PrivacySettings(), const PrivacySettings()), isEmpty);
  });

  test('a backup that turns protections off names each one', () {
    const current = PrivacySettings(appLock: true, hideFromScreenshots: true, incognitoApps: ['bank', 'mail']);
    const incoming = PrivacySettings();
    final changes = privacyChanges(current, incoming);
    expect(changes.map((c) => c.setting), [
      PrivacySetting.incognitoApps,
      PrivacySetting.hideFromScreenshots,
      PrivacySetting.appLock,
    ]);
    expect(changes.first.from, 2);
    expect(changes.first.to, 0);
    expect(changes.last.from, true);
    expect(changes.last.to, false);
  });

  test('the same incognito apps in another order are not a change', () {
    const a = PrivacySettings(incognitoApps: ['bank', 'mail']);
    const b = PrivacySettings(incognitoApps: ['mail', 'bank']);
    expect(privacyChanges(a, b), isEmpty);
  });

  test('swapping one incognito app is a change even when the count stays the same', () {
    const a = PrivacySettings(incognitoApps: ['bank']);
    const b = PrivacySettings(incognitoApps: ['mail']);
    final changes = privacyChanges(a, b);
    expect(changes.single.setting, PrivacySetting.incognitoApps);
    expect(changes.single.from, 1);
    expect(changes.single.to, 1);
  });

  test('learning and incognito are reported with their values', () {
    final changes = privacyChanges(const PrivacySettings(), const PrivacySettings(learning: false, incognito: true));
    expect(changes.map((c) => c.setting), [PrivacySetting.learning, PrivacySetting.incognito]);
    expect(changes.first.from, true);
    expect(changes.first.to, false);
  });
}
