// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A. Typing: corrections, suggestions, keys, and swipe. Swipe settings live here
// because they change how typing feels; they write the `swipe` section.
import 'package:material_ui/material_ui.dart';

import '../../settings/booboard_settings.dart';
import '../common/settings_widgets.dart';
import '../shell/settings_actions.dart';

import 'package:booboard/src/app/l10n.dart';

class TypingScreen extends StatelessWidget {
  const TypingScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveSettings(
    builder: (context, settings) {
      final t = settings.typing;
      final w = settings.swipe;

      void typing(BooBoardSettings Function(BooBoardSettings s, TypingSettings t) change) =>
          writeSettings(context, SettingsSection.typing, (s) => change(s, s.typing));
      void swipe(BooBoardSettings Function(BooBoardSettings s, SwipeSettings w) change) =>
          writeSettings(context, SettingsSection.swipe, (s) => change(s, s.swipe));

      return SettingsPage(
        title: context.l10n.settingsTyping,
        children: [
          SettingsGroup(
            title: context.l10n.typingCorrections,
            children: [
              SettingsSwitchTile(
                icon: Icons.spellcheck,
                title: context.l10n.typingAutocorrect,
                subtitle: context.l10n.typingAutocorrectBody,
                value: t.autoCorrect,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(autoCorrect: v))),
              ),
              SettingsSwitchTile(
                icon: Icons.text_fields,
                title: context.l10n.typingAutoCapitalise,
                subtitle: context.l10n.typingAutoCapitaliseBody,
                value: t.autoCapitalize,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(autoCapitalize: v))),
              ),
              SettingsSwitchTile(
                icon: Icons.more_horiz,
                title: context.l10n.typingDoubleSpace,
                subtitle: context.l10n.typingDoubleSpaceBody,
                value: t.doubleSpacePeriod,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(doubleSpacePeriod: v))),
              ),
              SettingsSwitchTile(
                icon: Icons.format_quote_outlined,
                title: context.l10n.typingSmartPunctuation,
                subtitle: context.l10n.typingSmartPunctuationBody,
                value: t.smartPunctuation,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(smartPunctuation: v))),
              ),
            ],
          ),
          SettingsGroup(
            title: context.l10n.typingSuggestions,
            children: [
              SettingsSwitchTile(
                icon: Icons.lightbulb_outline,
                title: context.l10n.typingSuggestions,
                subtitle: context.l10n.typingSuggestionsBody,
                value: t.showSuggestions,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(showSuggestions: v))),
              ),
              SettingsSwitchTile(
                icon: Icons.arrow_forward,
                title: context.l10n.typingNextWord,
                subtitle: context.l10n.typingNextWordBody,
                value: t.nextWordPrediction,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(nextWordPrediction: v))),
              ),
              SettingsSwitchTile(
                icon: Icons.emoji_emotions_outlined,
                title: context.l10n.emojiSuggestions,
                subtitle: context.l10n.typingEmojiBody,
                value: t.emojiSuggestions,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(emojiSuggestions: v))),
              ),
              SettingsSwitchTile(
                icon: Icons.block,
                title: context.l10n.typingHideOffensive,
                subtitle: context.l10n.typingHideOffensiveBody,
                value: t.blockOffensiveWords,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(blockOffensiveWords: v))),
              ),
            ],
          ),
          SettingsGroup(
            title: context.l10n.typingKeys,
            children: [
              SettingsSwitchTile(
                icon: Icons.bubble_chart_outlined,
                title: context.l10n.typingKeyPopups,
                subtitle: context.l10n.typingKeyPopupsBody,
                value: t.keyPopups,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(keyPopups: v))),
              ),
              SettingsSliderTile(
                icon: Icons.timer_outlined,
                title: context.l10n.typingLongPressDelay,
                value: t.longPressDelayMs.toDouble(),
                min: 150,
                max: 1000,
                divisions: 17,
                valueLabel: (v) => context.l10n.milliseconds(v.round()),
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(longPressDelayMs: v.round()))),
              ),
              SettingsSwitchTile(
                icon: Icons.pin_outlined,
                title: context.l10n.typingNumberRow,
                subtitle: context.l10n.typingNumberRowBody,
                value: t.numberRow,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(numberRow: v))),
              ),
              SettingsSwitchTile(
                icon: Icons.label_outline,
                title: context.l10n.typingHintLabels,
                subtitle: context.l10n.typingHintLabelsBody,
                value: t.hintLabels,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(hintLabels: v))),
              ),
              SettingsSwitchTile(
                icon: Icons.text_format,
                title: context.l10n.typingLowercaseLabels,
                subtitle: context.l10n.typingLowercaseLabelsBody,
                value: t.lowercaseLabels,
                onChanged: (v) => typing((s, t) => s.copyWith(typing: t.copyWith(lowercaseLabels: v))),
              ),
            ],
          ),
          SettingsGroup(
            title: context.l10n.typingSwipe,
            children: [
              SettingsSwitchTile(
                icon: Icons.gesture,
                title: context.l10n.typingSwipeTyping,
                subtitle: context.l10n.typingSwipeTypingBody,
                value: w.enabled,
                onChanged: (v) => swipe((s, w) => s.copyWith(swipe: w.copyWith(enabled: v))),
              ),
              SettingsSwitchTile(
                icon: Icons.timeline,
                title: context.l10n.typingShowTrail,
                value: w.showTrail,
                onChanged: w.enabled ? (v) => swipe((s, w) => s.copyWith(swipe: w.copyWith(showTrail: v))) : null,
              ),
              SettingsSliderTile(
                icon: Icons.line_weight,
                title: context.l10n.typingTrailWidth,
                value: w.trailWidth,
                min: 2,
                max: 16,
                divisions: 14,
                valueLabel: (v) => context.l10n.dpValue(v.round()),
                onChanged: (v) => swipe((s, w) => s.copyWith(swipe: w.copyWith(trailWidth: v))),
              ),
              SettingsSliderTile(
                icon: Icons.blur_on,
                title: context.l10n.typingTrailFade,
                value: w.trailFadeMs.toDouble(),
                min: 0,
                max: 2000,
                divisions: 20,
                valueLabel: (v) => context.l10n.milliseconds(v.round()),
                onChanged: (v) => swipe((s, w) => s.copyWith(swipe: w.copyWith(trailFadeMs: v.round()))),
              ),
              SettingsSwitchTile(
                icon: Icons.visibility_outlined,
                title: context.l10n.typingLivePreview,
                subtitle: context.l10n.typingLivePreviewBody,
                value: w.livePreview,
                onChanged: w.enabled ? (v) => swipe((s, w) => s.copyWith(swipe: w.copyWith(livePreview: v))) : null,
              ),
              SettingsSwitchTile(
                icon: Icons.space_bar,
                title: context.l10n.typingSpaceMovesCursor,
                subtitle: context.l10n.typingSpaceMovesCursorBody,
                value: w.spaceCursorControl,
                onChanged: w.enabled
                    ? (v) => swipe((s, w) => s.copyWith(swipe: w.copyWith(spaceCursorControl: v)))
                    : null,
              ),
              SettingsSwitchTile(
                icon: Icons.backspace_outlined,
                title: context.l10n.typingSwipeBackspace,
                subtitle: context.l10n.typingSwipeBackspaceBody,
                value: w.backspaceSwipeDelete,
                onChanged: w.enabled
                    ? (v) => swipe((s, w) => s.copyWith(swipe: w.copyWith(backspaceSwipeDelete: v)))
                    : null,
              ),
            ],
          ),
        ],
      );
    },
  );
}
