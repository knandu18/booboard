// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-B. The privacy center: proof of no internet, what is stored, typing privacy,
// always-incognito apps, personal shortcuts, learned words, app lock, backup and wipe.
// Keep `const PrivacyCenterScreen()` working.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../bridge/messages.g.dart';
import '../../core/data_sections.dart';
import '../../core/seen_apps.dart';
import '../../security/app_auth.dart';
import '../../security/data_wiper.dart';
import '../../settings/booboard_settings.dart';
import '../app_services.dart';
import '../common/settings_widgets.dart';
import '../routes.dart';
import 'backup_screen.dart';
import 'learned_words_screen.dart';
import 'privacy_deps.dart';
import 'privacy_format.dart';
import 'privacy_widgets.dart';
import 'shortcuts_screen.dart';

import 'package:booboard/src/app/l10n.dart';

class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key, this.authenticator});

  /// Defaults to the device's biometric or PIN. Tests pass a fake.
  final AppAuthenticator? authenticator;

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

/// Everything the center shows that is not in settings.
class _CenterData {
  const _CenterData({
    required this.internetPermission,
    required this.debugBuild,
    required this.blobs,
    required this.themeFiles,
    required this.themeBytes,
    required this.shortcutCount,
    required this.apps,
    required this.nowMillis,
    this.packs = const [],
  });

  final bool internetPermission;
  final bool debugBuild;
  final List<SecureBlobInfo> blobs;
  final int themeFiles;
  final int themeBytes;
  final int shortcutCount;
  final List<SeenApp> apps;
  final int nowMillis;

  /// Installed model packs (voice and translation); their files are not in [blobs].
  final List<PackInfoMessage> packs;

  int get packBytes => packs.fold(0, (sum, p) => sum + p.sizeBytes);

  List<String> get learnedBlobNames => [
    for (final b in blobs)
      if (DataBlobs.isLearnedWords(b.name)) b.name,
  ];

  /// Learned data the viewer cannot list (Chinese phrases, Japanese words): shown with a size only.
  List<SecureBlobInfo> get opaqueLearned => [
    for (final b in blobs)
      if (DataBlobs.learnedOpaque.contains(b.name)) b,
  ];

  SecureBlobInfo? blob(String name) {
    for (final b in blobs) {
      if (b.name == name) return b;
    }
    return null;
  }
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  AppServices? _services;
  PrivacyDeps? _deps;
  Future<_CenterData>? _future;
  late final AppAuthenticator _auth = widget.authenticator ?? LocalAuthAuthenticator();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    _services = AppScope.of(context);
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<_CenterData> _load() async {
    final services = _services!;
    final deps = _deps ??= await PrivacyDeps.load(services);
    deps.shortcuts.invalidate();
    services.seenApps.invalidate();
    final internet = await deps.platform.hasInternetPermission();
    final info = await deps.platform.getAppInfo();
    final blobs = await deps.platform.secureList();
    final themeFiles = await deps.themes.list();
    final shortcutCount = (await deps.shortcuts.list()).length;
    final apps = await services.seenApps.list();
    final packs = await _readPacks(deps);
    return _CenterData(
      internetPermission: internet,
      debugBuild: info.isDebugBuild,
      blobs: blobs,
      themeFiles: themeFiles.length,
      themeBytes: themeFiles.fold(0, (sum, f) => sum + f.sizeBytes),
      shortcutCount: shortcutCount,
      apps: apps,
      nowMillis: DateTime.now().millisecondsSinceEpoch,
      packs: packs,
    );
  }

  /// Installed model packs; an unreadable list shows as none rather than failing the whole center.
  Future<List<PackInfoMessage>> _readPacks(PrivacyDeps deps) async {
    try {
      return await deps.platform.listPacks();
    } on Object {
      return const [];
    }
  }

