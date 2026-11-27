// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:meta/meta.dart';

import '../json_util.dart';

@immutable
class PrivacySettings {
  const PrivacySettings({
    this.learning = true,
    this.incognito = false,
    this.incognitoApps = const [],
    this.hideFromScreenshots = false,
    this.appLock = false,
    this.appLockTimeoutSeconds = 60,
    this.personalShortcuts = true,
  });

  factory PrivacySettings.fromJson(Json j) => PrivacySettings(
    learning: jBool(j, 'learning', true),
    incognito: jBool(j, 'incognito', false),
    incognitoApps: jStrings(j, 'incognitoApps', const []),
    hideFromScreenshots: jBool(j, 'hideFromScreenshots', false),
    appLock: jBool(j, 'appLock', false),
    appLockTimeoutSeconds: jInt(j, 'appLockTimeoutSeconds', 60).clamp(0, 3600),
    personalShortcuts: jBool(j, 'personalShortcuts', true),
  );

  /// Learn new words and phrases (always off in password/incognito fields).
  final bool learning;

  /// Manual incognito toggle.
  final bool incognito;

  /// Packages where BooBoard is always incognito (e.g. banking apps).
  final List<String> incognitoApps;

  /// FLAG_SECURE on the keyboard window in every app (always on in password fields).
  final bool hideFromScreenshots;
  final bool appLock;
  final int appLockTimeoutSeconds;

  /// Offer the personal shortcuts ("omw" -> "on my way") in the suggestion strip.
  final bool personalShortcuts;

  Json toJson() => {
    'learning': learning,
    'incognito': incognito,
    'incognitoApps': incognitoApps,
    'hideFromScreenshots': hideFromScreenshots,
    'appLock': appLock,
    'appLockTimeoutSeconds': appLockTimeoutSeconds,
    'personalShortcuts': personalShortcuts,
  };

  PrivacySettings copyWith({
    bool? learning,
    bool? incognito,
    List<String>? incognitoApps,
    bool? hideFromScreenshots,
    bool? appLock,
    int? appLockTimeoutSeconds,
    bool? personalShortcuts,
  }) => PrivacySettings(
    learning: learning ?? this.learning,
    incognito: incognito ?? this.incognito,
    incognitoApps: incognitoApps ?? this.incognitoApps,
    hideFromScreenshots: hideFromScreenshots ?? this.hideFromScreenshots,
    appLock: appLock ?? this.appLock,
    appLockTimeoutSeconds: appLockTimeoutSeconds ?? this.appLockTimeoutSeconds,
    personalShortcuts: personalShortcuts ?? this.personalShortcuts,
  );
}
