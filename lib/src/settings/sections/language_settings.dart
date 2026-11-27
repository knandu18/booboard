// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:meta/meta.dart';

import '../json_util.dart';

@immutable
class LanguageSettings {
  const LanguageSettings({
    this.enabled = const ['en'],
    this.active = 'en',
    this.layouts = const {'en': 'qwerty'},
    this.multilingual = true,
    this.onboardingDone = false,
    this.nativeDigits = false,
    this.hinglishOutput = false,
  });

  factory LanguageSettings.fromJson(Json j) {
    final enabled = jStrings(j, 'enabled', const ['en']);
    final safeEnabled = enabled.isEmpty ? const ['en'] : enabled;
    final active = jString(j, 'active', safeEnabled.first);
    return LanguageSettings(
      enabled: safeEnabled,
      active: safeEnabled.contains(active) ? active : safeEnabled.first,
      layouts: jStringMap(j, 'layouts', const {'en': 'qwerty'}),
      multilingual: jBool(j, 'multilingual', true),
      onboardingDone: jBool(j, 'onboardingDone', false),
      nativeDigits: jBool(j, 'nativeDigits', false),
      hinglishOutput: jBool(j, 'hinglishOutput', false),
    );
  }

  /// Enabled languages in the user's order.
  final List<String> enabled;

  /// Language whose layout is showing.
  final String active;

  /// Chosen layout id per language (e.g. de -> qwertz).
  final Map<String, String> layouts;

  /// Blend up to 3 enabled languages that share the active layout's script.
  final bool multilingual;

  /// Set when the settings app's first-run setup reached its last step.
  final bool onboardingDone;

  /// Number row, symbols and number pad type the active language's own digits (०१२, ٠١٢) when it
  /// has them (Wave 3).
  final bool nativeDigits;

  /// Indic "English letters" typing commits the Latin text as typed instead of the native script
  /// (Hinglish), with the native word offered in the strip (Wave 3-B).
  final bool hinglishOutput;

  Json toJson() => {
    'enabled': enabled,
    'active': active,
    'layouts': layouts,
    'multilingual': multilingual,
    'onboardingDone': onboardingDone,
    'nativeDigits': nativeDigits,
    'hinglishOutput': hinglishOutput,
  };

  LanguageSettings copyWith({
    List<String>? enabled,
    String? active,
    Map<String, String>? layouts,
    bool? multilingual,
    bool? onboardingDone,
    bool? nativeDigits,
    bool? hinglishOutput,
  }) => LanguageSettings(
    enabled: enabled ?? this.enabled,
    active: active ?? this.active,
    layouts: layouts ?? this.layouts,
    multilingual: multilingual ?? this.multilingual,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    nativeDigits: nativeDigits ?? this.nativeDigits,
    hinglishOutput: hinglishOutput ?? this.hinglishOutput,
  );
}
