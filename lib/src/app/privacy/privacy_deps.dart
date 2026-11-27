// SPDX-License-Identifier: GPL-3.0-or-later
//
// The stores and services the privacy screens share, built once per screen from AppServices.
import '../../bridge/messages.g.dart';
import '../../core/seen_apps.dart';
import '../../core/secure_blob_store.dart';
import '../../security/backup/backup_collect.dart';
import '../../security/backup/backup_restore.dart';
import '../../security/custom_theme_files.dart';
import '../../security/data_wiper.dart';
import '../../security/shortcuts_store.dart';
import '../../settings/settings_store.dart';
import '../app_services.dart';

class PrivacyDeps {
  PrivacyDeps._({required this.services, required this.shortcuts, required this.themes});

  /// Resolves the data directory (custom themes live under it) and builds the stores.
  static Future<PrivacyDeps> load(AppServices services) async {
    final dir = await services.platform.getDataDirectory();
    return PrivacyDeps._(
      services: services,
      shortcuts: ShortcutsStore(services.secureStore),
      themes: CustomThemeFiles.forDataDirectory(dir),
    );
  }

  final AppServices services;
  final ShortcutsStore shortcuts;
  final CustomThemeFiles themes;

  SettingsStore get settings => services.settings;
  PlatformHostApi get platform => services.platform;
  SecureBlobStore get store => services.secureStore;
  SeenAppsStore get seenApps => services.seenApps;

  DataWiper get wiper => DataWiper(
    store: store,
    platform: platform,
    seenApps: seenApps,
    shortcuts: shortcuts,
    settings: settings,
    themes: themes,
    notify: services.notifyDataChanged,
  );

  BackupCollector get collector =>
      BackupCollector(store: store, platform: platform, shortcuts: shortcuts, settings: settings, themes: themes);

  BackupRestorer get restorer => BackupRestorer(
    store: store,
    platform: platform,
    shortcuts: shortcuts,
    settings: settings,
    themes: themes,
    notify: services.notifyDataChanged,
  );
}
