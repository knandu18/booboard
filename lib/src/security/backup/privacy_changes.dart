// SPDX-License-Identifier: GPL-3.0-or-later
//
// Decision D2 (SEC-17): restoring the settings section replaces the privacy settings too, so a backup could
// silently turn protections off. This lists exactly which privacy settings a restore would change, so the
// screen can name them and ask first. Pure data: no UI, no I/O.
import '../../settings/sections/privacy_settings.dart';

/// The privacy settings a restore can change.
enum PrivacySetting { learning, incognito, incognitoApps, hideFromScreenshots, appLock }

/// One privacy setting whose value would change. [from] and [to] are a bool, or an int (the number of apps)
/// for [PrivacySetting.incognitoApps].
class PrivacyChange {
  const PrivacyChange(this.setting, this.from, this.to);

  final PrivacySetting setting;
  final Object from;
  final Object to;

  @override
  String toString() => 'PrivacyChange($setting: $from -> $to)';
}

/// What applying [incoming] over [current] changes among the privacy settings, in a fixed order. Empty when
/// nothing changes.
List<PrivacyChange> privacyChanges(PrivacySettings current, PrivacySettings incoming) {
  final sameApps =
      current.incognitoApps.length == incoming.incognitoApps.length &&
      current.incognitoApps.toSet().containsAll(incoming.incognitoApps);
  return [
    if (current.learning != incoming.learning)
      PrivacyChange(PrivacySetting.learning, current.learning, incoming.learning),
    if (current.incognito != incoming.incognito)
      PrivacyChange(PrivacySetting.incognito, current.incognito, incoming.incognito),
    if (!sameApps)
      PrivacyChange(PrivacySetting.incognitoApps, current.incognitoApps.length, incoming.incognitoApps.length),
    if (current.hideFromScreenshots != incoming.hideFromScreenshots)
      PrivacyChange(PrivacySetting.hideFromScreenshots, current.hideFromScreenshots, incoming.hideFromScreenshots),
    if (current.appLock != incoming.appLock) PrivacyChange(PrivacySetting.appLock, current.appLock, incoming.appLock),
  ];
}