  Future<void> _updatePrivacy(PrivacySettings Function(PrivacySettings current) change) async {
    final services = _services!;
    await services.settings.update(
      (s) => s.copyWith(privacy: change(s.privacy)),
      sections: const [SettingsSection.privacy],
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    if (services == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return ListenableBuilder(
      listenable: services.settings,
      builder: (context, _) => FutureBuilder<_CenterData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(body: Center(child: Text(context.l10n.privacyCenterLoadFailed)));
          }
          if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          return SettingsPage(
            title: context.l10n.settingsPrivacy,
            header: const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(alignment: Alignment.centerLeft, child: PrivacyMascotSlot()),
            ),
            children: _sections(snapshot.requireData, services.settings.value.privacy),
          );
        },
      ),
    );
  }

  List<Widget> _sections(_CenterData d, PrivacySettings privacy) => [
    _proof(d),
    _storedData(d),
    _typing(privacy),
    _incognitoApps(d, privacy),
    _shortcutsGroup(d, privacy),
    _learnedGroup(d),
    _appLockGroup(privacy),
    _backupGroup(),
    _wipeGroup(d),
  ];

  // ---- 1. Proof of no internet ---------------------------------------------------------

  Widget _proof(_CenterData d) {
    if (d.debugBuild) {
      return SettingsGroup(
        children: [
          PrivacyStatusCard(
            icon: Icons.developer_mode,
            text: d.internetPermission ? context.l10n.privacyDevBuildNote : context.l10n.privacyDevBuildShort,
          ),
        ],
      );
    }
    if (d.internetPermission) {
      return SettingsGroup(
        children: [
          PrivacyStatusCard(
            icon: Icons.warning_amber,
            text: context.l10n.privacyDevBuildNetwork,
            tone: PrivacyTone.bad,
          ),
        ],
      );
    }
    return SettingsGroup(
      children: [
        PrivacyStatusCard(
          icon: Icons.verified_user_outlined,
          text: context.l10n.privacyNoInternetPermission,
          tone: PrivacyTone.good,
        ),
      ],
    );
  }

  // ---- 2. What is stored ------------------------------------------------------------

  Widget _storedData(_CenterData d) {
    final nowMillis = d.nowMillis;
    final blobTiles = [
      for (final b in d.blobs)
        SettingsTile(
          icon: Icons.inventory_2_outlined,
          title: friendlyBlobName(b.name, context.l10n),
          subtitle: context.l10n.privacyStorageSize(
            formatBytes(b.sizeBytes),
            timeAgo(b.modifiedMillis, nowMillis: nowMillis, l10n: context.l10n),
          ),
        ),
      if (d.themeFiles > 0)
        SettingsTile(
          icon: Icons.palette_outlined,
          title: context.l10n.privacyCustomThemes,
          subtitle: context.l10n.privacyThemesSize(d.themeFiles, formatBytes(d.themeBytes)),
        ),
      SettingsTile(
        icon: Icons.download_for_offline_outlined,
        title: context.l10n.settingsModelPacks,
        subtitle: d.packs.isEmpty
            ? context.l10n.privacyNoPacks
            : context.l10n.privacyPacksSize(d.packs.length, formatBytes(d.packBytes)),
        onTap: () => unawaited(Navigator.of(context).pushNamed(BooBoardRoutes.packs).then((_) => _reload())),
      ),
      if (d.blobs.isEmpty && d.themeFiles == 0 && d.packs.isEmpty)
        SettingsTile(icon: Icons.inbox_outlined, title: context.l10n.privacyNothingStored),
    ];
    return Column(
      children: [
        SettingsGroup(title: context.l10n.privacyWhatBooBoardStores, children: blobTiles),
        Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 20), child: Text(context.l10n.privacyShowsSizesOnly)),
      ],
    );
  }

  // ---- 3. Typing privacy --------------------------------------------------------------

  Widget _typing(PrivacySettings p) => SettingsGroup(
    title: context.l10n.privacyTypingPrivacy,
    children: [
      SettingsSwitchTile(
        icon: Icons.auto_awesome_outlined,
        title: context.l10n.privacyLearnNewWords,
        subtitle: context.l10n.privacyLearnNewWordsBody,
        value: p.learning,
        onChanged: (v) => unawaited(_updatePrivacy((c) => c.copyWith(learning: v))),
      ),
      SettingsSwitchTile(
        icon: Icons.visibility_off_outlined,
        title: context.l10n.privacyIncognito,
        subtitle: context.l10n.privacyIncognitoBody,
        value: p.incognito,
        onChanged: (v) => unawaited(_updatePrivacy((c) => c.copyWith(incognito: v))),
      ),
      SettingsSwitchTile(
        icon: Icons.screenshot_outlined,
        title: context.l10n.privacyHideScreenshots,
        subtitle: context.l10n.privacyHideScreenshotsBody,
        value: p.hideFromScreenshots,
        onChanged: (v) => unawaited(_updatePrivacy((c) => c.copyWith(hideFromScreenshots: v))),
      ),
    ],
  );

  // ---- 4. Always-incognito apps -----------------------------------------------------

  Widget _incognitoApps(_CenterData d, PrivacySettings p) {
    final rows = <Widget>[
      SettingsTile(
        icon: Icons.info_outline,
        title: context.l10n.privacyAutoOffApps,
        subtitle: context.l10n.privacyAutoOffAppsBody,
      ),
      if (d.apps.isEmpty)
        SettingsTile(
          icon: Icons.apps_outlined,
          title: context.l10n.privacyNoAppsYet,
          subtitle: context.l10n.privacyNoAppsYetBody,
        ),
      for (final app in d.apps)
        _AppIncognitoTile(
          app: app,
          incognito: p.incognitoApps.contains(app.packageName),
          onIncognito: (v) => _setAppIncognito(app.packageName, v),
          onRemove: () => _removeApp(app.packageName),
        ),
    ];
    return SettingsGroup(title: context.l10n.privacyAlwaysIncognitoApps, children: rows);
  }

  Future<void> _setAppIncognito(String packageName, bool on) async {
    final current = _services!.settings.value.privacy.incognitoApps;
    final next = on
        ? [...current.where((p) => p != packageName), packageName]
        : current.where((p) => p != packageName).toList();
    await _updatePrivacy((c) => c.copyWith(incognitoApps: next));
  }

  Future<void> _removeApp(String packageName) async {
    final services = _services!;
    await services.seenApps.remove(packageName);
    await services.notifyDataChanged(const [DataSections.seenApps]);
    if (_services!.settings.value.privacy.incognitoApps.contains(packageName)) {
      await _setAppIncognito(packageName, false);
    }
    _reload();
  }

  // ---- 5. Personal shortcuts ----------------------------------------------------------

  Widget _shortcutsGroup(_CenterData d, PrivacySettings p) => SettingsGroup(
    title: context.l10n.privacyPersonalShortcuts,
    children: [
      SettingsSwitchTile(
        icon: Icons.keyboard_alt_outlined,
        title: context.l10n.privacyOfferShortcuts,
        subtitle: context.l10n.privacyOfferShortcutsBody,
        value: p.personalShortcuts,
        onChanged: (v) => unawaited(_updatePrivacy((c) => c.copyWith(personalShortcuts: v))),
      ),
      SettingsTile(
        icon: Icons.edit_note,
        title: context.l10n.privacyEditShortcuts,
        subtitle: d.shortcutCount == 0
            ? context.l10n.privacyNoShortcutsYet
            : context.l10n.countShortcuts(d.shortcutCount),
        onTap: () => unawaited(_open(const ShortcutsScreen()).then((_) => _reload())),
      ),
    ],
  );

  // ---- 6. Learned words and clipboard ---------------------------------------------------

  Widget _learnedGroup(_CenterData d) {
    final nowMillis = d.nowMillis;
    final clipboard = d.blob(DataBlobs.clipboard);
    return SettingsGroup(
      title: context.l10n.privacyLearnedAndClipboard,
      children: [
        if (d.learnedBlobNames.isEmpty && d.opaqueLearned.isEmpty)
          SettingsTile(
            icon: Icons.text_fields,
            title: context.l10n.privacyNoWordsLearnedYet,
            subtitle: context.l10n.privacyWordsLearnedBody,
          ),
        for (final name in d.learnedBlobNames)
          SettingsTile(
            icon: Icons.menu_book_outlined,
            title: friendlyBlobName(name, context.l10n),
            subtitle: context.l10n.privacyReviewWords(
              timeAgo(d.blob(name)!.modifiedMillis, nowMillis: nowMillis, l10n: context.l10n),
            ),
            onTap: () => unawaited(
              _open(LearnedWordsScreen(languageId: name.substring(DataBlobs.learnedPrefix.length)))
                  .then((_) => _reload()),
            ),
          ),
        for (final b in d.opaqueLearned)
          SettingsTile(
            icon: Icons.translate,
            title: friendlyBlobName(b.name, context.l10n),
            subtitle:
                '${formatBytes(b.sizeBytes)} · ${timeAgo(b.modifiedMillis, nowMillis: nowMillis, l10n: context.l10n)}',
          ),
        SettingsTile(
          icon: Icons.content_paste_outlined,
          title: context.l10n.panelsClipboard,
          subtitle: clipboard == null
              ? context.l10n.privacyClipboardHistoryEmpty
              : context.l10n.privacyClipboardInHistory(formatBytes(clipboard.sizeBytes)),
          onTap: () => Navigator.of(context).pushNamed(BooBoardRoutes.panels),
        ),
      ],
    );
  }

  // ---- 7. App lock -------------------------------------------------------------------

  Widget _appLockGroup(PrivacySettings p) => SettingsGroup(
    title: context.l10n.privacyAppLock,
    children: [
      SettingsSwitchTile(
        icon: Icons.fingerprint,
        title: context.l10n.privacyLockBooBoard,
        subtitle: context.l10n.privacyLockBooBoardBody,
        value: p.appLock,
        onChanged: (v) => unawaited(_setAppLock(v)),
      ),
      SettingsTile(
        icon: Icons.timer_outlined,
        title: context.l10n.privacyLockAfter,
        subtitle: AppLockPolicy.timeoutLabel(p.appLockTimeoutSeconds),
        enabled: p.appLock,
        onTap: p.appLock ? () => unawaited(_pickTimeout(p)) : null,
      ),
    ],
  );

  Future<void> _setAppLock(bool on) async {
    final l10n = context.l10n;
    if (!on) {
      await _updatePrivacy((c) => c.copyWith(appLock: false));
      return;
    }
    if (!await _auth.isDeviceSecure()) {
      if (!mounted) return;
      await _info(l10n.privacySetScreenLockFirst, context.l10n.privacySetScreenLockBody);
      return;
    }
    // Turning it on needs one successful check first, so the user knows it works.
    final outcome = await _auth.authenticate(l10n.privacyTurnOnAppLockReason);
    if (!mounted) return;
    if (outcome == AuthOutcome.success) {
      await _updatePrivacy((c) => c.copyWith(appLock: true));
    } else if (outcome == AuthOutcome.unavailable) {
      await _info(l10n.privacyNotAvailable, l10n.privacyNotAvailableBody);
    }
  }

  Future<void> _pickTimeout(PrivacySettings p) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.privacyLockAfter),
        children: [
          RadioGroup<int>(
            groupValue: p.appLockTimeoutSeconds,
            onChanged: (v) => Navigator.of(context).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final seconds in AppLockPolicy.timeoutChoices)
                  RadioListTile<int>(value: seconds, title: Text(AppLockPolicy.timeoutLabel(seconds))),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await _updatePrivacy((c) => c.copyWith(appLockTimeoutSeconds: picked));
  }

  // ---- 8. Backup ---------------------------------------------------------------------

  Widget _backupGroup() => SettingsGroup(
    title: context.l10n.privacyBackupTitle,
    children: [
      SettingsTile(
        icon: Icons.archive_outlined,
        title: context.l10n.privacyBackupRestore,
        subtitle: context.l10n.privacyBackupRestoreBody,
        onTap: () => unawaited(_open(const BackupScreen()).then((_) => _reload())),
      ),
    ],
  );

  // ---- 9. Wipe -----------------------------------------------------------------------

  Widget _wipeGroup(_CenterData d) => SettingsGroup(
    title: context.l10n.privacyDeleteData,
    children: [
      for (final c in WipeCategory.values)
        SettingsTile(
          icon: Icons.delete_outline,
          title: c.title,
          subtitle: c.detail,
          onTap: () => unawaited(_confirmWipe({c}, everything: false)),
        ),
      SettingsTile(
        icon: Icons.delete_forever_outlined,
        title: context.l10n.privacyEraseEverything,
        subtitle: context.l10n.privacyEraseEverythingBody,
        onTap: () => unawaited(_confirmWipe(WipeCategory.values.toSet(), everything: true)),
      ),
    ],
  );

  Future<void> _confirmWipe(Set<WipeCategory> categories, {required bool everything}) async {
    final deps = _deps;
    if (deps == null) return;
    var resetSettings = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(
            everything
                ? context.l10n.privacyEraseTitle
                : context.l10n.privacyDeleteTitle(categories.first.title.toLowerCase()),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.privacyWillDelete),
                const SizedBox(height: 8),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(context.l10n.privacyCategoryLine(c.title, c.detail)),
                  ),
                if (everything)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: resetSettings,
                    title: Text(context.l10n.privacyResetSettings),
                    onChanged: (v) => setDialog(() => resetSettings = v ?? false),
                  ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.privacyCannotBeUndone,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.cancel)),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.delete),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      if (everything) {
        await deps.wiper.wipeEverything(resetSettings: resetSettings);
      } else {
        await deps.wiper.wipe(categories);
      }
      if (mounted) showPrivacyMessage(context, context.l10n.privacyDeleted);
    } on Object {
      if (mounted) showPrivacyMessage(context, context.l10n.privacyDeleteFailed);
    }
    _reload();
  }

  // ---- helpers -----------------------------------------------------------------------

  Future<void> _info(String title, String body) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.privacyOk))],
    ),
  );

  Future<T?> _open<T>(Widget screen) => Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => screen));
}

/// One always-incognito app: a switch to turn it on, and a button to forget the app.
class _AppIncognitoTile extends StatelessWidget {
  const _AppIncognitoTile({
    required this.app,
    required this.incognito,
    required this.onIncognito,
    required this.onRemove,
  });

  final SeenApp app;
  final bool incognito;
  final ValueChanged<bool> onIncognito;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final label = app.label ?? app.packageName;
    return ListTile(
      leading: const Icon(Icons.apps),
      title: Text(label),
      subtitle: app.label == null ? null : Text(app.packageName),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: incognito, onChanged: onIncognito),
          IconButton(
            tooltip: context.l10n.privacyRemoveAppTooltip(label),
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
