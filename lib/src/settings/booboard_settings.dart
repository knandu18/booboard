// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (Wave 0). All user settings. Each section lives in its own file
// (sections/) so feature agents can extend "their" section without conflicts.
// Sensitive data (learned words, clipboard) is NOT stored here: it goes to
// SecureBlobStore.
import 'package:meta/meta.dart';

import 'json_util.dart';
import 'sections/appearance_settings.dart';
import 'sections/chinese_settings.dart';
import 'sections/clipboard_settings.dart';
import 'sections/feedback_settings.dart';
import 'sections/japanese_settings.dart';
import 'sections/language_settings.dart';
import 'sections/mode_settings.dart';
import 'sections/privacy_settings.dart';
import 'sections/swipe_settings.dart';
import 'sections/translate_settings.dart';
import 'sections/typing_settings.dart';
import 'sections/voice_settings.dart';

export 'sections/appearance_settings.dart';
export 'sections/chinese_settings.dart';
export 'sections/clipboard_settings.dart';
export 'sections/feedback_settings.dart';
export 'sections/japanese_settings.dart';
export 'sections/language_settings.dart';
export 'sections/mode_settings.dart';
export 'sections/privacy_settings.dart';
export 'sections/swipe_settings.dart';
export 'sections/translate_settings.dart';
export 'sections/typing_settings.dart';
export 'sections/voice_settings.dart';

/// Section names used in change notifications between engines.
abstract final class SettingsSection {
  static const typing = 'typing';
  static const swipe = 'swipe';
  static const feedback = 'feedback';
  static const appearance = 'appearance';
  static const languages = 'languages';
  static const privacy = 'privacy';
  static const clipboard = 'clipboard';
  static const modes = 'modes';
  static const voice = 'voice';
  static const translate = 'translate';
  static const chinese = 'chinese';
  static const japanese = 'japanese';
  static const all = [
    typing,
    swipe,
    feedback,
    appearance,
    languages,
    privacy,
    clipboard,
    modes,
    voice,
    translate,
    chinese,
    japanese,
  ];
}

@immutable
class BooBoardSettings {
  const BooBoardSettings({
    this.typing = const TypingSettings(),
    this.swipe = const SwipeSettings(),
    this.feedback = const FeedbackSettings(),
    this.appearance = const AppearanceSettings(),
    this.languages = const LanguageSettings(),
    this.privacy = const PrivacySettings(),
    this.clipboard = const ClipboardSettings(),
    this.modes = const ModeSettings(),
    this.voice = const VoiceSettings(),
    this.translate = const TranslateSettings(),
    this.chinese = const ChineseSettings(),
    this.japanese = const JapaneseSettings(),
  });

  factory BooBoardSettings.fromJson(Json j) => BooBoardSettings(
    typing: TypingSettings.fromJson(jObject(j, SettingsSection.typing)),
    swipe: SwipeSettings.fromJson(jObject(j, SettingsSection.swipe)),
    feedback: FeedbackSettings.fromJson(jObject(j, SettingsSection.feedback)),
    appearance: AppearanceSettings.fromJson(jObject(j, SettingsSection.appearance)),
    languages: LanguageSettings.fromJson(jObject(j, SettingsSection.languages)),
    privacy: PrivacySettings.fromJson(jObject(j, SettingsSection.privacy)),
    clipboard: ClipboardSettings.fromJson(jObject(j, SettingsSection.clipboard)),
    modes: ModeSettings.fromJson(jObject(j, SettingsSection.modes)),
    voice: VoiceSettings.fromJson(jObject(j, SettingsSection.voice)),
    translate: TranslateSettings.fromJson(jObject(j, SettingsSection.translate)),
    chinese: ChineseSettings.fromJson(jObject(j, SettingsSection.chinese)),
    japanese: JapaneseSettings.fromJson(jObject(j, SettingsSection.japanese)),
  );

  static const int schemaVersion = 1;

  final TypingSettings typing;
  final SwipeSettings swipe;
  final FeedbackSettings feedback;
  final AppearanceSettings appearance;
  final LanguageSettings languages;
  final PrivacySettings privacy;
  final ClipboardSettings clipboard;
  final ModeSettings modes;
  final VoiceSettings voice;
  final TranslateSettings translate;

  /// Wave 4-A.
  final ChineseSettings chinese;

  /// Wave 4-B.
  final JapaneseSettings japanese;

  Json toJson() => {
    'schemaVersion': schemaVersion,
    SettingsSection.typing: typing.toJson(),
    SettingsSection.swipe: swipe.toJson(),
    SettingsSection.feedback: feedback.toJson(),
    SettingsSection.appearance: appearance.toJson(),
    SettingsSection.languages: languages.toJson(),
    SettingsSection.privacy: privacy.toJson(),
    SettingsSection.clipboard: clipboard.toJson(),
    SettingsSection.modes: modes.toJson(),
    SettingsSection.voice: voice.toJson(),
    SettingsSection.translate: translate.toJson(),
    SettingsSection.chinese: chinese.toJson(),
    SettingsSection.japanese: japanese.toJson(),
  };

  BooBoardSettings copyWith({
    TypingSettings? typing,
    SwipeSettings? swipe,
    FeedbackSettings? feedback,
    AppearanceSettings? appearance,
    LanguageSettings? languages,
    PrivacySettings? privacy,
    ClipboardSettings? clipboard,
    ModeSettings? modes,
    VoiceSettings? voice,
    TranslateSettings? translate,
    ChineseSettings? chinese,
    JapaneseSettings? japanese,
  }) => BooBoardSettings(
    typing: typing ?? this.typing,
    swipe: swipe ?? this.swipe,
    feedback: feedback ?? this.feedback,
    appearance: appearance ?? this.appearance,
    languages: languages ?? this.languages,
    privacy: privacy ?? this.privacy,
    clipboard: clipboard ?? this.clipboard,
    modes: modes ?? this.modes,
    voice: voice ?? this.voice,
    translate: translate ?? this.translate,
    chinese: chinese ?? this.chinese,
    japanese: japanese ?? this.japanese,
  );
}
