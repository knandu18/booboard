// SPDX-License-Identifier: GPL-3.0-or-later
//
// Deletes BooBoard's stored data: one category at a time, or everything. Each category says exactly
// what it removes, so the confirmation dialog can list it. Every wipe notifies the keyboard engine,
// which reloads or forgets the deleted data.
//
// "Everything" also destroys the Keystore key (SecureBlobStore.wipeAll), so the next write creates
// a new key.
import '../bridge/messages.g.dart';
import '../core/data_sections.dart';
import '../core/seen_apps.dart';
import '../core/secure_blob_store.dart';
import '../settings/booboard_settings.dart';
import '../settings/settings_store.dart';
import '../theme/presets.dart';
import 'custom_theme_files.dart';
import 'shortcuts_store.dart';

enum WipeCategory {
  learned(
    title: 'Learned words',
    detail: 'Every word BooBoard learned from your typing in every language, plus the words you blocked.',
  ),
  clipboard(title: 'Clipboard history', detail: 'Copied text in the clipboard history, including pinned items.'),
  emoji(title: 'Emoji recents', detail: 'Recently used emoji and the skin tones you picked.'),
  shortcuts(title: 'Personal shortcuts', detail: 'Every shortcut you added, such as "omw".'),
  apps(
    title: 'Apps list',
    detail: 'The app names that fill the always-incognito list. Your incognito choices stay in settings.',
  ),
  themes(title: 'Custom themes', detail: 'Custom theme files and their background images.');

  const WipeCategory({required this.title, required this.detail});

  final String title;
  final String detail;
}

class DataWiper {
  DataWiper({
    required this.store,
    required this.platform,
    required this.seenApps,
    required this.shortcuts,
    required this.settings,
    required this.themes,
    required this.notify,
  });

  final SecureBlobStore store;
  final PlatformHostApi platform;
  final SeenAppsStore seenApps;
  final ShortcutsStore shortcuts;
  final SettingsStore settings;
  final CustomThemeFiles themes;

  /// Tells the keyboard engine which [DataSections] changed (AppServices.notifyDataChanged).
  final Future<void> Function(List<String> sections) notify;

  /// Names of every learned-words blob on the device.
  Future<List<String>> learnedBlobNames() async {
    final blobs = await platform.secureList();
    return [
      for (final b in blobs)
        if (b.name.startsWith(DataBlobs.learnedPrefix)) b.name,
    ];
  }

  Future<void> wipe(Set<WipeCategory> categories) async {
    final sections = <String>[];
    if (categories.contains(WipeCategory.learned)) {
      for (final name in await learnedBlobNames()) {
        await store.delete(name);
      }
      sections.add(DataSections.learned);
    }
    if (categories.contains(WipeCategory.clipboard)) {
      await store.delete(DataBlobs.clipboard);
      sections.add(DataSections.clipboard);
    }
    if (categories.contains(WipeCategory.emoji)) {
      await store.delete(DataBlobs.emoji);
      sections.add(DataSections.emoji);
    }
    if (categories.contains(WipeCategory.shortcuts)) {
      await shortcuts.clear();
      sections.add(DataSections.shortcuts);
    }
    if (categories.contains(WipeCategory.apps)) {
      await seenApps.clear();
      sections.add(DataSections.seenApps);
    }
    if (categories.contains(WipeCategory.themes)) {
      await _deleteThemes();
    }
    if (sections.isNotEmpty) await notify(sections);
  }

  /// Wipes all encrypted data (and destroys the key), custom themes, and optionally the settings.
  Future<void> wipeEverything({required bool resetSettings}) async {
    await store.wipeAll();
    await seenApps.clear();
    await shortcuts.clear();
    await _deleteThemes();
    if (resetSettings) {
      await settings.update((_) => const BooBoardSettings(), sections: SettingsSection.all);
    }
    await notify([DataSections.all]);
  }

  /// Deletes the theme folder. A custom theme that was selected falls back to the default preset,
  /// so the keyboard never points at a file that is gone.
  Future<void> _deleteThemes() async {
    await themes.deleteAll();
    final appearance = settings.value.appearance;
    if (!ThemePresets.isPresetId(appearance.themeId)) {
      await settings.update(
        (s) => s.copyWith(appearance: s.appearance.copyWith(themeId: ThemePresets.defaultPreset.id)),
        sections: const [SettingsSection.appearance],
      );
    }
  }
}
