// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A. Chinese typing options (route BooBoardRoutes.chinese): Traditional output, fuzzy
// pinyin, the dictionary pack status and clearing the learned phrases. Writes the `chinese` section.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../bridge/messages.g.dart';
import '../../core/data_sections.dart';
import '../../engine/lang/chinese/learned_phrases.dart';
import '../../packs/installed_packs.dart';
import '../../settings/booboard_settings.dart';
import '../app_services.dart';
import '../common/settings_widgets.dart';
import '../routes.dart';
import '../l10n.dart';
import '../shell/settings_actions.dart';

class ChineseScreen extends StatelessWidget {
  const ChineseScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveSettings(
    builder: (context, settings) {
      final c = settings.chinese;
      return SettingsPage(
        title: context.l10n.chineseTitle,
        children: [
          SettingsGroup(
            children: [
              SettingsSwitchTile(
                icon: Icons.translate,
                title: context.l10n.chineseTraditional,
                subtitle: context.l10n.chineseTraditionalBody,
                value: c.traditional,
                onChanged: (on) => writeSettings(
                  context,
                  SettingsSection.chinese,
                  (s) => s.copyWith(chinese: s.chinese.copyWith(traditional: on)),
                ),
              ),
              SettingsSwitchTile(
                icon: Icons.swap_horiz,
                title: context.l10n.chineseFuzzy,
                subtitle: context.l10n.chineseFuzzyBody,
                value: c.fuzzyPinyin,
                onChanged: (on) => writeSettings(
                  context,
                  SettingsSection.chinese,
                  (s) => s.copyWith(chinese: s.chinese.copyWith(fuzzyPinyin: on)),
                ),
              ),
            ],
          ),
          SettingsGroup(title: context.l10n.cjkDictionary, children: const [_PackTile()]),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.delete_outline,
                title: context.l10n.chineseClearPhrases,
                subtitle: context.l10n.chineseClearPhrasesBody,
                onTap: () => unawaited(_confirmClear(context)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Text(context.l10n.chineseFooter, textAlign: TextAlign.center),
          ),
        ],
      );
    },
  );

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.chineseClearTitle),
        content: Text(context.l10n.chineseClearBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(context.l10n.cjkClear)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final services = AppScope.of(context);
    try {
      await services.secureStore.delete(learnedZhBlobName);
      await services.notifyDataChanged(const [DataSections.learned]);
    } on Object {
      // The blob may already be gone; the list is empty either way.
    }
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(context.l10n.chinesePhrasesCleared)));
    }
  }
}

/// The Chinese dictionary pack: its name and size, or a link to install it.
class _PackTile extends StatefulWidget {
  const _PackTile();

  @override
  State<_PackTile> createState() => _PackTileState();
}

class _PackTileState extends State<_PackTile> {
  Future<List<PackInfoMessage>>? _packs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _packs ??= _load(AppScope.of(context));
  }

  static Future<List<PackInfoMessage>> _load(AppServices services) async {
    try {
      return await InstalledPacks(services.platform).dictionariesFor('zh');
    } on Object {
      return <PackInfoMessage>[];
    }
  }

  static String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PackInfoMessage>>(
    future: _packs,
    builder: (context, snap) {
      final loading = snap.connectionState != ConnectionState.done;
      final packs = snap.data ?? const <PackInfoMessage>[];
      void open() => unawaited(Navigator.of(context).pushNamed(BooBoardRoutes.packs));
      if (loading) {
        return SettingsTile(icon: Icons.inventory_2_outlined, title: context.l10n.chineseLooking);
      }
      if (packs.isEmpty) {
        return SettingsTile(
          icon: Icons.inventory_2_outlined,
          title: context.l10n.chineseDictName,
          subtitle: context.l10n.chinesePackMissing,
          onTap: open,
        );
      }
      final pack = packs.first;
      return SettingsTile(
        icon: Icons.inventory_2_outlined,
        title: pack.name,
        subtitle: context.l10n.chinesePackInstalled(pack.license),
        trailing: Text(_mb(pack.sizeBytes)),
        onTap: open,
      );
    },
  );
}
