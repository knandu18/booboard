// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A. Panels: clipboard history (on/off, how long copies are kept, how many, the
// "recent copy" chip) and emoji suggestions. Writes `clipboard` and `typing` (values only; Wave
// 2-D owns the panels' behaviour).
import 'package:material_ui/material_ui.dart';

import '../../settings/booboard_settings.dart';
import '../common/settings_widgets.dart';
import '../shell/settings_actions.dart';

import 'package:booboard/src/app/l10n.dart';

/// Expiry choices in minutes. The clipboard section clamps to a week.
List<ChoiceOption<int>> _expiryChoices(AppLocalizations l10n) => [
  ChoiceOption(15, l10n.durationMinutes15),
  ChoiceOption(60, l10n.durationHour),
  ChoiceOption(1440, l10n.durationDay),
  ChoiceOption(10080, l10n.durationWeek),
];

class PanelsScreen extends StatelessWidget {
  const PanelsScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveSettings(
    builder: (context, settings) {
      final c = settings.clipboard;
      return SettingsPage(
        title: context.l10n.settingsPanels,
        children: [
          SettingsGroup(
            title: context.l10n.panelsClipboard,
            children: [
              SettingsSwitchTile(
                icon: Icons.content_paste_outlined,
                title: context.l10n.panelsClipboardHistory,
                subtitle: context.l10n.panelsClipboardHistoryBody,
                value: c.history,
                onChanged: (v) => writeSettings(
                  context,
                  SettingsSection.clipboard,
                  (s) => s.copyWith(clipboard: s.clipboard.copyWith(history: v)),
                ),
              ),
              SettingsSwitchTile(
                icon: Icons.push_pin_outlined,
                title: context.l10n.panelsRecentChip,
                subtitle: context.l10n.panelsRecentChipBody,
                value: c.recentChip,
                onChanged: (v) => writeSettings(
                  context,
                  SettingsSection.clipboard,
                  (s) => s.copyWith(clipboard: s.clipboard.copyWith(recentChip: v)),
                ),
              ),
            ],
          ),
          SettingsPanel(
            title: context.l10n.panelsKeepUnpinned,
            child: SettingsChoiceChips<int>(
              options: _expiryChoices(context.l10n),
              selected: _expiryChoices(context.l10n).where((o) => o.value == c.expiryMinutes).firstOrNull?.value,
              onSelected: (minutes) => writeSettings(
                context,
                SettingsSection.clipboard,
                (s) => s.copyWith(clipboard: s.clipboard.copyWith(expiryMinutes: minutes)),
              ),
            ),
          ),
          SettingsGroup(
            children: [
              SettingsSliderTile(
                icon: Icons.format_list_numbered,
                title: context.l10n.panelsClipsToKeep,
                value: c.maxItems.toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                valueLabel: (v) => '${v.round()}',
                onChanged: (v) => writeSettings(
                  context,
                  SettingsSection.clipboard,
                  (s) => s.copyWith(clipboard: s.clipboard.copyWith(maxItems: v.round())),
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: context.l10n.panelsEmoji,
            children: [
              SettingsSwitchTile(
                icon: Icons.emoji_emotions_outlined,
                title: context.l10n.emojiSuggestions,
                subtitle: context.l10n.emojiSuggestionsPanelBody,
                value: settings.typing.emojiSuggestions,
                onChanged: (v) => writeSettings(
                  context,
                  SettingsSection.typing,
                  (s) => s.copyWith(typing: s.typing.copyWith(emojiSuggestions: v)),
                ),
              ),
            ],
          ),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.key_off_outlined,
                title: context.l10n.panelsPasswordsNeverSaved,
                subtitle: context.l10n.panelsSensitiveBody,
              ),
            ],
          ),
        ],
      );
    },
  );
}
