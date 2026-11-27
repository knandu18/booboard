// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-B. Japanese typing options (route BooBoardRoutes.japanese). Writes the `japanese`
// settings section (flick only, half-width space) and the default Japanese layout
// (`languages.layouts['ja']`), shows the dictionary pack status, and clears the learned words.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../bridge/messages.g.dart';
import '../../core/data_sections.dart';
import '../../engine/lang/japanese/japanese_learning.dart';
import '../../packs/installed_packs.dart';
import '../../settings/booboard_settings.dart';
import '../app_services.dart';
import '../common/settings_widgets.dart';
import '../routes.dart';
import '../l10n.dart';
import '../shell/settings_actions.dart';

class JapaneseScreen extends StatefulWidget {
  const JapaneseScreen({super.key});

  @override
  State<JapaneseScreen> createState() => _JapaneseScreenState();
}

class _JapaneseScreenState extends State<JapaneseScreen> {
  Future<List<PackInfoMessage>>? _packs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _packs ??= _loadPacks(AppScope.of(context));
  }

  /// The installed Japanese dictionary packs. A failed read shows none rather than an error.
  static Future<List<PackInfoMessage>> _loadPacks(AppServices services) async {
    try {
      return await InstalledPacks(services.platform).dictionariesFor('ja');
    } on Object {
      return <PackInfoMessage>[];
    }
  }

  @override
  Widget build(BuildContext context) => LiveSettings(
    builder: (context, settings) {
      final j = settings.japanese;
      final layout = settings.languages.layouts['ja'] ?? 'kana12_ja';
      return SettingsPage(
        title: context.l10n.japaneseTitle,
        children: [
          SettingsPanel(
            title: context.l10n.japaneseLayout,
            child: SettingsChoiceChips<String>(
              options: [
                ChoiceOption('kana12_ja', context.l10n.japaneseLayout12),
                ChoiceOption('romaji_ja', context.l10n.japaneseLayoutRomaji),
              ],
              selected: layout,
              onSelected: (id) => writeSettings(
                context,
                SettingsSection.languages,
                (s) => s.copyWith(languages: s.languages.copyWith(layouts: {...s.languages.layouts, 'ja': id})),
              ),
            ),
          ),
          SettingsGroup(
            title: context.l10n.japaneseTyping,
            children: [
              SettingsSwitchTile(
                icon: Icons.touch_app_outlined,
                title: context.l10n.japaneseFlickOnly,
                subtitle: context.l10n.japaneseFlickOnlyBody,
                value: j.flickOnly,
                onChanged: (on) => writeSettings(
                  context,
                  SettingsSection.japanese,
                  (s) => s.copyWith(japanese: s.japanese.copyWith(flickOnly: on)),
                ),
              ),
              SettingsSwitchTile(
                icon: Icons.space_bar_outlined,
                title: context.l10n.japaneseHalfWidth,
                subtitle: context.l10n.japaneseHalfWidthBody,
                value: j.halfWidthSpace,
                onChanged: (on) => writeSettings(
                  context,
                  SettingsSection.japanese,
                  (s) => s.copyWith(japanese: s.japanese.copyWith(halfWidthSpace: on)),
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: context.l10n.cjkDictionary,
            children: [
              FutureBuilder<List<PackInfoMessage>>(
                future: _packs,
                builder: (context, snap) {
                  final packs = snap.data;
                  final installed = packs != null && packs.isNotEmpty;
                  return SettingsTile(
                    icon: Icons.inventory_2_outlined,
                    title: context.l10n.japaneseDictPack,
                    subtitle: !snap.hasData
                        ? context.l10n.japaneseChecking
                        : installed
                        ? context.l10n.japaneseInstalled(packs.first.name)
                        : context.l10n.japaneseNotInstalled,
                    onTap: () => unawaited(Navigator.of(context).pushNamed(BooBoardRoutes.packs)),
                  );
                },
              ),
              SettingsTile(
                icon: Icons.delete_outline,
                title: context.l10n.japaneseClearWords,
                subtitle: context.l10n.japaneseClearWordsBody,
                onTap: () => unawaited(_clearLearned(context)),
              ),
            ],
          ),
        ],
      );
    },
  );

  Future<void> _clearLearned(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.japaneseClearTitle),
        content: Text(context.l10n.japaneseClearBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.cjkClear),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final services = AppScope.of(context);
    await services.secureStore.delete(JapaneseLearning.blobName);
    await services.notifyDataChanged(const [DataSections.learned]);
  }
}
