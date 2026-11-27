// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A, Wave 3-A. Languages: the enabled languages (drag to reorder, the first is the
// default; a layout per language; remove), the languages still available, multilingual typing and
// native digits. Writes the `languages` section.
import 'package:material_ui/material_ui.dart';

import '../../engine/contracts.dart' show LanguageId;
import '../../engine/lang/registry.dart';
import '../../settings/booboard_settings.dart';
import '../common/settings_widgets.dart';
import '../routes.dart';
import '../shell/language_catalog.dart';
import '../shell/settings_actions.dart';

import 'package:booboard/src/app/l10n.dart';

class LanguagesScreen extends StatelessWidget {
  const LanguagesScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveSettings(
    builder: (context, settings) {
      final l = settings.languages;
      final enabled = [for (final id in l.enabled) languageInfo(id)];
      final available = [
        for (final info in selectableLanguages)
          if (!l.enabled.contains(info.id)) info,
      ];
      final anyDigits = enabled.any((info) => info.nativeDigits != null);
      return SettingsPage(
        title: context.l10n.settingsLanguages,
        children: [
          SettingsPanel(
            title: context.l10n.languagesEnabledHeader,
            child: _EnabledList(settings: l),
          ),
          if (enabled.length > 1)
            SettingsPanel(
              title: context.l10n.languagesActive,
              child: SettingsChoiceChips<String>(
                options: [for (final info in enabled) ChoiceOption(info.id, info.nativeName)],
                selected: l.active,
                onSelected: (id) => _write(context, (x) => x.copyWith(active: id)),
              ),
            ),
          SettingsGroup(
            title: context.l10n.languagesAdd,
            children: [
              for (final info in available)
                SettingsTile(
                  icon: Icons.add,
                  title: info.nativeName,
                  subtitle: info.englishName,
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () => _write(
                    context,
                    (x) => x.copyWith(enabled: [...x.enabled, info.id]),
                    active: _activeAfterAdd(l, info.id),
                  ),
                ),
              if (available.isEmpty)
                SettingsTile(
                  icon: Icons.check_circle_outline,
                  title: context.l10n.languagesAllEnabled,
                  subtitle: context.l10n.languagesAllEnabledBody,
                ),
            ],
          ),
          SettingsGroup(
            children: [
              SettingsSwitchTile(
                icon: Icons.layers_outlined,
                title: context.l10n.languagesMultilingual,
                subtitle: context.l10n.languagesMultilingualBody,
                value: l.multilingual,
                onChanged: (v) => _write(context, (x) => x.copyWith(multilingual: v)),
              ),
              if (anyDigits)
                SettingsSwitchTile(
                  icon: Icons.pin_outlined,
                  title: context.l10n.languagesNativeDigits,
                  subtitle: context.l10n.languagesNativeDigitsBody,
                  value: l.nativeDigits,
                  onChanged: (v) => _write(context, (x) => x.copyWith(nativeDigits: v)),
                ),
            ],
          ),
          // Wave 4: options of the Chinese and Japanese input methods.
          if (l.enabled.contains('zh') || l.enabled.contains('ja'))
            SettingsGroup(
              title: context.l10n.languagesOptions,
              children: [
                if (l.enabled.contains('zh'))
                  SettingsTile(
                    icon: Icons.translate,
                    title: '中文 (Chinese)',
                    subtitle: context.l10n.languagesZhSubtitle,
                    onTap: () => Navigator.of(context).pushNamed(BooBoardRoutes.chinese),
                  ),
                if (l.enabled.contains('ja'))
                  SettingsTile(
                    icon: Icons.translate,
                    title: '日本語 (Japanese)',
                    subtitle: context.l10n.languagesJaSubtitle,
                    onTap: () => Navigator.of(context).pushNamed(BooBoardRoutes.japanese),
                  ),
              ],
            ),
        ],
      );
    },
  );

  /// Writes the languages section. The first enabled language is the default; when the active one
  /// is no longer enabled, the first one becomes active.
  static void _write(
    BuildContext context,
    LanguageSettings Function(LanguageSettings current) change, {
    String? active,
  }) {
    writeSettings(context, SettingsSection.languages, (s) {
      final next = change(s.languages);
      final enabled = next.enabled.isEmpty ? const ['en'] : next.enabled;
      final chosen = active ?? next.active;
      return s.copyWith(
        languages: next.copyWith(enabled: enabled, active: enabled.contains(chosen) ? chosen : enabled.first),
      );
    });
  }

  /// A newly added language becomes the active one only when it is the first enabled language.
  static String? _activeAfterAdd(LanguageSettings l, String added) => l.enabled.isEmpty ? added : null;
}

/// Reorderable list of the enabled languages with their layout and a remove button.
class _EnabledList extends StatelessWidget {
  const _EnabledList({required this.settings});

  final LanguageSettings settings;

  @override
  Widget build(BuildContext context) {
    final ids = settings.enabled;
    final scheme = Theme.of(context).colorScheme;
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) {
        final list = [...ids];
        final moved = list.removeAt(oldIndex);
        list.insert(newIndex, moved);
        LanguagesScreen._write(context, (x) => x.copyWith(enabled: list));
      },
      children: [
        for (var i = 0; i < ids.length; i++)
          _EnabledRow(
            key: ValueKey(ids[i]),
            index: i,
            id: ids[i],
            settings: settings,
            canRemove: ids.length > 1,
            color: scheme.surfaceContainer,
          ),
      ],
    );
  }
}

class _EnabledRow extends StatelessWidget {
  const _EnabledRow({
    super.key,
    required this.index,
    required this.id,
    required this.settings,
    required this.canRemove,
    required this.color,
  });

  final int index;
  final LanguageId id;
  final LanguageSettings settings;
  final bool canRemove;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final info = languageInfo(id);
    final layout = layoutChoiceFor(settings, id);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  label: context.l10n.languagesReorderLabel(info.englishName),
                  child: const SizedBox(width: 48, height: 64, child: Icon(Icons.drag_indicator)),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.nativeName, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      index == 0 ? context.l10n.languageDefaultLabel(info.englishName) : info.englishName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (info.layouts.length > 1)
                PopupMenuButton<String>(
                  tooltip: context.l10n.languageLayoutTooltip(info.englishName),
                  initialValue: layout.id,
                  onSelected: (layoutId) =>
                      LanguagesScreen._write(context, (x) => x.copyWith(layouts: {...x.layouts, id: layoutId})),
                  itemBuilder: (context) => [
                    for (final choice in info.layouts) PopupMenuItem(value: choice.id, child: Text(choice.name)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(layout.name, style: Theme.of(context).textTheme.labelLarge),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(layout.name, style: Theme.of(context).textTheme.labelLarge),
                ),
              IconButton(
                tooltip: context.l10n.languageRemoveTooltip(info.englishName),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: canRemove
                    ? () => LanguagesScreen._write(context, (x) => x.copyWith(enabled: [...x.enabled]..remove(id)))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
